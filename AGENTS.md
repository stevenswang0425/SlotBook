# SlotBook — agent / contributor rules

## Branch protection (mandatory)

**Never commit or push directly to `main` (or `master`).**

Always:

1. Work on a feature branch (e.g. `develop` or `feature/...`).
2. Commit and push that branch.
3. Merge into `main` via **pull request** only.

Local enforcement: `.githooks/` (`pre-commit`, `pre-push`).  
After clone: `./scripts/install-git-hooks.sh`

GitHub: branch protection on `main` should require PRs when available.

## Preferred workflow

```bash
git checkout -b feature/short-description
# ... work ...
git add -A && git commit -m "..."
git push -u origin HEAD
gh pr create --base main
gh pr merge
```
