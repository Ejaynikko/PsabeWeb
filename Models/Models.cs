using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace PsabeWeb.Models;

// Property names map to snake_case columns (see SupabaseApi JSON options).
// Id is left out when null so inserts let the database generate it; every other null is sent,
// so clearing a field in an admin form really clears it.

public class Profile
{
    public Guid? Id { get; set; }
    public string FullName { get; set; } = "";
    public string? Email { get; set; }
    public string? Region { get; set; }
    public string? Chapter { get; set; }
    public string MembershipType { get; set; } = "member";
    public string Role { get; set; } = "member";
    public string Status { get; set; } = "pending";
    public string? PrcLicenseNo { get; set; }
    public string? Phone { get; set; }
    public string? AvatarUrl { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
}

public class EventItem
{
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public Guid? Id { get; set; }
    [Required] public string Title { get; set; } = "";
    public string? Summary { get; set; }
    public string? Location { get; set; }
    public DateTimeOffset StartsAt { get; set; } = DateTimeOffset.Now;
    public DateTimeOffset? EndsAt { get; set; }
    public string? RegistrationUrl { get; set; }
    public string? ProgramUrl { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsPublished { get; set; } = true;
}

public class Registration
{
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public Guid? Id { get; set; }
    public Guid EventId { get; set; }
    public Guid UserId { get; set; }
    public string? CertificateUrl { get; set; }
}

public class RegionCount
{
    public Guid EventId { get; set; }
    public string Region { get; set; } = "";
    public int Attendees { get; set; }
}

public class NewsItem
{
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public Guid? Id { get; set; }
    [Required] public string Title { get; set; } = "";
    public string? Body { get; set; }
    public string? ImageUrl { get; set; }
    public string Category { get; set; } = "News";
    public bool IsPublished { get; set; } = true;
    public DateTimeOffset? PublishedAt { get; set; } = DateTimeOffset.Now;
}

public class Officer
{
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public Guid? Id { get; set; }
    [Required] public string FullName { get; set; } = "";
    [Required] public string Position { get; set; } = "";
    public string? Region { get; set; }
    public string? Term { get; set; }
    public string? PhotoUrl { get; set; }
    public int SortOrder { get; set; }
}

public class GalleryItem
{
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public Guid? Id { get; set; }
    [Required] public string Title { get; set; } = "";
    [Required] public string ImageUrl { get; set; } = "";
    public int SortOrder { get; set; }
    public bool IsPublished { get; set; } = true;
}

public class ResourceItem
{
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public Guid? Id { get; set; }
    [Required] public string Title { get; set; } = "";
    public string? Description { get; set; }
    public string Category { get; set; } = "downloads"; // publications | references | downloads
    [Required] public string FileUrl { get; set; } = "";
    public int SortOrder { get; set; }
    public bool IsPublished { get; set; } = true;
}

public class Announcement
{
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public Guid? Id { get; set; }
    [Required] public string Text { get; set; } = "";
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public static class Regions
{
    public static readonly string[] All =
    [
        "BARMM", "CAR", "NCR", "Region I", "Region II", "Region III", "Region IVA", "Region IVB",
        "Region V", "Region VI", "Region VII", "Region VIII", "Region IX", "Region X",
        "Region XI", "Region XII", "Region XIII",
    ];
}
