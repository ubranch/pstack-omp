#!/usr/bin/env node
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { createInterface } from 'node:readline';

const [pluginPath, model] = process.argv.slice(2);
assert(pluginPath && model, 'Usage: node omp-port/smoke-plugin.mjs <plugin-path> <catalog-model>');
const plugin = resolve(pluginPath);
const home = await mkdtemp(resolve(tmpdir(), 'pstack-smoke-'));
const env = { ...process.env, PI_CONFIG_DIR: '.', PI_CODING_AGENT_DIR: home, HOME: home, USERPROFILE: home };
for (const key of Object.keys(env)) {
  if (/^(?:OMP_PROFILE|(?:OMP|PI)_CONFIG_FILES)$|API_KEY|TOKEN|SECRET|PASSWORD/i.test(key)) delete env[key];
}
const child = spawn(process.platform === 'win32' ? 'omp.exe' : 'omp', [
  '--mode', 'rpc', '--no-session', '--no-title', '--no-extensions',
  '--no-rules', '--no-lsp', '--no-tools', '--plugin-dir', plugin,
  '-e', resolve(plugin, 'extensions/potetomode/index.js'), '--model', model,
], { cwd: home, env, stdio: ['pipe', 'pipe', 'pipe'] });
const lines = createInterface({ input: child.stdout })[Symbol.asyncIterator]();
let spawnError;
child.on('error', error => { spawnError = error; });
child.stderr.resume();
const exited = new Promise(resolveExit => child.once('close', code => resolveExit(code)));
const timer = setTimeout(() => child.kill(), 60000);
let nextId = 0;

async function frame() {
  const { value, done } = await lines.next();
  assert(!done, spawnError?.message ?? 'OMP ended before completing the RPC check');
  const valueJson = JSON.parse(value);
  assert.notEqual(valueJson.type, 'agent_start', 'Smoke commands must not start inference');
  return valueJson;
}

async function request(type, fields = {}) {
  const id = String(++nextId);
  child.stdin.write(`${JSON.stringify({ id, type, ...fields })}\n`);
  while (true) {
    const message = await frame();
    if (message.id !== id) continue;
    if (message.type === 'response') {
      assert.equal(message.success, true, `RPC ${type} failed`);
      if (type !== 'prompt' || message.data?.agentInvoked === false) return message.data;
    }
    if (message.type === 'prompt_result') {
      assert.equal(message.agentInvoked, false, 'Pin commands must complete locally');
      assert.equal(message.status, 'completed');
      return message;
    }
  }
}

try {
  while ((await frame()).type !== 'ready') { }
  const { commands } = await request('get_available_commands');
  for (const name of ['statechart', 'sharpen', 'in-your-own-words', 'ketchup-video', 'create-formal-verification-skill', 'maintain-formal-verification-skill']) {
    assert(commands.some(command => command.name === `skill:${name}` && command.source === 'skill'), `Missing skill ${name}`);
  }
  assert(commands.some(command => command.name === 'poteto-mode' && command.source === 'extension'), 'Pin extension not loaded');
  for (const [argument, pinned] of [['on', true], ['off', false]]) {
    await request('prompt', { message: `/poteto-mode ${argument}` });
    const { entries } = await request('get_entries');
    const pin = entries.filter(entry => entry.type === 'custom' && entry.customType === 'poteto-mode').at(-1);
    assert.equal(pin?.data?.pinned, pinned, `Pin state after ${argument}`);
  }
  const { entries } = await request('get_entries');
  assert(!entries.some(entry => entry.type === 'message' && entry.message?.role === 'assistant'), 'Smoke must not create model replies');
  child.stdin.end();
  assert.equal(await exited, 0, 'OMP must exit cleanly');
  console.log('PASS: six new skills discovered; pin on/off recorded; no inference; clean RPC shutdown');
} finally {
  clearTimeout(timer);
  if (child.exitCode === null) child.kill();
  await exited;
  await rm(home, { recursive: true, force: true });
}
