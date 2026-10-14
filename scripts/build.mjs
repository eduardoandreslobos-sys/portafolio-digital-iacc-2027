// Genera index.html (versión independiente para GitHub Pages) a partir de src/app.html,
// que es la misma fuente que se publica como artifact en claude.ai.
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const app = readFileSync(join(root, 'src/app.html'), 'utf8');

const html = `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="description" content="Priorización consensuada, roadmap, tablero y métricas del portafolio digital IACC 2027.">
<!-- config.js define window.PD_CONFIG con la URL y la clave pública de Supabase. Sin ella, la app funciona en modo local. -->
<script src="config.js"></script>
</head>
<body>
<!-- Archivo generado por scripts/build.mjs desde src/app.html. No lo edites a mano. -->
${app}
</body>
</html>
`;
writeFileSync(join(root, 'index.html'), html);
console.log('index.html generado (' + html.length + ' bytes)');
