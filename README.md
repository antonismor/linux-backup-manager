# Linux Backup Manager (LBM)

**Linux Backup Manager (LBM)** is an open-source backup, restore, verification, retention, and disaster-recovery toolkit for Linux servers. It combines a colored, keyboard-driven terminal UI with a scriptable command-line interface suitable for automation and `systemd` timers.

**Current version:** `1.0.1`

> Designed & Developed by **antonios.mortos@outlook.com**

## Why LBM?

LBM is intended for administrators who want a practical management layer over proven Linux backup tools instead of a single monolithic backup format. A backup profile defines the source, destination, engine, retention, verification, application-aware capture, and schedule. The same profile can be managed interactively or from the CLI.

## Highlights

- Colored terminal dashboard
- Arrow-key / ENTER menus using `dialog`
- Full CLI mode for automation and scripts
- Multiple backup profiles
- `rsync` incremental snapshots with hard-link reuse
- Restic encrypted and deduplicated repositories
- `tar + zstd` compressed recovery archives
- Optional SHA-256 manifests
- Backup verification workflows
- Restore workflows
- Retention / pruning
- `systemd` timer generation for unattended daily backups
- `Persistent=true` timers so missed schedules can run after reboot
- `flock` protection against concurrent runs of the same profile
- MySQL/MariaDB logical dump capture
- PostgreSQL logical dump capture
- Docker inventory capture
- Linux disaster-recovery inventory capture
- Backup history and logs
- Storage reports
- Doctor / dependency diagnostics
- Pre- and post-backup hooks
- Restic remote backends such as SFTP and S3-compatible storage

## Interface preview

```text
╔══════════════════════════════════════════════════════════════════════════════╗
║                         LINUX BACKUP MANAGER                                 ║
║             Backup • Restore • Verify • Retention • DR                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

Host      : backup01.example.net
OS        : Debian GNU/Linux
Profiles  : 5
Failures  : 0
Warnings  : 1
Last OK   : 2026-09-24 19:34

  > Dashboard / Backup Health
    Create Backup Profile
    Run Backup Now
    Restore Backup
    Verify Backup Integrity
    Backup History
    Browse Recovery Points
    Apply Retention
    Schedule / systemd Timers
    Storage Status
    Disaster-Recovery Inventory
    Doctor / Diagnostics
    Logs

Designed & Developed by antonios.mortos@outlook.com
```

## Supported backup engines

| Engine | Best for | Main characteristics |
|---|---|---|
| `rsync` | Local transparent filesystem backups | Incremental snapshots, hard-link reuse, easy file browsing |
| `restic` | Encrypted local or remote repositories | Encryption, deduplication, retention, SFTP/S3-style targets |
| `tarzst` | Portable compressed recovery points | `tar` archive + Zstandard compression |

## Installation

### Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y dialog rsync zstd restic
```

Then clone and install:

```bash
git clone https://github.com/antonismor/linux-backup-manager.git
cd linux-backup-manager
sudo ./install.sh
```

Start the TUI:

```bash
sudo lbm
```

Check the installed version:

```bash
lbm version
```

Expected output:

```text
Linux Backup Manager 1.0.1
```

## Quick start

Create the first profile:

```bash
sudo lbm create
```

Run it:

```bash
sudo lbm run webserver01
```

Verify the latest backup:

```bash
sudo lbm verify webserver01
```

List recovery points:

```bash
sudo lbm points webserver01
```

Perform a restore test into a separate directory:

```bash
sudo lbm restore webserver01 latest /restore-test/webserver01
```

Configure the profile's `systemd` timer:

```bash
sudo lbm schedule webserver01
```

## CLI commands

```text
lbm                         Interactive TUI
lbm status                  Dashboard
lbm profiles                List profiles
lbm create                  Create profile wizard
lbm show PROFILE            Show profile
lbm run PROFILE             Run backup
lbm verify PROFILE          Verify latest backup
lbm points PROFILE          List recovery points
lbm restore PROFILE POINT DEST
lbm history PROFILE         Show run history
lbm retention PROFILE       Apply retention
lbm schedule PROFILE        Install/update systemd timer
lbm storage PROFILE         Storage report
lbm inventory [PATH]        Capture DR inventory
lbm doctor                  Diagnostics
lbm logs                    Follow logs
lbm version                 Show version
```

## Important filesystem paths

| Purpose | Path |
|---|---|
| Profiles | `/etc/linux-backup-manager/profiles/` |
| Secrets | `/etc/linux-backup-manager/secrets/` |
| History / state | `/var/lib/linux-backup-manager/` |
| Logs | `/var/log/linux-backup-manager/` |
| Cache / staging | `/var/cache/linux-backup-manager/` |
| Runtime locks | `/run/lock/linux-backup-manager/` |
| Installed executable | `/usr/local/bin/lbm` |

Secrets are created with restrictive permissions and should remain readable only by `root`.

## Unattended daily backups

LBM can generate a `systemd` service and timer for each profile. The schedule is stored in the profile as a standard `OnCalendar` expression, for example:

```text
*-*-* 02:00:00
```

Run:

```bash
sudo lbm schedule PROFILE
```

The generated timer uses `Persistent=true`, allowing a missed run to be triggered after the machine becomes available again.

Inspect timers with:

```bash
systemctl list-timers 'lbm-backup-*' --all
```

## Application-aware capture

When creating a profile, LBM can optionally capture useful application metadata before the filesystem backup:

- **MySQL/MariaDB:** logical all-database dump with routines and events
- **PostgreSQL:** logical cluster dump through `pg_dumpall`
- **Docker:** container, image, network, volume, and daemon information

This metadata is supplemental. Production database recovery requirements can differ, so test the exact restore procedure for your workload.

## Disaster-recovery inventory

LBM can capture information useful during server reconstruction, including:

- hostname and OS
- kernel
- IP addresses
- routes
- mounted filesystems
- listening sockets
- enabled services
- installed packages

Create a standalone inventory with:

```bash
sudo lbm inventory
```

## Safety model

LBM is intentionally conservative in several areas:

- profile runs use a lock to avoid concurrent execution of the same job
- restore destinations are explicit
- retention is a separate operation
- secrets are stored outside normal profile data
- verification can run automatically after backup
- logs and history are preserved separately from backup data

## Version 1.0.1 note

Version `1.0.1` fixes TUI detection when menu values are captured internally. The `dialog` interface now tests interactive `stdin` / `stderr` instead of captured `stdout`, preventing an incorrect fallback to the numeric `Select:` menu in normal interactive terminals.

## Documentation

The complete administrator manual is available here:

- [`docs/MANUAL.md`](docs/MANUAL.md)
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`CHANGELOG.md`](CHANGELOG.md)
- [`SECURITY.md`](SECURITY.md)
- [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Current limitations

Version `1.0.1` does **not yet include built-in email notifications**. Background scheduling is supported through `systemd`; email / SMTP reporting is planned for a future release. Until then, administrators can use post-hooks or external monitoring if notification is required.

## Roadmap

Potential future work includes:

- SMTP/email success and failure reports
- daily summary reports
- LVM/ZFS/Btrfs snapshot-aware workflows
- SSH rsync target wizard
- S3/B2/MinIO credential wizard
- Borg backend
- immutable/offline repository policies
- point-in-time file catalog and search
- recovery-point config diff
- automated scheduled restore tests
- webhook / Teams / Telegram notifications
- multi-server controller and lightweight agent
- optional web dashboard
- ransomware-oriented repository-health checks

## Production warning

A completed backup is not proof of recoverability. Test restores regularly, especially for databases and application state. Validate LBM in a non-production environment before relying on it for critical workloads.

## License

MIT License. See [`LICENSE`](LICENSE).

## Author

**Antonios Mortos**  
Designed & Developed by **antonios.mortos@outlook.com**
