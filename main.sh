#!/bin/bash
set -euo pipefail

if [[ "$IF_NO_FILES_FOUND" != "ignore" && "$IF_NO_FILES_FOUND" != "error" ]]; then
  echo "Invalid value for IF_NO_FILES_FOUND: $IF_NO_FILES_FOUND" >&2
  exit 1
fi
if [[ "$OVERWRITE" != "true" && "$OVERWRITE" != "false" ]]; then
  echo "Invalid value for OVERWRITE: $OVERWRITE" >&2
  exit 1
fi
if [[ "$INCLUDE_HIDDEN_FILES" != "true" && "$INCLUDE_HIDDEN_FILES" != "false" ]]; then
  echo "Invalid value for INCLUDE_HIDDEN_FILES: $INCLUDE_HIDDEN_FILES" >&2
  exit 1
fi

is_hidden_file() {
  IFS="/" read -ra parts <<< "$1"
  for part in "${parts[@]}"; do
    if [[ "$part" == "." || "$part" == ".." ]]; then
      continue
    fi
    if [[ "$part" == .* ]]; then
      return 0
    fi
  done
  return 1
}

shopt -s globstar
declare -A files=()
for file_path in $FILES_PATH; do
  if [[ "${file_path:0:1}" == "!" ]]; then
    while IFS= read -r -d "" file; do
      unset "files[$file]"
    done < <(find "${file_path:1}" -type f -print0)
  else
    while IFS= read -r -d "" file; do
      if [[ "$INCLUDE_HIDDEN_FILES" == "false" ]] && is_hidden_file "$file"; then
        continue
      fi
      files["$file"]=1
    done < <(find "$file_path" -type f -print0)
  fi
done

if [[ "$IF_NO_FILES_FOUND" = "error" && ${#files[@]} -eq 0 ]]; then
  echo "No files found" >&2
  exit 1
fi

git worktree remove -f .upload_orphan_worktree || true
git worktree add --detach .upload_orphan_worktree

(
  cd .upload_orphan_worktree
  git switch --orphan "$BRANCH"
  git reset --hard

  for file in "${!files[@]}"; do
    dir="$(dirname "$file")"
    mkdir -p "$dir"
    cp "../$file" "$dir"
    git add "$file"
  done

  git -c "user.name=$COMMITTER_NAME" -c "user.email=$COMMITTER_EMAIL" \
    commit --allow-empty --allow-empty-message -m "$COMMIT_MESSAGE"
  if [[ "$OVERWRITE" == "true" ]]; then
    git push -f origin "HEAD:$BRANCH"
  else
    git push origin "HEAD:$BRANCH"
  fi
)

git worktree remove -f .upload_orphan_worktree
