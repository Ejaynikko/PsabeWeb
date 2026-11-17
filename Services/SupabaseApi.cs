using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.Extensions.Options;

namespace PsabeWeb.Services;

public class SupabaseOptions
{
    public string Url { get; set; } = "";
    public string AnonKey { get; set; } = "";
    public string ServiceRoleKey { get; set; } = ""; // server-side secret: user-secrets / env var only, never appsettings.json
}

public class ApiException(string message) : Exception(message);

public record SignInResult(string AccessToken, Guid UserId, string Email, int ExpiresIn);

/// <summary>
/// Thin wrapper over Supabase's REST endpoints (PostgREST + GoTrue). Every data call runs with the
/// signed-in user's JWT, so Row Level Security in Postgres is the real access control.
/// Only the publishable key lives in this app - never a service-role key.
/// </summary>
public class SupabaseApi(IHttpClientFactory factory, IOptions<SupabaseOptions> opt, AuthenticationStateProvider auth)
{
    static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true,
    };

    readonly HttpClient http = factory.CreateClient();
    string Base => opt.Value.Url.TrimEnd('/');

    async Task<HttpResponseMessage> Send(HttpMethod method, string path, object? body = null,
        string? token = null, bool minimal = false)
    {
        using var req = new HttpRequestMessage(method, Base + path);
        req.Headers.Add("apikey", opt.Value.AnonKey);
        token ??= (await auth.GetAuthenticationStateAsync()).User.FindFirst("access_token")?.Value;
        if (!string.IsNullOrEmpty(token)) req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (minimal) req.Headers.Add("Prefer", "return=minimal");
        if (body != null) req.Content = JsonContent.Create(body, body.GetType(), options: Json);

        var res = await http.SendAsync(req);
        if (!res.IsSuccessStatusCode)
            throw new ApiException(ReadMessage(await res.Content.ReadAsStringAsync(), res.StatusCode.ToString()));
        return res;
    }

    internal static string ReadMessage(string body, string fallback)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            foreach (var key in new[] { "msg", "message", "error_description", "error" })
                if (doc.RootElement.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.String)
                    return v.GetString()!;
        }
        catch (JsonException) { }
        return fallback;
    }

    // ---- data (PostgREST) ----
    public async Task<List<T>> List<T>(string table, string query = "", string? token = null)
    {
        var res = await Send(HttpMethod.Get, $"/rest/v1/{table}?{query}", token: token);
        return await res.Content.ReadFromJsonAsync<List<T>>(Json) ?? [];
    }

    public Task Insert(string table, object row) =>
        Send(HttpMethod.Post, $"/rest/v1/{table}", row, minimal: true);

    public Task Update(string table, Guid id, object row) =>
        Send(HttpMethod.Patch, $"/rest/v1/{table}?id=eq.{id}", row, minimal: true);

    public Task Delete(string table, Guid id) =>
        Send(HttpMethod.Delete, $"/rest/v1/{table}?id=eq.{id}", minimal: true);

    public async Task<Guid?> CurrentUserId()
    {
        var id = (await auth.GetAuthenticationStateAsync()).User
            .FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(id, out var g) ? g : null;
    }

    // ---- storage ----
    const string Bucket = "psabe-media";

    /// <summary>Uploads an image to the media bucket (RLS decides who may write where) and returns its public URL.</summary>
    public async Task<string> Upload(string path, Stream data, string contentType)
    {
        var token = (await auth.GetAuthenticationStateAsync()).User.FindFirst("access_token")?.Value;
        using var req = new HttpRequestMessage(HttpMethod.Post, $"{Base}/storage/v1/object/{Bucket}/{path}");
        req.Headers.Add("apikey", opt.Value.AnonKey);
        if (!string.IsNullOrEmpty(token)) req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        req.Content = new StreamContent(data);
        req.Content.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        var res = await http.SendAsync(req);
        if (!res.IsSuccessStatusCode)
            throw new ApiException(ReadMessage(await res.Content.ReadAsStringAsync(), res.StatusCode.ToString()));
        return $"{Base}/storage/v1/object/public/{Bucket}/{path}";
    }

    // ---- auth (GoTrue) ----
    // Supabase has captcha protection on: sign-in, sign-up and recovery must carry the hCaptcha token.
    public async Task<SignInResult> SignIn(string email, string password, string captchaToken)
    {
        var res = await Send(HttpMethod.Post, "/auth/v1/token?grant_type=password",
            new { email, password, gotrue_meta_security = new { captcha_token = captchaToken } }, token: "");
        using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
        var r = doc.RootElement;
        var user = r.GetProperty("user");
        return new SignInResult(
            r.GetProperty("access_token").GetString()!,
            Guid.Parse(user.GetProperty("id").GetString()!),
            user.GetProperty("email").GetString() ?? email,
            r.GetProperty("expires_in").GetInt32());
    }

    public Task SignUp(string email, string password, string fullName, string captchaToken) =>
        Send(HttpMethod.Post, "/auth/v1/signup",
            new { email, password, data = new { full_name = fullName }, gotrue_meta_security = new { captcha_token = captchaToken } }, token: "");

    // redirectTo must be in Supabase > Authentication > URL Configuration > Redirect URLs.
    public Task Recover(string email, string redirectTo, string captchaToken) =>
        Send(HttpMethod.Post, $"/auth/v1/recover?redirect_to={Uri.EscapeDataString(redirectTo)}",
            new { email, gotrue_meta_security = new { captcha_token = captchaToken } }, token: "");

    // accessToken is the short-lived recovery token from the emailed link.
    public Task UpdatePassword(string accessToken, string newPassword) =>
        Send(HttpMethod.Put, "/auth/v1/user", new { password = newPassword }, token: accessToken);
}
