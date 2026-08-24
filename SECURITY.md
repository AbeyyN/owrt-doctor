# Security Policy

OWRT Doctor runs on network infrastructure and may inspect diagnostic data.

## Reporting

Do not open a public issue for a vulnerability that could expose credentials, private keys, authentication tokens, or sensitive router configuration.

Use GitHub private vulnerability reporting when available.

Include the affected version, exact component, a proof of concept using dummy credentials, expected/actual behavior, and a suggested mitigation if known.

## Principles

- No automatic network uploads.
- No destructive remediation in the core scanner.
- Secret-bearing fields are redacted.
- Support bundles are created locally.
- Collected commands should be read-only.
