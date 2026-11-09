// Public configuration only; never put secret/service_role keys here.
// Replace the publishable key after security review and before private beta testing.
window.LIFEONE_SUPABASE_URL = "https://ouzfnltcnskjaucruadn.supabase.co";
window.LIFEONE_SUPABASE_PUBLISHABLE_KEY = "sb_publishable_SIG542iOPcnBlfykMIMF1g_hd1z6OND";

// Safety gate: keep false until staging migrations, bidirectional block RLS tests,
// and two independent invited-account tests have passed. No public launch.
window.LIFEONE_FOLLOWS_ENABLED = false;

// Keep these off until the linked staging SQL, RLS, moderator process,
// and independent cross-account security tests have been verified.
window.LIFEONE_SAFETY_ENABLED = false;
window.LIFEONE_SHARED_POSTS_ENABLED = false;
