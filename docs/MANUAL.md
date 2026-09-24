# Linux Backup Manager 1.0.1 — Administrator Manual

Designed & Developed by **antonios.mortos@outlook.com**

## 1. Introduction

Linux Backup Manager (LBM) is a terminal-based backup administration toolkit for Linux. It is designed to provide one consistent workflow for creating backup profiles, running and verifying backups, browsing recovery points, restoring data, applying retention policies, scheduling unattended jobs, and recording disaster-recovery metadata.

LBM has two interfaces:

1. **Interactive TUI** — launch `sudo lbm`; use arrow keys and ENTER.
2. **Command-line interface** — use commands such as `sudo lbm run web01` from shells, scripts, or `systemd`.

Version `1.0.1` supports three backup engines: `rsync`, Restic, and `tar + zstd`.

---

## 2. Requirements

LBM is intended for a modern Linux distribution using Bash and systemd.

Core utilities used by the application include:

- Bash
- `dialog` for the full interactive TUI
- `flock` for profile locking
- `systemctl` for scheduling
- `ip`, `ss`, and `findmnt` for inventory/diagnostics

Engine-specific dependencies:

- `rsync` for rsync profiles
- `restic` for Restic profiles
- `tar` and `zstd` for compressed archive profiles

Application-aware capture may additionally require:

- `mysqldump` for MySQL/MariaDB
- `pg_dumpall` for PostgreSQL
- `docker` for Docker inventory

### Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y dialog rsync zstd restic
```

Database or Docker packages should be installed only when those capture modes are required.

---

## 3. Installation

Clone the repository:

```bash
git clone https://github.com/antonismor/linux-backup-manager.git
cd linux-backup-manager
```

Install:

```bash
sudo ./install.sh
```

The main executable is installed as:

```text
/usr/local/bin/lbm
```

Verify:

```bash
lbm version
```

Expected result:

```text
Linux Backup Manager 1.0.1
```

Start the interactive manager:

```bash
sudo lbm
```

---

## 4. TUI behavior

When `dialog` is installed and LBM is running in an interactive terminal, the full TUI is used. Navigate with:

- `↑` / `↓` — move between options
- `ENTER` — select
- `TAB` — move between dialog buttons where applicable
- `ESC` — cancel/back in many dialogs

If `dialog` is unavailable or the session is not interactive, LBM can fall back to a simple numeric menu.

### Verifying terminal support

```bash
command -v dialog
printf 'TERM=%s\n' "$TERM"
tty
test -t 0 && echo 'STDIN TTY OK'
test -t 2 && echo 'STDERR TTY OK'
```

Version 1.0.1 specifically fixes a TUI-detection problem present in 1.0.0.

---

## 5. Directory layout

LBM keeps configuration, secrets, state, and logs separate.

```text
/etc/linux-backup-manager/
├── profiles/
└── secrets/

/var/lib/linux-backup-manager/
└── history/

/var/log/linux-backup-manager/
/var/cache/linux-backup-manager/
/run/lock/linux-backup-manager/
```

Default meanings:

- `/etc/linux-backup-manager/profiles/` — backup profile configuration files
- `/etc/linux-backup-manager/secrets/` — sensitive Restic password files
- `/var/lib/linux-backup-manager/history/` — execution history
- `/var/log/linux-backup-manager/lbm.log` — application log
- `/var/cache/linux-backup-manager/` — temporary staging data
- `/run/lock/linux-backup-manager/` — per-profile runtime locks

The location variables can be overridden with supported `LBM_*` environment variables for testing or specialized deployments.

---

## 6. Creating a profile

Launch the wizard:

```bash
sudo lbm create
```

or choose **Create Backup Profile** from the TUI.

The wizard asks for:

1. profile name
2. source path
3. backup engine
4. destination/repository
5. optional application-aware capture
6. retention values
7. systemd schedule
8. automatic verification preference
9. SHA-256 manifest preference where supported

### Profile names

Use letters, numbers, dots, dashes, and underscores. Example:

```text
webserver01
```

### Example profile file

```text
NAME=webserver01
SOURCE=/var/www
ENGINE=rsync
TARGET=/backup/webserver01
APP_TYPE=none
KEEP_DAILY=14
KEEP_WEEKLY=8
KEEP_MONTHLY=12
VERIFY_AFTER=yes
SHA256_MANIFEST=no
SCHEDULE=*-*-* 02:00:00
EXCLUDES=
PRE_HOOK=
POST_HOOK=
RESTIC_PASSWORD_FILE=/etc/linux-backup-manager/secrets/webserver01.restic
CREATED_AT=2026-09-24T19:00:00+03:00
```

Do not store arbitrary secrets in profile files.

---

## 7. Backup engines

### 7.1 rsync snapshots

Choose `rsync` when you want a transparent filesystem-style backup that can be browsed with normal Linux tools.

LBM creates timestamped snapshots under the target. When a previous snapshot exists, hard-link reuse (`--link-dest`) reduces duplicate storage for unchanged files.

Conceptual layout:

```text
/backup/webserver01/
└── snapshots/
    ├── 20260924-020001/
    │   ├── data/
    │   ├── lbm-metadata/
    │   ├── lbm-system-inventory.txt
    │   └── lbm-snapshot.meta
    ├── 20260925-020002/
    └── latest -> /backup/.../20260925-020002
