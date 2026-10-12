# OMP session history

This reference supports recall, reflect, eval, session-pickup, show-me-your-work, and automate-me. Session history can contain private prompts, tool output, and secrets. Access remains limited to the session and project the user authorized.

## Internal resources

For registered agents, `history://` lists their status and parent. `history://<id>:1-50` reads a bounded transcript range. `agent://<id>` reads the output artifact. Use returned identifiers, including dotted child IDs, rather than constructing them from directory names. Structured fields use the live resource's documented path syntax.

These resources are preferable to disk searches when they expose the required history. A registry entry or old transcript timestamp does not prove that a worker is still running. `skill://pstack-omp` owns live status and messaging mechanics. Do not inspect unrelated agents merely because the registry lists them.

## Session root and project bucket

The default root is `~/.omp/agent/sessions/`, but the active profile or environment can relocate it. An explicit session directory or `PI_CODING_AGENT_SESSION_DIR` can select a different root. `PI_CODING_AGENT_DIR`, profile configuration, and supported XDG roots can also affect the default. Resolve the active store before globbing. Do not infer a Windows path from a POSIX example or assume every host uses the default profile.

Buckets use the canonicalized working directory, so symlinked spellings can share a bucket. In the path-encoded layout:

- A home-relative path has its separators replaced with hyphens, preserving a leading hyphen.
- A temporary-root path uses `-tmp-<rest>`.
- Other paths use `--<encoded-absolute>--`.

Some older stores have hashed bucket names. Encoded names can also collide. Confirm the transcript header's `cwd` matches the authorized project rather than trusting a bucket name. Search only that confirmed bucket, never sibling project buckets or the whole session root.

## Transcript and artifact files

A transcript is a flat `<timestamp>_<session-id>.jsonl` file. Timestamp colons and the millisecond dot become hyphens for filesystem compatibility. Its sibling directory with the same stem is the artifact namespace.

That directory can contain child JSONL transcripts, final Markdown and JSON outputs, session-local scratch artifacts, and nested child directories. Nested files can carry full dotted agent IDs. The current runtime and actual directory listing determine what is available. An artifact's presence does not grant access beyond the authorized scope.

## Transcript records

A current transcript begins with a padded, fixed-width `type: title` record. It is not a message. The following `type: session` header carries the session ID, timestamp, cwd, and title. Legacy transcripts may begin at that header. The title record can differ from the header title.

User turns are `type: message` records with `role: user`. Persisted tool-result roles use `toolResult`, not `tool_result`. `toolCall` is an assistant content block, not a role. Match the actual user message when identifying a prior conversation. Agent results and notifications are not user turns.

`/clear` appends a durable `reset_boundary`. Current model context begins after the latest boundary, while the raw file still contains earlier material. Keep a pickup within the requested scope and boundary. Earlier records require explicit historical scope and must not be presented as the current conversation.

Use bounded reads and quote only the evidence needed for the task. Exclude secrets from reports and shared artifacts. Do not modify, retitle, migrate, or delete history during a read-only investigation or status request.
