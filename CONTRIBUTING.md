# Contributing to OWRT Doctor

Contributions are welcome.

## Design rules

1. **Read-only by default.** Diagnostic checks must not change router configuration.
2. **No telemetry.** Do not add automatic uploads or tracking.
3. **Protect secrets.** New bundle collectors must pass through the sanitizer.
4. **BusyBox first.** Prefer POSIX shell and tools commonly available on OpenWrt.
5. **Small dependencies.** New runtime dependencies require strong justification.
6. **Explain failures.** Checks should return useful human-readable detail.

## Check plugin contract

Files under `/usr/lib/owrt-doctor/checks.d/` are executed with `sh` in lexical order.

Each output line must use:

```text
STATUS|CHECK_ID|TITLE|DETAIL
```

`STATUS` must be one of `PASS`, `WARN`, `FAIL`, or `SKIP`.

## Pull requests

Include:

- what problem is solved,
- router/OpenWrt version tested,
- whether bundle collection changes,
- tests or reproducible verification steps.

For redaction, command execution, or support-data changes, explain the threat model.
