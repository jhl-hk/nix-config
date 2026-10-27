# Upstream provenance

Vendored, not tracked as a flake input.

| | |
|---|---|
| Source | https://github.com/pbakaus/impeccable — `plugin/skills/impeccable/` |
| Commit | `d34c87e1a00989ae8dbdd7f6b30b70f23319e860` |
| Version | 4.8.0 |
| License | Apache-2.0 (© Paul Bakaus) |

## Why vendored

The repo's HEAD tree is 86 MiB across 4422 files. The skill is 2.2 MiB.

## Notes

- `scripts/impeccable` downloads its engine binary into `~/.impeccable/bin/<version>/` on first run, verified against `scripts/engine-checksums.txt`.
- Hooks are per project: `/impeccable hooks on` writes `.claude/settings.local.json`, `.codex/hooks.json`, etc.

## Local changes

None. `UPSTREAM.md` is the only added file.

## Updating

```sh
git clone --depth 1 --filter=blob:none --sparse https://github.com/pbakaus/impeccable.git .temp/impeccable
git -C .temp/impeccable sparse-checkout set plugin/skills/impeccable
rsync -a --delete --exclude UPSTREAM.md .temp/impeccable/plugin/skills/impeccable/ claude/skills/impeccable/
```

Then update the commit and version above.
