# Apply to upstream Markdown only. Structural runtime adaptations live in patches/.
# Match raw Cursor mechanics before replacing model names or tool tokens.

/^Spawn one Task subagent with `subagent_type: generalPurpose` and `readonly: true` that explores and explains/c\
Resolve one explainer through `skill://pstack-omp` that explores and explains in one pass. Give it a read-only brief with an explicit write ban, the user's question, and the brief below. Model selection stays in the operator's `modelRoles` and `task.agentModelOverrides`; do not change it for this workflow.
/^3\. Pick the worker model from /c\
3. Resolve the worker role and existing model configuration through `skill://pstack-omp`. For a model race, record each arm's returned model metadata; do not infer diversity from different prompts or change operator configuration.
/^3\. Pick the runners from the `arena runners` line /c\
3. Resolve runners through `skill://pstack-omp` using existing role configuration. Prefer different model families for judgment-sensitive work when returned metadata proves it, and report unavailable diversity. Spawn more runners when the arena covers multiple design directions. Use the same model N times when the work is generation-bound rather than judgment-sensitive.
/^After all Phase B candidates complete, spawn one readonly judge /c\
After all Phase B candidates complete, start a read-only cross-judge through `skill://pstack-omp`. Prefer a different model family from the parent's when returned metadata proves it; otherwise report the limitation. It sees the rubric and candidates by sanitized path label, scores each criterion, and recommends a base with rationale. It runs in parallel with your reading in Phase D. Do not spawn it while candidates are still writing.
s#Spawn all N workers in one message with .*#Spawn all N workers through `skill://pstack-omp`: one `tasks[]` batch when exposed, otherwise one flat `task`/`solutionSpace` call per worker, all before waiting. Give each a standalone brief and explicit write ownership. Create separate worktrees before dispatch when workers may write the same paths.#
s#Spawn all N subagents in one message with `run_in_background: true`, each with#Spawn all N subagents through `skill://pstack-omp`, in one `tasks[]` batch when exposed or separate flat `task`/`solutionSpace` calls before waiting, each with#
s#`subagent_type: "([^"]+)"`#`agent`: `\1`#g
s#Spawn each adversary as `generalPurpose`\.#Start each adversary through `skill://pstack-omp` as a worker with write access limited to its own worktree.#
s#Spawn one investigator subagent per source, in agent mode because readonly strips MCP access, and ask each#Start one investigator per source through `skill://pstack-omp`, with the MCP access it needs and an explicit write ban, and ask each#
s#When a worker must start from a non-default pushed branch, pass `cloud_base_branch`\.#When a worker needs a non-default base, create its private `git worktree` on that exact base before dispatch and name the absolute path in its brief.#
s#each a Cursor cloud agent#each a root-started worker in its own worktree#g
s#as cloud agents#in separate worktrees#g

/^\*\*You own the verdicts, never the PRs\./c\
**You own the verdicts and authorized publication. One local owner prepares each PR from build to merge-ready, and the root merges only on its clean swarm verdict.** For "autopilot this queue", "full autopilot", and one-owner-per-PR programs. Orchestrate runs a standing program whose coordinator lands verified work. Here each PR's owner keeps the local lifecycle, while the root performs pushes, PR mutations, approvals, and merges under the operator's grant and existing gates.
s#Pick each subagent's reasoning level for the job, per the Subagents section#Keep each subagent's configured model and effort, per the Subagents section#g
s#the owner rebases its own branch and publishes it with `git push --force-with-lease`\.#the owner prepares the local rebase and reports its exact head; the root publishes it with `git push --force-with-lease`.#
s#Push that wave before replying so the reply cites the commit\. Reply with#The babysitter returns the local wave, exact head, and proposed replies; the root pushes the authorized wave before replying so each reply cites the published commit, then replies with#
s#No PR and no push unless you already had one out\.#Children return local evidence and any publication request to the root. The root opens no PR and performs no push unless one was already out and the operation remains authorized.#

s#`claude-opus-[0-9.-]+-(medium|low)-fast`#your fast code model#g
s#`claude-(fable|opus)-[0-9.-]+(-(thinking-)?[a-z]+)*`#your strongest judgment model#g
s#`(claude|gpt|grok|gemini|opus)-[a-z0-9.]+-[a-z0-9.-]+`#your configured model for this role#g

