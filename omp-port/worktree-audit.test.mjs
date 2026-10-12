import assert from "node:assert/strict";
import { execFileSync, spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, readlinkSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";

const bash = process.argv[2] ?? "bash";
const script = resolve(dirname(fileURLToPath(import.meta.url)), "../plugins/pstack/skills/poteto-mode/scripts/worktree-audit.sh");
const root = mkdtempSync(join(tmpdir(), "pstack-audit-"));
const repo = join(root, "repo");
const active = join(root, "active worktree");
const legacy = join(root, "legacy");
const parentOwned = join(root, "parent-owned");
const idle = join(root, "idle");
const sessions = join(root, "authorized-sessions");
const forward = (path) => path.replaceAll("\\", "/");
const env = { ...process.env, GH_PROMPT_DISABLED: "1" };
for (const key of Object.keys(env)) {
	if (/^(?:GIT_|GH_(?:REPO|CONFIG_DIR)$|(?:OMP|PI)_(?:PROFILE|CONFIG_DIR|CONFIG_FILES|CODING_AGENT_DIR|CODING_AGENT_SESSION_DIR|NATIVES_DIR)$|HOME$|USERPROFILE$|LOCALAPPDATA$|XDG_(?:DATA|CACHE|STATE)_HOME$)|API_KEY|TOKEN|SECRET|PASSWORD/i.test(key)) delete env[key];
}
env.HOME = join(root, "home");
env.USERPROFILE = env.HOME;
env.PI_CONFIG_DIR = ".omp";
env.LOCALAPPDATA = join(env.HOME, "AppData", "Local");
env.XDG_CACHE_HOME = join(env.HOME, ".cache");
env.XDG_STATE_HOME = join(env.HOME, ".local", "state");
env.GIT_CONFIG_NOSYSTEM = "1";
env.GIT_CONFIG_GLOBAL = join(root, "gitconfig");
env.GH_CONFIG_DIR = join(root, "gh-config");
const git = (...args) => execFileSync("git", args, { env, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });

function audit(sessionDir, overrides = {}) {
	const childEnv = { ...env, ...overrides };
	if (sessionDir !== undefined) childEnv.PI_CODING_AGENT_SESSION_DIR = forward(sessionDir);
	const result = spawnSync(bash, [forward(script), "--base", "HEAD", forward(repo)], {
		encoding: "utf8",
		env: childEnv,
	});
	assert.equal(result.status, 0, result.stderr || String(result.error));
	const rows = new Map(result.stdout.split(/\r?\n/).filter((line) => line.includes("\t") && !line.startsWith("SIZE\t"))
		.map((line) => {
			const cells = line.split("\t");
			assert.equal(cells.length, 9, line);
			return [forward(cells[8]), { dirty: cells[3], lastChat: cells[6], bucket: cells[7] }];
		}));
	assert.equal(rows.size, 4, result.stdout);
	return { rows, stderr: result.stderr };
}

async function nativeSessionFile(cwd, overrides) {
	const child = spawn(process.platform === "win32" ? "omp.exe" : "omp", [
		"--mode", "rpc", "--cwd", cwd, "--no-title", "--no-extensions", "--no-skills",
		"--no-rules", "--no-lsp", "--no-tools", "--model", process.argv[3] ?? "anthropic/claude-sonnet-4-5",
	], { cwd, env: { ...env, ...overrides }, stdio: ["pipe", "pipe", "pipe"] });
	const lines = createInterface({ input: child.stdout })[Symbol.asyncIterator]();
	let spawnError;
	child.on("error", (error) => { spawnError = error; });
	child.stderr.resume();
	const exited = new Promise((resolveExit) => child.once("close", resolveExit));
	const timer = setTimeout(() => child.kill(), 60000);
	try {
		let sessionFile;
		for (; ;) {
			const { value, done } = await lines.next();
			assert(!done, spawnError?.message ?? "OMP ended before returning sessionFile");
			const frame = JSON.parse(value);
			assert(!["agent_start", "assistant_message"].includes(frame.type), "Session discovery must not invoke inference");
			if (frame.type === "ready") child.stdin.write('{"id":"path","type":"get_state"}\n');
			if (frame.id === "path") {
				assert.equal(frame.success, true, "Native get_state failed");
				sessionFile = frame.data?.sessionFile;
				assert.equal(typeof sessionFile, "string", "Native sessionFile missing");
				assert(sessionFile.length > 0, "Native sessionFile empty");
				const inside = relative(root, resolve(sessionFile));
				assert(inside !== "" && inside !== ".." && !inside.startsWith(".." + sep) && !isAbsolute(inside),
					"Native sessionFile must stay inside the fixture root");
				break;
			}
		}
		child.stdin.end();
		assert.equal(await exited, 0, "Native session lookup must exit cleanly");
		return sessionFile;
	} finally {
		clearTimeout(timer);
		if (child.exitCode === null) child.kill();
		await exited;
	}
}

function assertUnavailable(result) {
	assert.match(result.stderr, /session enrichment unavailable/);
	for (const row of result.rows.values()) {
		assert.equal(row.bucket, "verify-session-unavailable");
		assert.equal(row.lastChat, "unavailable");
	}
}

function snapshot(directory) {
	const entries = [];
	const visit = (parent) => {
		for (const entry of readdirSync(parent, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
			const file = join(parent, entry.name);
			entries.push([relative(directory, file), entry.isDirectory() ? "directory" :
				entry.isSymbolicLink() ? readlinkSync(file) : createHash("sha256").update(readFileSync(file)).digest("hex")]);
			if (entry.isDirectory()) visit(file);
		}
	};
	visit(directory);
	return entries;
}

try {
	writeFileSync(env.GIT_CONFIG_GLOBAL, "");
	mkdirSync(env.HOME);
	mkdirSync(repo);
	mkdirSync(sessions);
	git("-C", repo, "init", "--initial-branch", "main");
	git("-C", repo, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-m", "fixture");
	for (const [branch, path] of [["active", active], ["legacy", legacy], ["parent-owned", parentOwned], ["idle", idle]]) {
		git("-C", repo, "worktree", "add", "-b", branch, path);
	}
	// GitHub CLI's device-id cache is outside OMP's read-only profile contract.
	spawnSync("gh", ["pr", "list", "--state", "all", "--limit", "1", "--json", "number"], { cwd: repo, env, stdio: "ignore" });
	const alias = join(root, "active alias");
	symlinkSync(active, alias, process.platform === "win32" ? "junction" : "dir");
	for (const profile of [undefined, "fresh-profile", "legacy-profile"]) {
		const overrides = profile ? { OMP_PROFILE: profile } : {};
		if (profile === "legacy-profile") {
			const agent = join(env.HOME, ".omp", "profiles", profile, "agent");
			mkdirSync(agent, { recursive: true });
			writeFileSync(join(agent, "settings.json"), '{ "model": "legacy-fixture", "privateValue": "unchanged" }\n');
		}
		const before = snapshot(env.HOME);
		for (const row of audit(undefined, overrides).rows.values()) {
			assert.equal(row.bucket, "safe");
			assert.equal(row.lastChat, "-");
		}
		assert.deepEqual(snapshot(env.HOME), before, "Audit must not initialize profiles, migrate settings, or extract native caches");
	}

	const defaultAgent = join(env.HOME, ".omp", "agent");
	const profileAgent = join(env.HOME, ".omp", "profiles", "dotenv-profile", "agent");
	const selectedAgent = join(env.HOME, "dotenv agent");
	const lowerPriority = join(env.HOME, "lower-priority agent");
	const projectEnv = join(repo, ".env");
	const quote = (value) => JSON.stringify(forward(value));
	for (const scenario of [
		{
			name: "agent-dotenv", overrides: {}, dotenv: join(defaultAgent, ".env"), content:
				`PI_CODING_AGENT_DIR=${quote(lowerPriority)}\nOMP_CODING_AGENT_DIR=${quote(selectedAgent)}\n`, expected: selectedAgent
		},
		{
			name: "project-precedence", overrides: {}, dotenv: projectEnv, content:
				`OMP_CODING_AGENT_DIR=${quote(selectedAgent)}\n`, expected: selectedAgent, lowerFiles: true
		},
		{
			name: "frozen-profile", overrides: { OMP_PROFILE: "dotenv-profile", PI_CODING_AGENT_DIR: lowerPriority },
			dotenv: join(profileAgent, ".env"), content: `OMP_PROFILE=other-profile\nOMP_CODING_AGENT_DIR=${quote(selectedAgent)}\n`, expected: profileAgent
		},
		{
			name: "dotenv-default-profile", overrides: { OMP_PROFILE: "", PI_PROFILE: "unused" },
			dotenv: join(defaultAgent, ".env"),
			content: `OMP_PROFILE=dotenv-profile\nOMP_CODING_AGENT_DIR=${quote(selectedAgent)}\n`, expected: selectedAgent
		},
		{
			name: "launch-omp-agent-alias-ignored", overrides: { OMP_CODING_AGENT_DIR: lowerPriority },
			dotenv: join(defaultAgent, ".env"), content: "", expected: defaultAgent
		},
		{
			name: "invalid-lower-profile-ignored", overrides: { OMP_PROFILE: "default", PI_PROFILE: "invalid/profile" },
			dotenv: join(defaultAgent, ".env"), content: "", expected: defaultAgent
		},
		{
			name: "empty-omp-profile", overrides: process.platform === "win32" ?
				{ oMp_PrOfIlE: "", pI_PrOfIlE: "dotenv-profile", pI_cOdInG_aGeNt_DiR: profileAgent } :
				{ OMP_PROFILE: "", PI_PROFILE: "dotenv-profile", PI_CODING_AGENT_DIR: profileAgent },
			dotenv: join(defaultAgent, ".env"), content: "# The explicit empty OMP profile selects default.\n", expected: defaultAgent
		},
		{
			name: "config-dotenv", overrides: { PI_CONFIG_DIR: "" }, dotenv: join(defaultAgent, ".env"),
			content: "OMP_CONFIG_DIR=.dotenv-config\n", expected: join(env.HOME, ".dotenv-config", "agent")
		},
		...(process.platform === "win32" ? [{
			name: "mixed-case-profile", overrides: { oMp_PrOfIlE: "dotenv-profile" },
			dotenv: join(profileAgent, ".env"), content: "# Windows environment keys ignore case.\n", expected: profileAgent,
		}] : []),
	]) {
		const files = [scenario.dotenv];
		if (scenario.lowerFiles) {
			for (const file of [join(defaultAgent, ".env"), join(env.HOME, ".omp", ".env"), join(env.HOME, ".env")]) {
				mkdirSync(dirname(file), { recursive: true });
				writeFileSync(file, `OMP_CODING_AGENT_DIR=${quote(lowerPriority)}\n`);
				files.push(file);
			}
		}
		mkdirSync(dirname(scenario.dotenv), { recursive: true });
		writeFileSync(scenario.dotenv, scenario.content);
		const file = await nativeSessionFile(repo, scenario.overrides);
		const inside = relative(join(scenario.expected, "sessions"), file);
		assert(inside !== ".." && !inside.startsWith(".." + sep) && !isAbsolute(inside), scenario.name);
		mkdirSync(dirname(file), { recursive: true });
		writeFileSync(file, JSON.stringify({ type: "session", cwd: repo }) + "\n" +
			JSON.stringify({ type: "message", text: forward(active) + "/file.ts" }) + "\n");
		writeFileSync(projectEnv, (scenario.dotenv === projectEnv ? scenario.content : "") +
			`GIT_DIR=${quote(join(root, "not-a-git-directory"))}\nPRIVATE_FIXTURE_VALUE=must-not-be-printed\n`);
		const before = snapshot(env.HOME);
		const result = audit(undefined, scenario.overrides);
		assert.equal(result.rows.get(forward(active)).bucket, "verify-recent-chat", scenario.name);
		assert.equal(result.rows.get(forward(idle)).bucket, "safe", scenario.name);
		assert(!result.stderr.includes("must-not-be-printed"), scenario.name);
		assert.deepEqual(snapshot(env.HOME), before, scenario.name);
		rmSync(file);
		for (const dotenv of new Set([...files, projectEnv])) rmSync(dotenv);
	}
	if (process.platform === "linux" || process.platform === "darwin") {
		const xdg = join(env.HOME, "dotenv-data");
		for (const profile of [undefined, "xdg-profile"]) {
			const overrides = profile ? { OMP_PROFILE: profile } : {};
			const initialAgent = profile ? join(env.HOME, ".omp", "profiles", profile, "agent") : defaultAgent;
			const data = profile ? join(xdg, "omp", "profiles", profile) : join(xdg, "omp");
			mkdirSync(data, { recursive: true });
			mkdirSync(initialAgent, { recursive: true });
			writeFileSync(join(initialAgent, ".env"), `XDG_DATA_HOME=${quote(xdg)}\n`);
			const file = await nativeSessionFile(repo, overrides);
			const inside = relative(join(data, "sessions"), file);
			assert(inside !== ".." && !inside.startsWith(".." + sep) && !isAbsolute(inside), "Native dotenv XDG root");
			mkdirSync(dirname(file), { recursive: true });
			writeFileSync(file, JSON.stringify({ type: "session", cwd: repo }) + "\n" +
				JSON.stringify({ type: "message", text: forward(active) + "/file.ts" }) + "\n");
			const before = snapshot(env.HOME);
			assert.equal(audit(undefined, overrides).rows.get(forward(active)).bucket, "verify-recent-chat");
			assert.deepEqual(snapshot(env.HOME), before, "XDG audit must not write state");
			rmSync(file);
			rmSync(join(initialAgent, ".env"));
		}
	} else {
		console.log("worktree-audit dotenv XDG roots: SKIP (requires Linux or macOS)");
	}
	if (process.platform === "win32") {
		assertUnavailable(audit(undefined, { PI_CODING_AGENT_DIR: "C:relative-agent" }));
		writeFileSync(projectEnv, `PI_CODING_AGENT_DIR=${quote(selectedAgent)}\npi_coding_agent_dir=${quote(lowerPriority)}\n`);
		assertUnavailable(audit());
		rmSync(projectEnv);
	}
	mkdirSync(projectEnv);
	assertUnavailable(audit());
	rmSync(projectEnv, { recursive: true });
	writeFileSync(projectEnv, "PRIVATE_FIXTURE_VALUE=must-not-be-printed\n");
	chmodSync(projectEnv, 0);
	try {
		let denied = false;
		try {
			readFileSync(projectEnv);
		} catch (error) {
			if (error.code !== "EACCES" && error.code !== "EPERM") throw error;
			denied = true;
		}
		if (denied) assertUnavailable(audit());
		else console.log("worktree-audit unreadable dotenv: SKIP (permissions do not deny access)");
	} finally {
		chmodSync(projectEnv, 0o600);
		rmSync(projectEnv);
	}
	for (const overrides of [{}, { PI_CODING_AGENT_DIR: join(root, "custom agent") }]) {
		for (const row of audit(undefined, overrides).rows.values()) {
			assert.equal(row.bucket, "safe");
			assert.equal(row.lastChat, "-");
		}
		const activeFile = await nativeSessionFile(active, overrides);
		const parentFile = await nativeSessionFile(repo, overrides);
		const unrelated = join(root, "unrelated-project");
		mkdirSync(unrelated, { recursive: true });
		const unrelatedFile = await nativeSessionFile(unrelated, overrides);
		for (const file of [activeFile, parentFile, unrelatedFile]) mkdirSync(dirname(file), { recursive: true });
		writeFileSync(activeFile, JSON.stringify({ type: "session", cwd: active }) + "\n");
		writeFileSync(parentFile, [
			JSON.stringify({ type: "session", cwd: repo }),
			JSON.stringify({ type: "message", text: forward(parentOwned) + "/file.ts" }),
		].join("\n") + "\n");
		writeFileSync(unrelatedFile, "{not-json}\n");
		for (const sessionDir of [undefined, ""]) {
			const result = audit(sessionDir, overrides);
			assert.equal(result.stderr.includes("session enrichment unavailable"), false, result.stderr);
			for (const path of [active, parentOwned]) {
				assert.equal(result.rows.get(forward(path)).bucket, "verify-recent-chat");
				assert.match(result.rows.get(forward(path)).lastChat, /^\d{4}-\d{2}-\d{2}$/);
			}
			for (const path of [legacy, idle]) {
				assert.equal(result.rows.get(forward(path)).bucket, "safe");
				assert.equal(result.rows.get(forward(path)).lastChat, "-");
			}
		}
		const aliasFile = await nativeSessionFile(alias, overrides);
		assert.equal(dirname(aliasFile), dirname(activeFile), "Native alias lookup must use the canonical bucket");
		writeFileSync(activeFile, JSON.stringify({ type: "session", cwd: alias }) + "\n");
		assert.equal(audit(undefined, overrides).rows.get(forward(active)).bucket, "verify-recent-chat");
		if (process.platform === "win32") {
			writeFileSync(activeFile, JSON.stringify({ type: "session", cwd: active.toUpperCase() }) + "\n");
			assert.equal(audit(undefined, overrides).rows.get(forward(active)).bucket, "verify-recent-chat");
		}
		writeFileSync(activeFile, [
			JSON.stringify({ type: "session", cwd: unrelated }),
			JSON.stringify({ type: "message", text: forward(idle) + "/file.ts" }),
		].join("\n") + "\n");
		const unrelatedHeader = audit(undefined, overrides).rows;
		assert.equal(unrelatedHeader.get(forward(active)).bucket, "safe");
		assert.equal(unrelatedHeader.get(forward(idle)).bucket, "safe");
		assert.equal(unrelatedHeader.get(forward(parentOwned)).bucket, "verify-recent-chat");
		for (const cwd of [join(root, "missing-header-workspace"), "relative/workspace"]) {
			writeFileSync(activeFile, JSON.stringify({ type: "session", cwd }) + "\n");
			assertUnavailable(audit(undefined, overrides));
		}
		for (const content of ["{not-json}\n", JSON.stringify({ type: "session", cwd: "\u0000" }) + "\n"]) {
			writeFileSync(activeFile, content);
			assertUnavailable(audit(undefined, overrides));
		}
		rmSync(activeFile);
		rmSync(parentFile);
		rmSync(unrelatedFile);
	}
	const invalidProfile = "invalid/private-profile";
	const unavailable = audit(undefined, { OMP_PROFILE: invalidProfile });
	assertUnavailable(unavailable);
	assert(!unavailable.stderr.includes(invalidProfile), "Lookup diagnostics must not expose config values");
	assertUnavailable(audit(undefined, { PI_CONFIG_DIR: "invalid\nconfig" }));
	const notDirectory = join(root, "not-a-directory");
	writeFileSync(notDirectory, "");
	assertUnavailable(audit(undefined, { PI_CODING_AGENT_DIR: notDirectory }));
	assertUnavailable(audit(sessions + "\n"));
	const missing = audit(join(root, "missing"));
	assert.match(missing.stderr, /session enrichment unavailable/);
	for (const row of missing.rows.values()) assert.equal(row.bucket, "verify-session-unavailable");

	const empty = audit(sessions, { OMP_PROFILE: invalidProfile }).rows;
	for (const row of empty.values()) {
		assert.equal(row.bucket, "safe");
		assert.equal(row.lastChat, "-");
	}

	const index = git("-C", idle, "rev-parse", "--git-path", "index").trim();
	const originalIndex = readFileSync(index);
	writeFileSync(index, "invalid index\n");
	try {
		const row = audit(sessions).rows.get(forward(idle));
		assert.equal(row.dirty, "error", "A failed status must not be reported as clean");
		assert.equal(row.bucket, "hold-error", "A failed status must block cleanup");
	} finally {
		writeFileSync(index, originalIndex);
	}

	const lockSession = join(sessions, "locked.jsonl");
	writeFileSync(lockSession, JSON.stringify({ type: "session", cwd: idle }) + "\n");
	for (const reason of [[], ["--reason", "fixture lock"]]) {
		git("-C", repo, "worktree", "lock", ...reason, idle);
		try {
			assert.equal(audit(sessions).rows.get(forward(idle)).bucket, "hold-locked", "Lock must override recent activity");
			assert.equal(audit(join(root, "missing")).rows.get(forward(idle)).bucket, "hold-locked", "Lock must override unavailable enrichment");
		} finally {
			git("-C", repo, "worktree", "unlock", idle);
		}
	}
	rmSync(lockSession);

	if (process.platform === "win32") {
		const windowsSession = join(sessions, "windows-path.jsonl");
		for (const [text, bucket] of [
			[join(parentOwned, "file.ts"), "verify-recent-chat"],
			[join(parentOwned, "file.ts").toLowerCase(), "verify-recent-chat"],
			[parentOwned, "verify-recent-chat"],
			[`${parentOwned}-other\\file.ts`, "safe"],
		]) {
			writeFileSync(windowsSession, [
				JSON.stringify({ type: "session", cwd: repo }),
				JSON.stringify({ type: "message", text }),
			].join("\n") + "\n");
			assert.equal(audit(sessions).rows.get(forward(parentOwned)).bucket, bucket, "Native Windows paths must match only at path boundaries");
		}
		rmSync(windowsSession);
	} else {
		console.log("worktree-audit Windows transcript paths: SKIP (requires native Windows paths)");
	}

	if (process.platform !== "win32") {
		const backslashCwd = idle.replace(/\/idle$/, "\\idle");
		const backslashSession = join(sessions, "backslash-cwd.jsonl");
		mkdirSync(backslashCwd);
		try {
			writeFileSync(backslashSession, JSON.stringify({ type: "session", cwd: backslashCwd }) + "\n");
			const row = audit(sessions).rows.get(idle);
			assert.equal(row.bucket, "safe", "A POSIX backslash must not become a path separator");
			assert.equal(row.lastChat, "-");
		} finally {
			rmSync(backslashSession);
			rmSync(backslashCwd, { recursive: true });
		}
	} else {
		console.log("worktree-audit POSIX backslash cwd: SKIP (requires POSIX filenames)");
	}

	const malformedPath = join(sessions, "malformed.jsonl");
	writeFileSync(malformedPath, "{not-json}\n");
	for (const row of audit(sessions).rows.values()) {
		assert.equal(row.bucket, "verify-session-unavailable");
		assert.equal(row.lastChat, "unavailable");
	}
	rmSync(malformedPath);
	for (const [name, content] of [
		["nul-cwd", JSON.stringify({ type: "session", cwd: "\u0000" }) + "\n"],
		["empty-header", ""],
		["missing-header", JSON.stringify({ type: "title", title: "fixture" }) + "\n"],
		["invalid-cwd", JSON.stringify({ type: "session", cwd: 42 }) + "\n"],
		["empty-cwd", JSON.stringify({ type: "session", cwd: "" }) + "\n"],
		["tab-cwd", JSON.stringify({ type: "session", cwd: active + "\tother" }) + "\n"],
		["cr-cwd", JSON.stringify({ type: "session", cwd: active + "\rother" }) + "\n"],
		["newline-cwd", JSON.stringify({ type: "session", cwd: active + "\nother" }) + "\n"],
		["malformed-second", JSON.stringify({ type: "session", cwd: repo }) + "\n{not-json}\n"],
	]) {
		const path = join(sessions, name + ".jsonl");
		writeFileSync(path, content);
		for (const row of audit(sessions).rows.values()) {
			assert.equal(row.bucket, "verify-session-unavailable", name);
			assert.equal(row.lastChat, "unavailable", name);
		}
		rmSync(path);
	}
	if (process.platform !== "win32") {
		for (const [name, control] of [["tab", "\t"], ["cr", "\r"], ["newline", "\n"]]) {
			const path = join(sessions, `unsupported${control}filename.jsonl`);
			writeFileSync(path, JSON.stringify({ type: "session", cwd: active }) + "\n");
			for (const row of audit(sessions).rows.values()) {
				assert.equal(row.bucket, "verify-session-unavailable", name + " filename");
				assert.equal(row.lastChat, "unavailable", name + " filename");
			}
			rmSync(path);
		}
	} else {
		console.log("worktree-audit control filename: SKIP (Windows forbids control characters in filenames)");
	}

	writeFileSync(join(sessions, "active.jsonl"), [
		JSON.stringify({ type: "title", title: "fixture" }),
		JSON.stringify({ type: "session", cwd: active }),
	].join("\n") + "\n");
	writeFileSync(join(sessions, "legacy.jsonl"), JSON.stringify({ type: "session", cwd: legacy }) + "\n");
	writeFileSync(join(sessions, "parent.jsonl"), [
		JSON.stringify({ type: "session", cwd: repo }),
		JSON.stringify({ type: "message", text: forward(parentOwned) + "/file.ts" }),
	].join("\n") + "\n");
	writeFileSync(join(sessions, "unrelated.jsonl"), [
		JSON.stringify({ type: "session", cwd: join(root, "unrelated-project") }),
		JSON.stringify({ type: "message", text: forward(idle) + "/file.ts" }),
	].join("\n") + "\n");
	const scoped = audit(sessions).rows;
	for (const path of [active, legacy, parentOwned]) {
		assert.equal(scoped.get(forward(path)).bucket, "verify-recent-chat");
		assert.match(scoped.get(forward(path)).lastChat, /^\d{4}-\d{2}-\d{2}$/);
	}
	assert.equal(scoped.get(forward(idle)).bucket, "safe");
	assert.equal(scoped.get(forward(idle)).lastChat, "-");

	const unreadableFile = join(sessions, "unreadable.jsonl");
	const unreadableDirectory = join(sessions, "unreadable-directory");
	writeFileSync(unreadableFile, JSON.stringify({ type: "session", cwd: active }) + "\n");
	mkdirSync(unreadableDirectory);
	writeFileSync(join(unreadableDirectory, "session.jsonl"), JSON.stringify({ type: "session", cwd: idle }) + "\n");
	for (const [path, probe, mode] of [
		[unreadableFile, readFileSync, 0o600],
		[unreadableDirectory, readdirSync, 0o700],
	]) {
		chmodSync(path, 0);
		try {
			let denied = false;
			try {
				probe(path);
			} catch (error) {
				if (error.code !== "EACCES" && error.code !== "EPERM") throw error;
				denied = true;
			}
			if (!denied) {
				console.log(`worktree-audit unreadable input: SKIP (permissions do not deny access to ${path})`);
				continue;
			}
			const result = audit(sessions);
			assert.match(result.stderr, /session enrichment unavailable/);
			for (const row of result.rows.values()) {
				assert.equal(row.bucket, "verify-session-unavailable", path);
				assert.equal(row.lastChat, "unavailable", path);
			}
		} finally {
			chmodSync(path, mode);
		}
	}
	rmSync(unreadableFile);
	rmSync(unreadableDirectory, { recursive: true });
	console.log("worktree-audit entrypoint: PASS");
} finally {
	rmSync(root, { recursive: true, force: true });
}
