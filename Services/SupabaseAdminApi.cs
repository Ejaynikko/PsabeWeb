using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using PsabeWeb.Models;

namespace PsabeWeb.Services;

/// <summary>
/// Creates/deletes login accounts with the service-role key. Blazor Server runs this on the server only,
/// so the key never reaches the browser. Every call re-checks in the database that the caller is an admin.
/// </summary>
public class SupabaseAdminApi(IHttpClientFactory factory, IOptions<SupabaseOptions> opt, SupabaseApi api)
{
    readonly HttpClient http = factory.CreateClient();

    async Task EnsureAdmin()
    {
        if (string.IsNullOrWhiteSpace(opt.Value.ServiceRoleKey))
            throw new ApiException("ServiceRoleKey is not set on the server (see README).");
        var uid = await api.CurrentUserId();
        var me = uid is null ? null : (await api.List<Profile>("profiles", $"id=eq.{uid}")).FirstOrDefault();
        if (me?.Role != "admin") throw new ApiException("Admins only.");
    }

    async Task<HttpResponseMessage> Send(HttpMethod method, string path, object? body = null)
    {
        var key = opt.Value.ServiceRoleKey;
        using var req = new HttpRequestMessage(method, opt.Value.Url.TrimEnd('/') + path);
        req.Headers.Add("apikey", key);
        if (key.StartsWith("eyJ")) req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", key); // legacy JWT keys only
        if (body != null) req.Content = JsonContent.Create(body);
        var res = await http.SendAsync(req);
        if (!res.IsSuccessStatusCode)
            throw new ApiException(SupabaseApi.ReadMessage(await res.Content.ReadAsStringAsync(), res.StatusCode.ToString()));
        return res;
    }

    public async Task<Guid> CreateUser(string email, string password, string fullName)
    {
        await EnsureAdmin();
        var res = await Send(HttpMethod.Post, "/auth/v1/admin/users",
            new { email, password, email_confirm = true, user_metadata = new { full_name = fullName } });
        using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
        return Guid.Parse(doc.RootElement.GetProperty("id").GetString()!);
    }

    // Cascades to the profile and that member's event registrations.
    public async Task DeleteUser(Guid id)
    {
        await EnsureAdmin();
        if (id == await api.CurrentUserId()) throw new ApiException("You can't delete your own account.");
        await Send(HttpMethod.Delete, $"/auth/v1/admin/users/{id}");
    }
}
