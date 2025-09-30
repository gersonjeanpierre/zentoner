interface ImportMetaEnv {
  readonly SUPABASE_URL: string;
  readonly SUPABASE_KEY: string;
  // Agrega aquí otras variables si las necesitas
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
