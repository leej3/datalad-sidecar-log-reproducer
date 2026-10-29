**AI-generated draft — not reviewed by John**

# Optional command previews for sidecar run records

With DataLad 1.7.2, `run --sidecar yes -m ...` produces a commit containing the user message and a sidecar identifier, but no command.
Without `-m`, only the first 40 command characters appear in the subject.
This makes ordinary Git history less useful for inspecting what was run.
Provenance is intact: `datalad -f json rerun --report HEAD` recovers the complete recorded command.

## Reproducer

A pinned Pixi container and assertions for sidecar/custom-message, sidecar/automatic-message, explicit embedded, and default storage are available at [leej3/datalad-sidecar-log-reproducer](https://github.com/leej3/datalad-sidecar-log-reproducer).
Tested on Linux ARM64 with DataLad 1.7.2.

```sh
git clone https://github.com/leej3/datalad-sidecar-log-reproducer.git
cd datalad-sidecar-log-reproducer
docker build -t datalad-sidecar-repro .
docker run --rm datalad-sidecar-repro
```

All four assertions pass with the current behavior.
The default is embedded storage, which already includes the full command in the commit body.

## Proposed behavior

Would an **opt-in, bounded command preview in the commit body** be useful for sidecar records?
It would preserve the entire user message, clearly indicate truncation, and leave the sidecar as the authoritative machine-readable record.
A preview should derive from the recorded command, preserve readable quoting, and not claim to reconstruct the original `datalad run` invocation.
Replay should replace a generated preview rather than accumulate copies.

This should preserve existing storage defaults and be separate from run-record detection:

- **[#3370](https://github.com/datalad/datalad/issues/3370) / [#3062](https://github.com/datalad/datalad/pull/3062):** Keep the user's subject space available.
  Place an optional preview outside the machine-readable block; it should neither require nor obstruct the proposed marker redesign.
- **[#3866](https://github.com/datalad/datalad/issues/3866):** A readable `rerun --report` renderer is an alternative if inspection belongs in DataLad rather than Git history.
  This reproducer may be useful evidence for that existing discussion instead of a new issue.
- **[#3558](https://github.com/datalad/datalad/issues/3558) / [#3673](https://github.com/datalad/datalad/issues/3673):** Reconstructing an editable original invocation is a broader feature than displaying the recorded command.
- **[#2576](https://github.com/datalad/datalad/issues/2576) / [#2588](https://github.com/datalad/datalad/pull/2588):** Sidecars support separate handling of potentially sensitive provenance.
  Commands can expose private paths and parameters, so a preview must not become an unconditional default.
- **[#3896](https://github.com/datalad/datalad/issues/3896):** If implemented through message templates or configuration, use the common message-handling approach rather than a separate convention.

Source: DataLad 1.7.2 [command shortening](https://github.com/datalad/datalad/blob/1.7.2/datalad/core/local/run.py#L75-L81) and [message construction](https://github.com/datalad/datalad/blob/1.7.2/datalad/core/local/run.py#L1140-L1154).
