# Linux Backup Manager — Architecture

Designed & Developed by **antonios.mortos@outlook.com**

## Overview

LBM 1.0.1 is implemented as a Bash application installed as `/usr/local/bin/lbm`. It acts as an orchestration layer over established Linux utilities rather than inventing a proprietary backup format.

## High-level flow

```text
                      ┌───────────────────────────┐
                      │   Interactive TUI / CLI   │
                      └─────────────┬─────────────┘
                                    │
                           profile validation
                                    │
                             per-profile lock
                                    │
                       ┌────────────▼────────────┐
                       │ Pre-backup orchestration│
                       │ hooks / app capture / DR│
                       └────────────┬────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
               ┌────▼────┐     ┌────▼────┐     ┌────▼─────┐
               │  rsync  │     │ Restic  │     │ tar+zstd │
               └────┬────┘     └────┬────┘     └────┬─────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │
                              verification
                                    │
                                retention
                                    │
                                post-hook
                                    │
                          history + application log
```

## Profile-driven design

Each backup job is defined by a profile in `/etc/linux-backup-manager/profiles`. Profiles are text configuration files containing only the parameters required to orchestrate the job.

Sensitive Restic passwords are stored separately under `/etc/linux-backup-manager/secrets`.

## Scheduling

LBM does not remain resident merely to wait for the next backup. Instead, it creates a `systemd` oneshot service and timer for each scheduled profile. This is efficient, observable, and integrates with standard Linux administration.

## Concurrency

Each profile run obtains a `flock` lock under `/run/lock/linux-backup-manager`. This protects against overlapping executions of the same profile.

## Backup engines

### rsync

Rsync profiles use timestamped snapshot directories and `--link-dest` when a previous snapshot exists. The result remains directly browseable as normal files.

### Restic

Restic provides repository encryption, deduplication, snapshot history, and remote repository support. LBM manages repository environment variables and delegates repository mechanics to Restic.

### tar + zstd

Tar+zstd profiles create compressed point-in-time archives and can optionally create SHA-256 sidecar checksums.

## Verification

Verification is engine-specific and deliberately separated from backup creation so it can be invoked on demand as well as after a run.

## Disaster-recovery metadata

LBM captures system state useful for reconstruction, such as OS, kernel, network, mount, socket, service, and package information. Application-aware modes can additionally capture database dumps or Docker metadata.

## Security boundaries

LBM frequently runs as root because faithful system backup/restore can require privileged access. Accordingly:

- profile and secret directories should be protected
- hooks must be considered privileged code
- remote credentials should be dedicated and restricted
- backup repositories should be protected from destructive access where possible

## Future modularization

The current single-script implementation keeps deployment simple. Future major versions may separate engines, notification providers, storage backends, and fleet-management functionality into modules while preserving the same CLI contract.