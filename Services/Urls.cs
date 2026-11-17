namespace PsabeWeb.Services;

public static class Urls
{
    /// <summary>Admin-entered links go into href attributes; only allow http(s) and site-relative paths (blocks javascript: links).</summary>
    public static string Safe(string? url) =>
        url is not null && (url.StartsWith("https://") || url.StartsWith("http://") || (url.StartsWith('/') && !url.StartsWith("//")))
            ? url : "#";
}
