#!/bin/sh
set -eu
checker=$(pwd)/verify.py
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export GIT_AUTHOR_NAME='Reproducer'
export GIT_AUTHOR_EMAIL='reproducer@example.invalid'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
# An ordinary Git dataset suffices: the behavior concerns run records.
datalad create --no-annex "$work/dataset"
cd "$work/dataset"
datalad --version

# With a custom message, the sidecar record leaves no command in git log.
datalad run --sidecar yes -m 'feat: create a result

Keep this explanation intact.' --output custom.txt \
  'printf "%s\n" "a deliberately long argument to demonstrate command visibility" > custom.txt'
git log -1 --format=%B > "$work/custom.message"
datalad -f json rerun --report HEAD > "$work/custom.report"

# Without a message, DataLad uses a shortened command as the subject.
datalad run --sidecar yes --output automatic.txt \
  'printf "%s\n" "a deliberately long argument to demonstrate command visibility" > automatic.txt'
git log -1 --format=%B > "$work/automatic.message"
datalad -f json rerun --report HEAD > "$work/automatic.report"

# Explicit embedded records retain the full command in the commit body.
datalad run --sidecar no -m 'feat: create an embedded result' --output embedded.txt \
  'printf "%s\n" "a deliberately long argument to demonstrate command visibility" > embedded.txt'
git log -1 --format=%B > "$work/embedded.message"
datalad -f json rerun --report HEAD > "$work/embedded.report"

# The unconfigured default also embeds the record.
datalad run -m 'feat: check the default storage' --output default.txt \
  'printf "%s\n" "a deliberately long argument to demonstrate command visibility" > default.txt'
git log -1 --format=%B > "$work/default.message"
datalad -f json rerun --report HEAD > "$work/default.report"
python "$checker" "$work"
