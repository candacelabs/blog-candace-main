#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_ROOT="$(git rev-parse --show-toplevel)"
readonly REPOSITORY_ROOT
cd "${REPOSITORY_ROOT}"

failures=0
audited=0

while IFS= read -r -d '' path; do
  [[ -f "${path}" && ! -L "${path}" && -s "${path}" ]] || continue

  lower_path="${path,,}"
  encoding="$(file --brief --mime-encoding -- "${path}")" || {
    echo "Could not inspect asset encoding: ${path}" >&2
    failures=$((failures + 1))
    continue
  }
  requires_lfs="false"
  case "${lower_path}" in
    *.7z | *.aac | *.avif | *.bin | *.bmp | *.br | *.bz2 | \
      *.eot | *.flac | *.gif | *.gz | *.ico | *.jpeg | *.jpg | \
      *.m4a | *.mov | *.mp3 | *.mp4 | *.oga | *.ogg | *.ogv | \
      *.otf | *.pdf | *.png | *.psd | *.tar | *.tgz | *.tif | \
      *.tiff | *.ttc | *.ttf | *.wasm | *.wav | *.webm | *.webp | \
      *.woff | *.woff2 | *.xz | *.zip)
      requires_lfs="true"
      ;;
  esac
  if [[ "${encoding}" == "binary" ]]; then
    requires_lfs="true"
  fi
  [[ "${requires_lfs}" == "true" ]] || continue

  audited=$((audited + 1))
  filter="$(
    git check-attr filter -- "${path}" |
      sed 's/^.*: filter: //'
  )"
  if [[ "${filter}" != "lfs" ]]; then
    echo "Binary asset is not assigned to Git LFS: ${path}" >&2
    failures=$((failures + 1))
    continue
  fi

  if ! git cat-file blob ":${path}" |
    git lfs pointer --check --strict --stdin; then
    echo "Git index does not contain an LFS pointer: ${path}" >&2
    failures=$((failures + 1))
    continue
  fi
  if git lfs pointer --check --strict --file="${path}" >/dev/null 2>&1; then
    echo "Git LFS asset is not hydrated in the working tree: ${path}" >&2
    failures=$((failures + 1))
    continue
  fi

  printf 'LFS asset: %s\n' "${path}"
done < <(git ls-files -z)

if ((audited == 0)); then
  echo "No binary assets were found." >&2
  exit 1
fi
if ((failures != 0)); then
  echo "${failures} Git LFS asset check(s) failed." >&2
  exit 1
fi

git lfs fsck
printf 'Verified %d Git LFS asset(s).\n' "${audited}"
