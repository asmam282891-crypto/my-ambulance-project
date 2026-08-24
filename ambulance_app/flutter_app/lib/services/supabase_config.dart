// Supabase connection settings.
// Where to get these values: Supabase dashboard -> Settings -> API
class SupabaseConfig {
  static const String url = 'https://vdqsdoyqpxuiiznaruuj.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkcXNkb3lxcHh1aWl6bmFydXVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY5MDU0NTksImV4cCI6MjEwMjQ4MTQ1OX0.BMGUe1XVsee_-gviktC25wbqBDUkzuJu20fv8QBRypg';

  // Suffix used internally to turn a "username" into an email address,
  // because Supabase Auth requires an email format.
  static const String emailSuffix = '@ambulance.local';
}
