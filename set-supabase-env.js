// set-supabase-env.js
const fs = require('fs');
const path = require('path');

// Las variables de entorno son inyectadas por GitHub Actions (los 'secrets')
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_KEY;

console.log('--- Configurando variables de Supabase para Electron Build ---');

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error(
    'FATAL: SUPABASE_URL o SUPABASE_KEY no están definidas en el entorno de build de GitHub Actions.',
  );
  // Aseguramos que el build falle si faltan los secretos
  process.exit(1);
}

// El contenido que se escribirá en el archivo
const envContent = `
// Este archivo es generado automáticamente para el build de Electron en GitHub Actions
export const environment = {
  production: true,
  SUPABASE_URL: "${SUPABASE_URL}",
  SUPABASE_KEY: "${SUPABASE_KEY}"
};
`;

// Define la ruta donde debe crearse/escribirse el archivo
const targetDir = path.join(__dirname, 'src', 'environments');
const targetPath = path.join(targetDir, 'environment.ts');

try {
  // 1. Crea el directorio 'src/environments' si no existe
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
    console.log(`Directorio creado: ${targetDir}`);
  }

  // 2. Escribe el archivo environment.ts
  fs.writeFileSync(targetPath, envContent.trim());
  console.log(`✅ Archivo de entorno generado con éxito en: ${targetPath}`);
} catch (error) {
  console.error('❌ Error al generar el archivo de entorno:', error);
  process.exit(1);
}
