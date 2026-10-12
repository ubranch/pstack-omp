#!/usr/bin/env bash
# Read-only worktree prune audit. Classifies every git worktree by size, merge
# state, uncommitted work, remote/PR state, and the most recent chat that
# operated in it. Emits a table sorted by size with a suggested bucket. Never
# deletes anything; deletion stays a human-gated step in the playbook.
#
# Usage: worktree-audit.sh [-b|--base <ref>] [repo-path]
#   repo-path defaults to the current repo.
#   -b sets the ref the MERGED column checks against (e.g. origin/integration).
#   Without it the base is origin/HEAD, then origin/main, then origin/master.
#   origin/HEAD is the remote's default branch, not necessarily the branch PRs
#   merge into; pass -b when they differ.
set -u
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

base=""
while [ $# -gt 0 ]; do
	case "$1" in
	-b|--base) [ $# -ge 2 ] || { echo "error: $1 needs a ref" >&2; exit 2; }; base="$2"; shift 2 ;;
	-h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	-*) echo "error: unknown option: $1" >&2; exit 2 ;;
	*) break ;;
	esac
done

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "not in a git repo; pass a repo path" >&2; exit 1; }
cd "$repo" || exit 1
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: not a git repo: $repo" >&2; exit 1; }

# Main worktree is the first entry; everything else is a candidate.
worktree_paths=$(mktemp) || exit 1
if ! git worktree list --porcelain -z >"$worktree_paths" 2>/dev/null; then
	rm -f "$worktree_paths"
	echo "error: worktree discovery unavailable" >&2
	exit 1
fi
owned_worktrees=$(
	while IFS= read -r -d '' entry; do
		case "$entry" in
			"worktree "*) wt=${entry#worktree }
				case "$wt" in ""|*[[:cntrl:]]*) exit 1 ;; esac
				printf '%s\n' "$wt" ;;
		esac
	done <"$worktree_paths"
) || { rm -f "$worktree_paths"; echo "error: unsupported worktree path" >&2; exit 1; }
locked_worktrees=$(
	while IFS= read -r -d '' entry; do
		case "$entry" in
			"worktree "*) wt=${entry#worktree } ;;
			locked|"locked "*) printf '%s\n' "$wt" ;;
		esac
	done <"$worktree_paths"
)
rm -f "$worktree_paths"
[ -n "$owned_worktrees" ] || { echo "error: worktree discovery unavailable" >&2; exit 1; }
main_wt=${owned_worktrees%%$'\n'*}

if [ -z "$base" ]; then
	for cand in "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" origin/main origin/master; do
		[ -n "$cand" ] && git rev-parse --verify --quiet "$cand^{commit}" >/dev/null && { base="$cand"; break; }
	done
	[ -z "$base" ] && { echo "error: no base ref (origin/HEAD, origin/main, origin/master all missing); pass -b <ref>" >&2; exit 1; }
	echo "warn: no -b given; MERGED checks against $base" >&2
fi

