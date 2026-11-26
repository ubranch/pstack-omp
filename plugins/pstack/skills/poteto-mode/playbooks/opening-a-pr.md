### Opening a PR

Read `skill://pstack-omp` for dispatch and root publication ownership. Children return local branch/diff/head evidence, PR text, and requested actions. The root performs authorized pushes, PR creation and mutations after the applicable gates and reports the resulting URL. Follow the operator's existing permissions and the child's explicit worktree and write scope.

Invoked at the end of every other playbook.

Work from a git worktree off trunk, and keep unrelated work out of it. Rebase into small, landable commits. Run the `unslop` skill (`skill://unslop`) over the diff before commit.

Title: `type(scope): subject`, naming a real symbol when one carries the change. Body: a one-minute briefing under 40 lines with these `##` headings in order, dropping empty ones: `## Why`, `## What changed`, `## Scope`, `## Tradeoffs` (only rejected alternatives a reviewer would otherwise ask about), `## Blast Radius`, `## Verification`.

Stack follow-ups by base branch. Open PRs ready, through the run's PR tool with `draft: false`. Without one, use `gh pr create` without `--draft`, or `origin pr create --status open` when Origin's CLI resolves the repository. Opening a PR does not start a babysit.
