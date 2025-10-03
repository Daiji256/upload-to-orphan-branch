# daiji256/upload-to-orphan-branch

During a GitHub Actions workflow, this action uploads selected files to a Git orphan branch (a branch with no parents). It allows you to persist small generated outputs (images, JSON, text) and reference them in Issues, PRs, or other workflows.

Companion actions are available: download at [daiji256/download-from-orphan-branch](https://github.com/Daiji256/download-from-orphan-branch) and delete at [daiji256/delete-orphan-branch](https://github.com/Daiji256/delete-orphan-branch). End-to-end usage examples are provided in [orphan-branch-upload-download-delete-examples](https://github.com/Daiji256/orphan-branch-upload-download-delete-examples).

## Why use an orphan branch

- No history; outputs stay isolated from main code history.
- Persists while the branch exists (unlike cache or ephemeral workflow artifacts).
- Easy to embed raw URLs in Issues, PRs, or README (e.g. `https://raw.githubusercontent.com/<user>/<repo>/<branch>/<path>`).
- Shared state across workflows without external storage.

## How it works

1. Resolve the file list from your `path` patterns (recursively for directories, supports exclusions).
2. Create (or switch to) a detached worktree.
3. Start a new orphan branch (`git switch --orphan`), add the files, commit (an empty commit is allowed).
4. Push (force if `overwrite: true`).

## Inputs

| Input                | Default                                               | Description                                                                  |
| -------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------- |
| branch               | -                                                     | Orphan branch to create or update.                                           |
| path                 | -                                                     | Newline-separated list of file / dir / glob patterns; prefix `!` to exclude. |
| committer-name       | github-actions[bot]                                   | Git user.name for commit.                                                    |
| committer-email      | 41898282+github-actions[bot]@users.noreply.github.com | Git user.email for commit.                                                   |
| commit-message       | (empty)                                               | Commit message (empty is allowed).                                           |
| if-no-files-found    | ignore                                                | `ignore`: allow empty commit; `error`: fail action.                          |
| overwrite            | false                                                 | `true`: force-push to replace branch; `false`: normal push.                  |
| include-hidden-files | false                                                 | `true`: include dotfiles / hidden paths.                                     |

## Notes

- Not intended for large or frequently changing binary blobs (repository size will grow).
- Force pushing (`overwrite: true`) rewrites the branch history each run.
- Having many orphan branches can bloat the repository; clean up unused branches.
- Hidden file detection: any segment starting with `.` causes exclusion unless explicitly allowed via `include-hidden-files: true`.

## Example

```yaml
jobs:
  upload:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v5

      - run: |
          mkdir -p dir
          touch dir/{foo,bar}

      - uses: daiji256/upload-to-orphan-branch@v0.1.2
        with:
          branch: outputs-branch-name
          path: |
            dir
            !**/bar
```

## License

[MIT](LICENSE) © [Daiji256](https://github.com/Daiji256)
