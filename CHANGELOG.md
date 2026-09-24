# Changelog

All notable changes to Linux Backup Manager are documented here.

## 1.0.1 — 2026-09-24

### Fixed

- Corrected TUI detection when `dialog` menu output is captured internally.
- Interactive detection now uses terminal `stdin` / `stderr` rather than captured `stdout`, preventing an incorrect fallback to the plain numeric `Select:` menu in normal terminals.

### Included

- Colored terminal dashboard
- `dialog` TUI and CLI operation
- rsync incremental snapshots
- Restic repositories
- tar+zstd archives
- verification
- restore
- retention
- systemd timer scheduling
- DR inventory
- MySQL/MariaDB, PostgreSQL, and Docker metadata capture
- history, storage reporting, and Doctor diagnostics

## 1.0.0 — 2026-09-24

- Initial public implementation.

---

Designed & Developed by **antonios.mortos@outlook.com**