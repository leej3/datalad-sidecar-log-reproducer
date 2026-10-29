"""Fail unless Git messages and DataLad reports demonstrate all four cases."""
import json
from pathlib import Path
import sys

root = Path(sys.argv[1])
for case in ("custom", "automatic", "embedded", "default"):
    message = (root / f"{case}.message").read_text()
    reports = [json.loads(line) for line in (root / f"{case}.report").read_text().splitlines()]
    records = [r["run_info"] for r in reports if "run_info" in r]
    assert len(records) == 1, reports
    command = records[0]["cmd"]
    expected = 'printf "%s\\n" "a deliberately long argument to demonstrate command visibility" > '
    expected += case + ".txt"
    assert command == expected, (command, expected)
    payload = message.split("=== Do not change lines below ===\n", 1)[1].split("\n^^^ Do not change lines above ^^^", 1)[0]
    record = json.loads(payload)
    if case in ("custom", "automatic"):
        assert isinstance(record, str), record
        assert "deliberately long argument" not in message, message
        if case == "custom":
            assert message.startswith("[DATALAD RUNCMD] feat: create a result\n\nKeep this explanation intact.\n"), message
        else:
            assert message.splitlines()[0] == "[DATALAD RUNCMD] " + command[:40] + "...", message
    else:
        assert record["cmd"] == command, record
    print(f"\nPASS: {case}")
    # Show only DataLad's message; any external test-harness trailers are irrelevant.
    print(message.split("^^^ Do not change lines above ^^^", 1)[0] + "^^^ Do not change lines above ^^^")
    print("Recovered by datalad rerun --report:", command)
print("\nPASS: all four cases; sidecar provenance remains recoverable.")
