### Autopilot-stack

Read `skill://pstack-omp` for dispatch and lifecycle. The root starts participants, accepts evidence, and performs authorized external writes and merges after the applicable operator, CI, and independent-review gates. A bounded worker prepares local branch/diff/head evidence and returns dispatch and PR-action requests instead of starting children or publishing. Use explicit private worktrees when writers overlap. Keep the operator's model configuration and approval policy unchanged.

Run the Autopilot-full playbook, but do not merge.

1. **In place of step 5, stop at verified.** Stop when each PR is verified and green at its current head, then hand the PRs to the operator. After the handoff, the root publishes nothing without the operator's go. Every audit tick reads this file from its installed URI, so each tick sees the no-merge rule.
2. **Stack a PR only when it builds on another PR.** This is the one exception to step 3. Base the PR on the other PR's branch in place of trunk, per **Size and stacks** in `playbooks/opening-a-pr.md`. In place of step 2's rebase onto trunk, each PR rebases onto its parent PR's branch, and the stack root rebases onto trunk. A new head on the lower PR restacks the PRs above it, and a PR whose `git patch-id` the restack leaves unchanged keeps its verdict.

**Reply:** list each PR with its verdict, in place of what merged.
