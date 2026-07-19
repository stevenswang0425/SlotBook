# Branch protection: no direct commits/pushes to `main`

## What is enforced

| Layer | Blocks |
|--------|--------|
| **Local `pre-commit`** | Committing while checked out on `main` / `master` |
| **Local `pre-push`** | Pushing updates to remote `main` / `master` |
| **AGENTS.md** | AI agents instructed never to commit/push to main |
| **GitHub branch protection** | Server-side PR requirement (when enabled) |

## Install hooks (each clone)

```bash
./scripts/install-git-hooks.sh
```

This sets:

```bash
git config core.hooksPath .githooks
```

## Emergency bypass (avoid)

```bash
git commit --no-verify
git push --no-verify
```

## Correct flow

```bash
git checkout -b feature/my-change
git commit -m "..."
git push -u origin HEAD
gh pr create --base main
gh pr merge
```
