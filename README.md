# PSABE website (Blazor Server, .NET 9 + Supabase)

Green/gold PSABE design. Public site for guests, member accounts, and an admin area with CRUD.

## Run it

1. **Database** - open the *Philmech PSABE* Supabase project, SQL editor, run `supabase/000_psabe_full_schema.sql`
   (creates every table, the admin/member policies and the region-count view from scratch; safe to re-run).
2. **Admin account** - create `Admin.PSABE@gmail.com` (Supabase > Authentication > Users > Add user, auto-confirm), then run the script again; its last line makes that email an admin.
3. **New content tables** - run `supabase/002_content_tables.sql` (Gallery, Resources, Announcements, news category, event image). Optional: `supabase/003_sample_content.sql` adds sample content from the original design (only into empty tables).
3b. **Contact details** - edit the `Site` section in `appsettings.json` (address, email, phone, Facebook, YouTube).
4. `dotnet run` and open the https URL it prints.

5. **Admin create/delete members** needs the project's service-role key, kept on the server only (Supabase dashboard > Project Settings > API Keys):
   `dotnet user-secrets init` then `dotnet user-secrets set "Supabase:ServiceRoleKey" "<key>"`
   (in production use the env var `Supabase__ServiceRoleKey`). Never put it in `appsettings.json` or commit it.

## Forgot password + captcha

- Supabase captcha (hCaptcha) is on, so Login, Register and Forgot password show the widget. The sitekey is in `appsettings.json` (`HCaptcha:SiteKey`); the *secret* lives only in the Supabase dashboard.
- In hCaptcha's dashboard, allow `localhost` for that sitekey if the widget shows a domain error.
- Forgot password emails a reset link. In Supabase > Authentication > URL Configuration set **Site URL** to `https://localhost:7113` and add `https://localhost:7113/reset-password` to **Redirect URLs** (add your real domain's `/reset-password` when you deploy).
- Supabase's built-in email sender is limited to a few emails per hour; set up custom SMTP before launch.

`appsettings.json` already holds the project URL and the *publishable* key (safe for client apps).
Never put the `service_role` key in this app.

## Roles

| Who | Can do |
|---|---|
| Guest | View home, about, officers, events (with region charts), news |
| Member | Log in, edit own profile, register for events once approved (`status = active`), download own certificate |
| Admin | `/admin/members`, `/admin/events`, `/admin/news`, `/admin/officers` - full create / edit / delete (members too: create with a temporary password, deactivate, or delete permanently) |

Access is enforced by Postgres Row Level Security using the user's own JWT, not just by hidden buttons.

## Known limits

- Session ends when the Supabase token expires (~1 hour), then the user logs in again.
- In production, persist ASP.NET Data Protection keys, or logins reset on every restart.
- Deleting a member or an event cascades in the database (profile, registrations). There is no undo.
- Sample images are hot-linked from Unsplash/placehold.co: replace them with real PSABE photos (admin > Gallery/News/Events) before launch.
- Resources and Gallery take file/image URLs; there is no file upload yet.
- Not built yet: certificate upload/auto-generation, regional-officer role.
