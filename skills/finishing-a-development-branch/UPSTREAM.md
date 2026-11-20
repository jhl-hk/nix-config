# Upstream

| | |
|---|---|
| Source | https://github.com/obra/superpowers — `skills/finishing-a-development-branch/` |
| Commit | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (v6.3.0) |
| License | MIT |

## Local changes

- "Announce at start" line removed.
- Test commands reordered for this stack (`bun test` first, `swift test` added).
- "Superpowers created this worktree" → "the using-git-worktrees skill created this worktree".
- Rationalizations table removed; its two facts not stated elsewhere moved into the steps (test the tree you integrate; force-push only on explicit request; leave stale-looking host worktrees alone).
- Step 2: submodule guard (`git rev-parse --show-superproject-working-tree`, from using-git-worktrees) so a submodule no longer reads as a linked worktree; the menu table, the `MAIN_ROOT` steps and Step 6 treat a submodule as a normal repo.
- Step 6: a worktree in the user-declared worktree directory (using-git-worktrees directory selection item 1) is cleaned up like `.worktrees/`/`worktrees/`.
- Step 4: the "present the menu exactly as written" paragraph that restated the headings cut to the discard rule and the wait.
- Description: integration choices named; boundary with using-git-worktrees added.
