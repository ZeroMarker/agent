#!/usr/bin/env node
// Add models advertised by the local Codex account through CloudCLI's custom-model service.
import { chmod, readFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const home = os.homedir();
process.umask(0o077);
const app = process.env.CLOUDCLI_PACKAGE_DIR || path.join(home, '.local/share/cloudcli/node_modules/@cloudcli-ai/cloudcli');
process.env.DATABASE_PATH ||= path.join(home, '.local/state/cloudcli/auth.db');
const cachePath = path.join(process.env.CODEX_HOME || path.join(home, '.codex'), 'models_cache.json');
const cache = JSON.parse(await readFile(cachePath, 'utf8'));
const age = Date.now() - Date.parse(cache.fetched_at);
if (!Number.isFinite(age) || age < -300_000 || age > 86_400_000) {
  throw new Error('Codex model cache is missing a recent timestamp. Open Codex and refresh /model first.');
}
const visible = cache.models?.filter((model) => model.visibility === 'list');
if (!visible?.length || visible.some((model) => typeof model.slug !== 'string' || !model.slug.trim())) {
  throw new Error('Codex cache contains no valid visible models. Nothing was changed.');
}
const load = (file) => import(pathToFileURL(path.join(app, 'dist-server/server', file)).href);
const { closeConnection, getConnection } = await load('modules/database/index.js');
try {
  const { providerModelsService } = await load('modules/providers/services/provider-models.service.js');
  const catalog = await providerModelsService.getProviderModels('codex');
  const existing = new Set(catalog.OPTIONS.map((model) => model.value));
  const additions = visible.filter((model) => !existing.has(model.slug));
  const inputs = additions.map((model) => {
    const levels = model.supported_reasoning_levels?.map((level) => level.effort) || [];
    if (levels.some((level) => !catalog.EFFORT_LEVELS.includes(level))) {
      throw new Error(`CloudCLI cannot represent the reasoning levels for ${model.slug}. Nothing was changed.`);
    }
    return {
      id: model.slug,
      model: model.display_name || model.slug,
      ...(levels.length ? { effort: {
        values: levels,
        ...(levels.includes(model.default_reasoning_level) ? { default: model.default_reasoning_level } : {}),
      } } : {}),
    };
  });
  if (inputs.length) {
    const backup = `${process.env.DATABASE_PATH}.bak-models-${Date.now()}`;
    await getConnection().backup(backup);
    await chmod(backup, 0o600);
    console.log(`Database backup: ${backup}`);
    for (const input of inputs) {
      await providerModelsService.createCustomModel('codex', input);
      console.log(`Added ${input.id}`);
    }
  }
  console.log(`Visible Codex models checked: ${visible.length}; added: ${inputs.length}. Defaults and existing entries preserved.`);
} finally {
  closeConnection();
}
