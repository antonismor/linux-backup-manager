# Contributing to Linux Backup Manager

Contributions are welcome.

## Development principles

Changes should preserve the following goals:

- predictable Linux administration behavior
- safe defaults
- readable Bash
- no hidden destructive actions
- CLI compatibility for automation
- useful diagnostics and clear error messages
- graceful operation with or without the full `dialog` TUI

## Before submitting changes

1. run Bash syntax checks
2. test the affected command in a non-production environment
3. test restore behavior when backup/restore code changes
4. avoid introducing secrets into examples or fixtures
5. update documentation and the changelog when user-visible behavior changes

Syntax check example:

```bash
bash -n lbm
bash -n install.sh
bash -n uninstall.sh
```

## Pull requests

Please explain:

- the problem being solved
- the implementation approach
- any compatibility impact
- how the change was tested

Designed & Developed by **antonios.mortos@outlook.com**