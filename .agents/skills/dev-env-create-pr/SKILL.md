---
name: dev-env-create-pr
description: Use when preparing, creating, updating, replacing, or splitting a GitHub Pull Request for dev-env, including Docker, Compose, Dev Container, JetBrains, shell, networking, persistence, and documentation changes.
---

# Create a dev-env Pull Request

This is the project delivery workflow for `dev-env`. It binds PR scope, validation, Issue relations, and remote-write safety to this repository's container environment, client integration, configuration, and documentation contracts.

## Operating Modes

| User wording                             | Mode          | Default remote behavior                                 |
| ---------------------------------------- | ------------- | ------------------------------------------------------- |
| “准备 PR”“整理 PR”“draft”                | `preflight`   | local inspection and draft only                         |
| “创建/提交 PR”                           | `create`      | draft first; confirm each remote write separately       |
| “更新 PR”“修标题/描述”                   | `update`      | read existing PR; confirm the requested edit            |
| “替代旧 PR”                              | `replacement` | preserve old facts and revalidate current HEAD          |
| independent behaviors or staged delivery | `split`       | keep PRs reviewable and use non-closing Issue relations |

Ambiguous wording defaults to `preflight`. Reviewing a draft never authorizes push, Issue creation, PR creation, labels, reviewers, or milestones.

## 1. Determine Scope

Read before drafting:

- `docs/developer/git-contribution.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/ISSUE_TEMPLATE/discussion.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/workflows/pr-title-lint.yml`

Record branch, target base, HEAD, commits, changed paths, Issue/PR references, and unrelated dirty-worktree changes. Do not include unrelated changes in PR scope.

Classify affected areas using the project template: Docker image or Compose services; Dev Container or JetBrains integration; shell, mise, or chezmoi configuration; Tailscale, networking, or container persistence; documentation.

For cross-layer changes, trace:

```text
Compose -> devbox entrypoint -> Docker Engine -> client/workspace integration
```

## 2. Issue Relation

Search for an existing Issue before proposing a duplicate. Every PR title must include at least one real Issue using `--issue=#N`; do not invent Issue numbers. Use `closes`, `fixes`, or `resolves` only when the PR completes the Issue; use `refs` or `related to` for staged work. Never invent impact, acceptance, environment, or credential facts.

## 3. Verification Matrix

| Changed paths                      | Required validation                                              |
| ---------------------------------- | ---------------------------------------------------------------- |
| `Dockerfile`                       | `docker compose config --quiet`; `docker compose build`          |
| `docker-compose.yml` or entrypoint | above plus Docker smoke checks                                   |
| `.devcontainer/**`                 | Compose validation plus client/config verification               |
| `config/**`                        | relevant shell/tool verification                                 |
| `docs/**`                          | links, commands, paths, and config examples match implementation |
| `.github/**`                       | YAML/Markdown structure and project fields                       |

Only check commands that ran on the current HEAD. Record unavailable checks exactly.

## 4. Draft The PR

Start from `.github/PULL_REQUEST_TEMPLATE.md` and fill its five sections. Use an English action-oriented title in `<type>: <subject> --issue=#N` form. For multiple Issues use `--issue=#12, #34`; validate against `.github/workflows/pr-title-lint.yml`. Do not copy Issue form prefixes into the PR title.

## 5. Remote Writes

Create temporary Git worktrees inside the current repository at `.worktree/`; do not create worktree directories alongside the repository or under the shared workspace root. Keep `.worktree/` ignored and use a dedicated branch for each PR.

Authorize separately: branch push; Issue create/edit; PR create/edit; labels, reviewers, assignees, and milestones. Use explicit repository, base, head, and body-file arguments with `gh`. Read resources back after writes; after an ambiguous failure, query state before retrying.

For `preflight`, finish with `No GitHub writes performed` and list pending actions. Delivery reports must include mode, scope/base/head, title, Issue relation, affected areas, actual checks, unverified checks, risks/rollback, and remote actions.
