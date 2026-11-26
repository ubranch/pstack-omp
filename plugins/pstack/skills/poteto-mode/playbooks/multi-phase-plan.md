### Multi-phase or multi-PR plan

Read `skill://pstack-omp` for dispatch and lifecycle. The root starts participants, accepts evidence, and performs authorized external writes and merges after the applicable operator, CI, and independent-review gates. A bounded worker prepares local branch/diff/head evidence and returns dispatch and PR-action requests instead of starting children or publishing. Use explicit private worktrees when writers overlap. Keep the operator's model configuration and approval policy unchanged.

**You own the plan, not the code. The plan is a checklist an owner runs box by box and the operator audits from the evidence.** The plan is the deliverable. Do not implement.

1. When the change is one or two files with an obvious approach, skip the plan. Say so and stop.
2. Settle open questions by prototype before you write, per `playbooks/prototype.md`. Ask the operator only about a product or preference call that no run can settle.
3. Write the plan file. Open with what changes, the PR ids in landing order, and the dependency graph, which says which PRs are independent and branch from trunk, which wait for which, and the files each may touch. Then one section per PR. One PR is one change with its own evidence (the **sequence-verifiable-units** principle skill). Each section has checkboxes for what it depends on, the files it edits, the one change it builds, the result you see, and its verification.
4. Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked. Each live box drives the real surface with a concrete scenario and a pass predicate. The perf box names the metric, the probe, the trunk baseline measured first, and the number that fails. A PR that changes an interaction waits for the operator's review before merge.
5. Hand back the plan path and stop. Execution starts on the operator's explicit go.

**Reply:** the plan path, the PR ids with their dependencies and the review-gated set, and what stays unproven.
