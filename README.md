**AI-generated draft — not reviewed by John**

# DataLad sidecar command visibility

Confirmed with DataLad **1.7.2**: when `run --sidecar yes` has a custom message, ordinary Git history contains the message and a record identifier, but no command.
Without a custom message, the command in the subject is truncated to 40 characters plus `...`.
The full command remains available through `datalad rerun --report`.

This is an inspection/readability limitation, not lost provenance.
Embedded records (the unconfigured default) already expose the command in the commit body.

## Reproduce

Requires Docker.
No host Python, Pixi, DataLad, credentials, or existing dataset is required.

```sh
git clone https://github.com/leej3/datalad-sidecar-log-reproducer.git
cd datalad-sidecar-log-reproducer
docker build -t datalad-sidecar-repro .
docker run --rm datalad-sidecar-repro
```

The image installs the committed Pixi lockfile and runs [reproduce.sh](reproduce.sh).
The script creates a temporary Git-only DataLad dataset, runs four commands, prints their commit messages and recovered commands, and removes the dataset.
[verify.py](verify.py) fails if any expected observation is absent.
A final `PASS: all four cases` means the behavior was reproduced successfully.

| Case | Ordinary Git commit message | `rerun --report` |
|---|---|---|
| Sidecar, multiline custom message | Full user message and record ID; no command | Full command |
| Sidecar, no custom message | First 40 command characters plus `...`, and record ID | Full command |
| Explicit embedded record | User message and full JSON record | Full command |
| Unconfigured default | User message and full JSON record | Full command |

The essential commands are:

```sh
datalad run --sidecar yes -m 'feat: create a result' --output result.txt \
  'printf "%s\n" "a deliberately long argument to demonstrate command visibility" > result.txt'
git log -1 --format=%B
datalad -f json rerun --report HEAD
```

`--report` inspects the recorded run; it does not execute it.
Each test writes a different output so an unchanged dataset cannot conceal a missing run commit.

## Verified result

Tested on Linux ARM64 in Docker on 2026-10-29, using Pixi 0.83.0 and DataLad 1.7.2.
Linux AMD64 is also resolved in the lockfile but has not been executed.
The base image is pinned by digest; Python, Git, DataLad, git-annex, and their dependencies are locked.
The Git-only fixture keeps initialization small; annex content handling is outside this test.

For the multiline custom-message case, `git log` prints this structure (record IDs vary):

```text
[DATALAD RUNCMD] feat: create a result

Keep this explanation intact.

=== Do not change lines below ===
"<record-id>"
^^^ Do not change lines above ^^^
```

The automatic subject is:

```text
[DATALAD RUNCMD] printf "%s\n" "a deliberately long argum...
```

Both reports recover the complete corresponding command, including the output filename.
The assertions also verify that both embedded cases contain the full command.

## Related upstream discussions

Reviewed on 2026-10-29:

- [#3370: Change run record markup](https://github.com/datalad/datalad/issues/3370) (closed) proposes recognizing runs through body markers and freeing the subject for users.
  A human-readable preview belongs in the body and should be independent of parser markup.
  Its discussion explicitly covers sidecar records and Conventional Commits.
- [#3866: Convenience command to list recorded run commits](https://github.com/datalad/datalad/issues/3866) (open) is the closest inspection/discovery discussion.
  A readable renderer for `rerun --report` could address the need without putting additional information into Git messages.
- [#3558: `rerun --print`](https://github.com/datalad/datalad/issues/3558) (open) and [#3673: record user-invoked command](https://github.com/datalad/datalad/issues/3673) (closed) concern reconstructing an editable invocation.
  A preview of the recorded command is narrower than reconstructing the original `datalad run` invocation with all its options.
- [#2576: sidecar records](https://github.com/datalad/datalad/issues/2576) (closed), implemented by [#2588](https://github.com/datalad/datalad/pull/2588), discusses keeping sensitive provenance separately and controlling its sharing.
  Automatically copying commands into Git history would undermine that use case.
  Any preview should be opt-in.
- [#3062: shorter run prefix](https://github.com/datalad/datalad/pull/3062) (closed) provides the subject-space background for #3370.
  [#3896: consolidate message specification](https://github.com/datalad/datalad/issues/3896) (open) is relevant if adding message templating or configuration.

Searches included `sidecar`, `sidecar message`, `sidecar preview`, and `command "commit message"` across issues and pull requests.
No exact existing opt-in sidecar-preview request was identified; this is not an exhaustive absence claim.
[ISSUE.md](ISSUE.md) is an unposted proposal intended to fit these discussions.

The release source explicitly [truncates at 40 characters](https://github.com/datalad/datalad/blob/1.7.2/datalad/core/local/run.py#L75-L81) and [chooses a custom message or shortened command, followed by either a sidecar ID or embedded record](https://github.com/datalad/datalad/blob/1.7.2/datalad/core/local/run.py#L1140-L1154).
