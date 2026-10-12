import { execFileSync } from "node:child_process";
import { lstatSync, readFileSync, realpathSync, statSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import path from "node:path";
import * as util from "node:util";

function safePath(value) {
	if (!value || /[\x00-\x1f\x7f-\x9f]/u.test(value)) throw new Error();
	return value;
}

function canonicalPath(value) {
	if (!path.isAbsolute(safePath(value))) throw new Error();
	return safePath(realpathSync(value));
}

function existingDirectory(directory) {
	try {
		lstatSync(directory);
	} catch (error) {
		if (error.code !== "ENOENT") throw error;
		const parent = path.dirname(directory);
		if (parent === directory) throw error;
		existingDirectory(parent);
		return false;
	}
	if (!statSync(directory).isDirectory()) throw new Error();
	return true;
}

function profileName(value = "") {
	if (/[\x00-\x1f\x7f-\x9f]/u.test(value)) throw new Error();
	const name = value.trim();
	if (!name || name === "default") return "";
	if (!/^[a-z0-9][a-z0-9._-]{0,63}$/.test(name) || name.endsWith(".") ||
		/^(?:CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])(?:\..*)?$/i.test(name)) throw new Error();
	return name;
}

function sessionRoot() {
	if (typeof util.parseEnv !== "function") throw new Error();
	const envKey = (key) => process.platform === "win32" ? key.toUpperCase() : key;
	const selectors = new Set([
		"PI_CONFIG_DIR", "PI_CODING_AGENT_DIR", "OMP_PROFILE", "PI_PROFILE", "XDG_DATA_HOME",
		"HOME", "USERPROFILE", "TMPDIR", "TMP", "TEMP", "SystemRoot", "windir",
	].map(envKey));
	const selected = Object.create(null);
	for (const [key, value] of Object.entries(process.env)) {
		const name = envKey(key);
		if (!selectors.has(name)) continue;
		if (selected[name] !== undefined && selected[name] !== value) throw new Error();
		selected[name] = value;
	}
	const profile = profileName(selected.OMP_PROFILE ?? selected.PI_PROFILE);
	const profileParts = profile ? ["profiles", profile] : [];
	const agentPaths = () => {
		const configRoot = path.join(safePath(homedir()), safePath(selected.PI_CONFIG_DIR || ".omp"));
		const config = path.join(configRoot, ...profileParts);
		const defaultAgent = path.join(config, "agent");
		let override = selected.PI_CODING_AGENT_DIR;
		let inheritedProfile = "";
		// Native ignores invalid lower-priority profile hints.
		try { inheritedProfile = profileName(selected.PI_PROFILE); } catch { }
		if (inheritedProfile && override === path.join(configRoot, "profiles", inheritedProfile, "agent")) override = undefined;
		if (!profile && override && process.platform === "win32" && /^[a-z]:($|[^\\/])/i.test(override)) throw new Error();
		const agent = !profile && override ? path.resolve(safePath(override)) : defaultAgent;
		return { config, agent, defaultAgent };
	};
	const initial = agentPaths();
	const files = [
		path.join(process.cwd(), ".env"), path.join(initial.agent, ".env"),
		path.join(initial.config, ".env"), path.join(safePath(homedir()), ".env"),
	];
	for (const file of files) {
		try {
			lstatSync(file);
		} catch (error) {
			if (error.code !== "ENOENT") throw error;
			existingDirectory(path.dirname(file));
			continue;
		}
		if (!statSync(file).isFile()) throw new Error();
		const parsed = util.parseEnv(readFileSync(file, "utf8"));
		const values = Object.create(null);
		for (const [key, value] of Object.entries(parsed)) {
			const alias = key.startsWith("OMP_") ? `PI_${key.slice(4)}` : key;
			if ((selectors.has(envKey(key)) || selectors.has(envKey(alias))) &&
				/^[A-Za-z_][A-Za-z0-9_]*$/.test(key) && !value.includes("\0")) values[key] = value;
		}
		for (const key of Object.keys(values)) {
			if (key.startsWith("OMP_")) values[`PI_${key.slice(4)}`] = values[key];
		}
		const retained = Object.create(null);
		for (const [key, value] of Object.entries(values)) {
			const name = envKey(key);
			if (!selectors.has(name)) continue;
			if (retained[name] !== undefined && retained[name] !== value) throw new Error();
			retained[name] = value;
		}
		for (const [key, value] of Object.entries(retained)) {
			if (!selected[key]) selected[key] = value;
		}
	}
	// Only OS path selectors reach this process's os helpers. Git keeps its inherited environment.
	for (const key of ["HOME", "USERPROFILE", "TMPDIR", "TMP", "TEMP", "SystemRoot", "windir"]) {
		if (selected[envKey(key)] !== undefined) process.env[key] = selected[envKey(key)];
	}
	profileName(selected.OMP_PROFILE ?? selected.PI_PROFILE);
	const { agent, defaultAgent } = agentPaths();
	let base = agent;
	if ((process.platform === "linux" || process.platform === "darwin") && agent === defaultAgent && selected.XDG_DATA_HOME) {
		const xdg = path.join(safePath(selected.XDG_DATA_HOME), "omp", ...profileParts);
		if (existingDirectory(xdg)) base = xdg;
	}
	return path.resolve(base, "sessions");
}

function sessionDirectories() {
	const options = { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], timeout: 30000, env: { ...process.env } };
	const sessions = sessionRoot();
	const home = safePath(homedir());
	const temp = safePath(tmpdir());
	const canonicalHome = canonicalPath(home);
	const canonicalTemp = canonicalPath(temp);
	const listing = execFileSync("git", ["worktree", "list", "--porcelain", "-z"], options);
	if (!listing.endsWith("\0\0")) throw new Error();
	const directories = new Set();
	for (const record of listing.slice(0, -2).split("\0\0")) {
		const field = record.split("\0")[0];
		if (!field.startsWith("worktree ")) throw new Error();
		const cwd = canonicalPath(field.slice(9));
		const inTemp = path.relative(canonicalTemp, cwd);
		const inHome = path.relative(canonicalHome, cwd);
		const within = (relative) => !relative.startsWith("..") && !path.isAbsolute(relative);
		let key;
		if (within(inTemp)) key = inTemp ? "-tmp-" + inTemp.replace(/[/\\:]/g, "-") : "-tmp";
		else if (within(inHome)) key = "-" + inHome.replace(/[/\\:]/g, "-");
		else key = "--" + cwd.replace(/^[/\\]/, "").replace(/[/\\:]/g, "-") + "--";
		const directory = safePath(path.join(sessions, key));
		if (existingDirectory(directory)) directories.add(directory);
	}
	return [...directories];
}

try {
	let directories;
	if (process.argv[2] === "--owner") {
		const cwd = canonicalPath(process.argv[3]);
		const worktrees = process.argv.slice(4);
		if (!worktrees.length) throw new Error();
		const canonicalWorktrees = worktrees.map(canonicalPath);
		const index = canonicalWorktrees.findIndex((worktree) => path.relative(worktree, cwd) === "");
		directories = index < 0 ? [] : [safePath(worktrees[index])];
	} else {
		if (process.argv.length !== 2) throw new Error();
		directories = sessionDirectories();
	}
	if (directories.length) process.stdout.write(directories.map((directory) => process.platform === "win32" ? directory.replaceAll("\\", "/") : directory).join("\n") + "\n");
} catch {
	process.exitCode = 1;
}