# The base drives the merge check. The fetch is best-effort (stale is fine for
# a first pass) and runs before the check, since -b may name a branch not
# fetched yet. The explicit refspec creates it even in a single-branch clone.
case "$base" in
origin/*) git fetch origin "+refs/heads/${base#origin/}:refs/remotes/$base" --quiet 2>/dev/null \
	|| echo "warn: could not fetch $base; merged column may be stale" >&2 ;;
esac
git rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 || { echo "error: base ref not found: $base" >&2; exit 1; }

# PR state by branch, fetched once. Empty if gh is unavailable.
prs=$(mktemp)
gh pr list --author "@me" --state all --limit 1000 \
	--json number,state,headRefName 2>/dev/null > "$prs" || echo "[]" > "$prs"

sessions="${PI_CODING_AGENT_SESSION_DIR:-}"
session_files=$(mktemp) || exit 1
session_paths=$(mktemp) || { rm -f "$prs" "$session_files"; exit 1; }
runner=()
if command -v node >/dev/null 2>&1; then runner=(node)
elif command -v bun >/dev/null 2>&1; then runner=(bun run --no-env-file); fi
worktrees=()
while IFS= read -r wt; do worktrees+=("$wt"); done <<<"$owned_worktrees"
session_status=available
if [ -n "$sessions" ]; then
	case "$sessions" in *[[:cntrl:]]*) session_status=unavailable ;; -*) sessions="./$sessions" ;; esac
	[ "$session_status" = available ] && [ -d "$sessions" ] &&
		find -H "$sessions" -type f -name '*.jsonl' -print0 >"$session_paths" 2>/dev/null || session_status=unavailable
else
	if [ "${#runner[@]}" -gt 0 ] && session_dirs=$("${runner[@]}" "$script_dir/worktree-session-dirs.mjs" 2>/dev/null); then
		if [ -n "$session_dirs" ]; then
			while IFS= read -r directory; do
				find -H "$directory" -type f -name '*.jsonl' -print0 >>"$session_paths" 2>/dev/null || { session_status=unavailable; break; }
			done <<<"$session_dirs"
		fi
	else
		session_status=unavailable
	fi
fi
if [ "$session_status" = available ]; then
	while IFS= read -r -d '' f; do
		case "$f" in *[[:cntrl:]]*) session_status=unavailable; break ;; esac
		cwd=$(set -o pipefail; head -n 2 "$f" |
			jq -ers 'map(select(.type == "session")) | first | .cwd | select(type == "string" and length > 0 and (test("[[:cntrl:]]") | not))') 2>/dev/null || { session_status=unavailable; break; }
		printf '%s\n' "$owned_worktrees" | grep -qxF -- "$cwd"
		case $? in
			0) ;;
			1)
				if [ "${#runner[@]}" -eq 0 ] || ! cwd=$("${runner[@]}" "$script_dir/worktree-session-dirs.mjs" --owner "$cwd" "${worktrees[@]}" 2>/dev/null); then
					session_status=unavailable; break
				fi
				[ -n "$cwd" ] || continue ;;
			*) session_status=unavailable; break ;;
		esac
		mtime=$(stat -c '%Y' "$f" 2>/dev/null || stat -f '%m' "$f" 2>/dev/null) || { session_status=unavailable; break; }
		printf '%s\t%s\t%s\n' "$cwd" "$f" "$mtime" >>"$session_files" || { session_status=unavailable; break; }
	done <"$session_paths" || session_status=unavailable
fi
[ "$session_status" = available ] || echo "warn: session enrichment unavailable; check OMP lookup, session access, and runtime prerequisites" >&2
now=$(date +%s)

echo "# base: $base"
printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tLAST_CHAT\tBUCKET\tWORKTREE\n"

printf '%s\n' "$owned_worktrees" | while IFS= read -r wt; do
	[ "$wt" = "$main_wt" ] && continue

	size=$(du -sh "$wt" 2>/dev/null | awk '{print $1}')
	head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
	head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
	age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

	# Squash-merged branches are not ancestors of the base, so PR state is the
	# real signal; merge-base only catches fast-forward/rebase merges.
	git merge-base --is-ancestor "$head" "$base" 2>/dev/null && merged=YES || merged=no

	# Distinguish real WIP (tracked edits) from disposable untracked scratch.
	if ! porcelain=$(git -C "$wt" status --porcelain 2>/dev/null); then dirty=error
	elif [ -z "$porcelain" ]; then dirty=clean
	elif printf '%s\n' "$porcelain" | grep -qv '^??'; then
		dirty="wip:$(printf '%s\n' "$porcelain" | grep -cv '^??')"
	else dirty="scratch:$(printf '%s\n' "$porcelain" | grep -c '^??')"; fi

	branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
	if [ -z "$branch" ]; then remote=detached
	elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
		[ "$(git -C "$wt" rev-parse "origin/$branch" 2>/dev/null)" = "$head" ] \
			&& remote=pushed \
			|| remote="ahead$(git -C "$wt" rev-list --count "origin/$branch..HEAD" 2>/dev/null)"
	else remote=no-remote; fi

	pr=$([ -n "$branch" ] && jq -r --arg b "$branch" \
		'.[] | select(.headRefName==$b) | "#\(.number)/\(.state)"' "$prs" 2>/dev/null | head -1)
	[ -z "$pr" ] && pr="-"

	# Match a path separator or closing quote, not a sibling's shared prefix.
	chat_paths=(-e "${wt}/" -e "${wt}\"")
	case "$wt" in [[:alpha:]]:/*)
		windows_wt=${wt//\//\\\\}
		chat_paths+=(-i -e "${windows_wt}\\\\" -e "${windows_wt}\"") ;;
	esac
	last="-"; last_ts=0
	chat_status=$session_status
	if [ "$chat_status" = available ]; then
		while IFS=$'\t' read -r cwd f mtime; do
			if [ "$cwd" != "$wt" ]; then
				[ "$cwd" = "$main_wt" ] || continue
				rg -F "${chat_paths[@]}" "$f" >/dev/null 2>&1
				case $? in
					0) ;;
					1) continue ;;
					*) chat_status=unavailable; break ;;
				esac
			fi
			if [ "$mtime" -gt "$last_ts" ]; then last_ts="$mtime"; fi
		done <"$session_files" || chat_status=unavailable
	fi
	if [ "$chat_status" != available ]; then
		last=unavailable
	elif [ "$last_ts" -gt 0 ]; then
		last=$(date -d @"$last_ts" '+%Y-%m-%d' 2>/dev/null || date -r "$last_ts" '+%Y-%m-%d' 2>/dev/null) || { chat_status=unavailable; last=unavailable; }
	fi
	recent=$([ "$last_ts" -gt 0 ] 2>/dev/null && [ $(( (now - last_ts) / 86400 )) -le 4 ] && echo yes || echo no)

	if [ "$dirty" = error ]; then bucket=hold-error
	elif printf '%s\n' "$locked_worktrees" | grep -qxF -- "$wt"; then bucket=hold-locked
	else
		case "$dirty" in wip:*) bucket=hold-wip ;; *)
			case "$pr" in *OPEN*) bucket=hold-open-pr ;; *)
				if [ "$chat_status" != available ]; then bucket=verify-session-unavailable
				elif [ "$recent" = yes ]; then bucket=verify-recent-chat
				elif [ "$merged" = YES ] || [ "$pr" != "-" ]; then bucket=safe
				else bucket=review; fi ;;
			esac ;;
		esac
	fi

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		"$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$last" "$bucket" "$wt"
done | sort -t$'\t' -k1,1 -rh

rm -f "$prs" "$session_files" "$session_paths"
