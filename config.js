// Configuración del servidor compartido (Supabase).
// Deja los valores vacíos para usar la app en modo local (datos solo en este navegador).
// La clave "anon" es pública por diseño: la seguridad la dan las políticas RLS de supabase/schema.sql.
window.PD_CONFIG = {
  supabaseUrl: '',      // ej. 'https://abcdefghijkl.supabase.co'
  supabaseAnonKey: ''   // Project Settings → API → anon public
};