s#`AskQuestion`#the live user-question tool#g
s#AskQuestion#the live user-question tool#g
s#the `deslop` skill from the `cursor-team-kit` plugin \(`/deslop`\)#the `unslop` skill (`skill://unslop`)#g
s#Run `/deslop` from `cursor-team-kit` over the diff before commit\.#Run the `unslop` skill (`skill://unslop`) over the diff before commit.#
s#`/deslop` from the `cursor-team-kit` plugin#the `unslop` skill (`skill://unslop`)#g
s#`/deslop`#the `unslop` skill (`skill://unslop`)#g
s#`control-ui`#the live browser controls#g
s#`control-cli`#bash and PTY#g
s# from `cursor-team-kit`##g
s#^1\. Use the \*\*create-skill\*\* skill \(Cursor's built-in for authoring SKILL\.md files\)\.$#1. Write the SKILL.md with the live file tools. Give it valid YAML frontmatter, a name matching its directory, and a description that states its invocation conditions. Preserve the runtime's supported invocation metadata.#
s#the \*\*create-skill\*\* skill \(Cursor's built-in for authoring SKILL\.md files\)#the **authoring-a-skill** playbook (`skill://poteto-mode/playbooks/authoring-a-skill.md`)#g
s#Cursor's built-in `create-skill` skill#the `authoring-a-skill` playbook#g
s#Cursor's built-in `create-skill`#the `authoring-a-skill` playbook#g
s#`create-skill`'s#the `authoring-a-skill` playbook's#g
s#`create-skill`#the `authoring-a-skill` playbook#g
s#A `create-skill`-style#An `authoring-a-skill`-style#g
s#via create-skill \+ unslop#via the authoring-a-skill playbook + unslop#g
s#Drive a long or stubborn hunt with Cursor's `/loop` command\.#Drive a long or stubborn hunt to the stated predicate. Use `/loop` only when the live runtime exposes it and the operator has enabled it.#
s#Pick the wake mechanism using Cursor's `/loop` command \(a built-in, not a pstack skill\)\.#Pick a supported wake mechanism through `skill://pstack-omp`. Use `/loop` only when it is exposed and already enabled; otherwise use a root-owned watcher or an authorized external supervisor.#
s#`/loop` per component until the diff is zero\.#Repeat per component until the diff is zero using a supported root-owned wake mechanism.#
s#cloud-agent URL#the prior returned `history://<id>` or `agent://<id>` handle#g

s#`~/\.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>\.jsonl`#the current workspace's OMP session transcript, resolved from its session metadata#g
s#the active workspace's `agent-transcripts/` directory#the current workspace's session transcript directory#g
s#the workspace's `agent-transcripts/` directory#the current workspace's session transcript directory#g
s#`agent-transcripts/` directory#session transcript directory#g
s#`~/\.cursor/projects/\*/`#unrelated workspace session buckets#g
s#~/\.cursor/skills/#~/.omp/agent/skills/#g
s#\.cursor/skills/#.omp/skills/#g
s#`~/\.cursor/plugins/`#the plugin path reported by the live skill loader#g
s#misses one that lives at `\.cursor/worktrees/myrepo/x`#misses one that lives at a tool-managed path like `.worktrees/myrepo/x`#g
s#The pinned and active chats are the real artifact \(principle-prove-it-works\)\. Get that set from the user or sidebar and cross-check every candidate\. The lever has marked `safe` a worktree the user had pinned, so the pinned set wins\.#Active sessions are the real artifact (principle-prove-it-works). Cross-check the returned agent handles, this workspace's session metadata, and the user's known active chats before removing a worktree. A script's `safe` label does not override a live owner's claim.#
s#report whether the chat is pinned or ongoing and which worktrees it touches#report whether the session is active and which worktrees it touches#g
s#A pinned chat spawns arena and repro trees into sibling worktrees via background subagents, and those are in use even when their names never hit the sidebar\.#An active chat can own sibling arena and repro worktrees even when their names do not appear in returned agent metadata.#
s#then suggests a bucket\. The transcript scan is slow, so background it\.#then suggests a bucket. `hold-unpushed` means the worktree holds commits that exist nowhere else (ahead of its remote, no remote branch, or detached and not on the base, and HEAD is not the head of one of its PRs); push them or get a decision before anything else. A `LAST_CHAT` of `unavailable` means the OMP session store could not be read, so the row holds at `verify-session-unavailable`. The transcript scan is slow, so background it.#
s#`scratch:N` is untracked throwaway, safe to drop, but name the files\.#`scratch:N` is N untracked files. Name them and get a decision too, since Git refuses to remove a worktree that holds them and this playbook never forces it.#
s#Per path, `git worktree remove --force <path>`\. If the dir survives on ignored build artifacts, `rm -rf` it, then `git worktree prune`\.#Immediately before removal, re-run `git -C <path> status --porcelain=v1 --untracked-files=all` and confirm the row still qualifies, then per path `git worktree remove <path>`, never with `--force`. If Git refuses, stop and keep the worktree; never `rm -rf` it or `git worktree prune` to bypass the refusal.#

/^is_background: true$/d
/^model: [a-z0-9.-]+$/d
s#https://github.com/cursor/plugins/blob/main/pstack/#https://github.com/ubranch/pstack-omp/blob/main/plugins/pstack/#g
s#^paths: \[#globs: [#
