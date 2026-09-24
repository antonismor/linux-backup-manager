# Security Policy

Linux Backup Manager performs privileged backup and restore operations. Security issues should therefore be treated seriously.

## Reporting a vulnerability

Please avoid publishing exploit details in a public GitHub issue before a fix is available.

Contact:

**antonios.mortos@outlook.com**

Include, where possible:

- affected LBM version
- Linux distribution and version
- backup engine
- minimal reproduction steps
- security impact
- relevant logs with credentials and private data removed

## Administrator security guidance

- Restrict `/etc/linux-backup-manager/secrets/` to root.
- Never commit production passwords, API keys, private keys, or Restic passwords.
- Review `PRE_HOOK` and `POST_HOOK` as privileged code.
- Prefer dedicated credentials for remote backup storage.
- Isolate or immutably protect at least one recovery copy from the production host.
- Encrypt off-host repositories where appropriate.
- Test recovery procedures on a schedule.

Designed & Developed by **antonios.mortos@outlook.com**