```

When SHA-256 manifests are enabled, LBM stores a `SHA256SUMS` file for stronger content verification. This can be expensive on very large trees.

### 7.2 Restic

Choose `restic` for encrypted, deduplicated repositories and remote-backend support.

The repository may be local or a Restic-supported remote backend. Example concepts:

```text
/backup/restic-web01
sftp:backup@backup.example.net:/srv/restic/web01
s3:https://minio.example.net/bucket/web01
```

LBM stores the Restic password file under:

```text
/etc/linux-backup-manager/secrets/PROFILE.restic
```

Protect this directory carefully. Losing the Restic password can make the repository unrecoverable.

### 7.3 tar + zstd

Choose `tarzst` for portable compressed point-in-time archives. LBM preserves ACL/xattr-related metadata where supported and compresses using Zstandard.

This engine is simple and portable but does not provide the same block-level deduplication model as Restic.

---

## 8. Running a backup

Interactive:

```bash
sudo lbm
```

then choose **Run Backup Now**.

CLI:

```bash
sudo lbm run PROFILE
```

Example:

```bash
sudo lbm run webserver01
```

Typical run flow:

```text
profile validation
    ↓
per-profile lock
    ↓
pre-hook
    ↓
application-aware capture
    ↓
system recovery inventory
    ↓
backup engine execution
    ↓
verification (if enabled)
    ↓
retention
    ↓
post-hook
    ↓
