import { cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = dirname(fileURLToPath(import.meta.url));
const outputDir = resolve(process.env.MAKEFUN_OUTPUT_DIR || '/output');
const requiredFiles = ['game.rbxl', 'PLAY.json'];

mkdirSync(outputDir, { recursive: true });
for (const name of requiredFiles) {
  const source = join(here, name);
  if (!existsSync(source)) throw new Error(`Required hand-in file is missing: ${source}`);
  cpSync(source, join(outputDir, name));
}
for (const name of ['src', 'screenshots']) {
  const source = join(here, name);
  if (!existsSync(source)) throw new Error(`Required hand-in directory is missing: ${source}`);
  cpSync(source, join(outputDir, name), { recursive: true });
}

const dossier = buildDossier(outputDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(outputDir, 'dossier.json'), dossier);