history + log update
```

A lock prevents two runs of the same profile from executing simultaneously.

---

## 9. Verification

Run verification manually:

```bash
sudo lbm verify PROFILE
```

Example:

```bash
sudo lbm verify webserver01
```

Verification behavior depends on the engine:

- **rsync:** validates snapshot structure and, when present, SHA-256 checksums
- **Restic:** invokes Restic repository checking
- **tarzst:** verifies Zstandard stream integrity, TAR readability, and checksum when available

Verification does not replace an actual restore test. A backup may pass integrity checks while an application-specific recovery procedure still fails.

---

## 10. Recovery points

List available recovery points:

```bash
sudo lbm points PROFILE
```

Example:

```bash
sudo lbm points webserver01
```

The output format differs by engine. Restic shows repository snapshots; rsync lists snapshot directories; tarzst lists archive paths.

---

## 11. Restore

CLI syntax:

```bash
sudo lbm restore PROFILE POINT DESTINATION
```

A safe restore test example:

```bash
sudo mkdir -p /restore-test/webserver01
sudo lbm restore webserver01 latest /restore-test/webserver01
```

Always test recovery into a separate directory before overwriting production data unless you have a specifically reviewed recovery plan.

### Recommended restore validation

After a test restore:

1. inspect directory/file ownership
2. verify permissions and ACLs
3. compare key configuration files
4. validate application data
5. start the restored service in an isolated environment where possible
6. record the result of the recovery exercise

---

## 12. Retention

Apply retention manually:

```bash
sudo lbm retention PROFILE
```

For Restic, LBM uses daily/weekly/monthly retention values. For the current rsync/tarzst implementation, `KEEP_DAILY` controls how many newest recovery points are retained.

Retention deletes older recovery points. Review profile values before running it against important repositories.

---

## 13. Unattended background scheduling

LBM integrates with systemd rather than keeping a permanent backup process running in the background.

Configure a profile's timer:

```bash
sudo lbm schedule PROFILE
```

Example:

```bash
sudo lbm schedule webserver01
```

A profile can contain:

```text
SCHEDULE=*-*-* 02:00:00
```

LBM creates units conceptually named:

```text
lbm-backup-webserver01.service
lbm-backup-webserver01.timer
```

The timer uses persistent scheduling, so a missed scheduled event can run after reboot.

Inspect timers:

```bash
systemctl list-timers 'lbm-backup-*' --all
```

Inspect one timer:

```bash
systemctl status lbm-backup-webserver01.timer
```

Inspect the most recent job log through systemd:

```bash
journalctl -u lbm-backup-webserver01.service -n 100 --no-pager
```

### Changing the time

Edit or recreate the profile schedule, then run:

```bash
sudo lbm schedule PROFILE
```

Common `OnCalendar` examples:

```text
*-*-* 02:00:00        every day at 02:00
Mon..Fri *-*-* 23:00  weekdays at 23:00
Sun *-*-* 03:30       Sunday at 03:30
```

---

## 14. Application-aware capture

### MySQL / MariaDB

When the profile uses MySQL/MariaDB capture and `mysqldump` is available, LBM can generate a logical dump before the main backup.

The exact authentication model is environment-specific. Configure database credentials securely using the database client's supported mechanism rather than embedding passwords in LBM profile files.

### PostgreSQL

When enabled and `pg_dumpall` is available, LBM executes a logical dump as the `postgres` user.

### Docker

Docker mode captures operational inventory such as:

- containers
- images
- networks
- volumes
- daemon information

This is metadata capture, not a universal application-consistent backup of every Docker volume. Use service-specific quiescing or database dump strategies where required.

---

## 15. Disaster-recovery inventory

Run:

```bash
sudo lbm inventory
```

or specify an output path:

```bash
sudo lbm inventory /root/server-inventory.txt
```

Inventory can contain:

- capture timestamp
- hostname
- OS information
- kernel
- network interfaces
- routes
- mounts
- listening sockets
- enabled systemd services
- package inventory

This information can speed up server reconstruction after a major failure.

---

## 16. History and logs

Show profile history:

```bash
sudo lbm history PROFILE
```

Follow the application log:

```bash
sudo lbm logs
```

Default main log:

```text
/var/log/linux-backup-manager/lbm.log
```

Systemd-run jobs are also visible through `journalctl`.

---

## 17. Storage report

Run:

```bash
sudo lbm storage PROFILE
```

For local engines, this reports filesystem and repository size information. For Restic, LBM queries repository statistics when available.

Always monitor free capacity independently as well. Running out of backup storage can invalidate your expected recovery window.

---

## 18. Doctor / diagnostics

Run:

```bash
sudo lbm doctor
```

Doctor mode is intended to help identify missing tools and environment problems. It is useful after installation and before introducing a new backup engine.

---

## 19. Pre- and post-hooks

Profiles contain optional:

```text
PRE_HOOK=
POST_HOOK=
```

Hooks can be used to coordinate application-specific actions, for example:

- pause a service
- flush data
- create an application snapshot
- run a custom health check
- call an external notification script

Hooks execute with the privileges of the LBM process. Treat them as privileged code and review them carefully.

---

## 20. Email notifications in 1.0.1

Built-in SMTP/email notification configuration is **not included in version 1.0.1**.

Possible interim methods:

- use `POST_HOOK` to call a local mailer or notification script
- monitor the systemd service with your existing monitoring platform
- watch the LBM log for `FAILED` results

Native success/failure email reporting and daily summaries are planned for a future release.

---

## 21. Security recommendations

1. Run LBM administration as root only when required.
2. Keep `/etc/linux-backup-manager/secrets/` root-only.
3. Do not commit real profile secrets to Git.
4. Protect backup repositories with permissions independent from production data where possible.
5. For remote repositories, use dedicated restricted credentials.
6. Keep at least one backup copy that a compromised production host cannot freely destroy.
7. Test restores regularly.
8. Monitor failed or missed timers.
9. Keep recovery credentials in a separate secure process.
10. Use encryption for off-host or untrusted storage.

---

## 22. Troubleshooting

### The program shows only `Select:` instead of the dialog TUI

Verify:

```bash
command -v dialog
printf 'TERM=%s\n' "$TERM"
tty
test -t 0 && echo 'STDIN TTY OK' || echo 'STDIN NO TTY'
test -t 2 && echo 'STDERR TTY OK' || echo 'STDERR NO TTY'
```

Version 1.0.1 contains the fix for normal interactive use where `stdout` is internally captured.

### `restic is not installed`

Debian/Ubuntu:

```bash
sudo apt install restic
```

### `rsync is not installed`

```bash
sudo apt install rsync
```

### `zstd is not installed`

```bash
sudo apt install zstd
```

### A systemd timer does not run

Check:

```bash
systemctl list-timers 'lbm-backup-*' --all
systemctl status lbm-backup-PROFILE.timer
journalctl -u lbm-backup-PROFILE.service --no-pager
```

### Backup is successful but application recovery fails

An integrity-valid filesystem backup may still not be application-consistent. Review database/application quiescing, logical dumps, transactions, and startup dependencies.

---

## 23. Uninstall

Run from the source checkout:

```bash
sudo ./uninstall.sh
```

The uninstaller removes the program executable but intentionally preserves profiles, secrets, history, logs, and backup data.

Review preserved data manually before deleting anything.

---

## 24. Recommended operating procedure

For a production deployment:

1. install LBM and dependencies
2. run `sudo lbm doctor`
3. create one profile
4. run it manually
5. verify it
6. perform a restore into `/restore-test/...`
7. validate the restored application/data
8. configure the systemd timer
9. monitor the first several scheduled runs
10. document the recovery procedure and repeat restore tests periodically

---

## 25. Version and authorship

Current documented release: **1.0.1**

**Linux Backup Manager**  
Designed & Developed by **antonios.mortos@outlook.com**