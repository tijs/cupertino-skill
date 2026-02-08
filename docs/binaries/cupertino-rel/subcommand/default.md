# cupertino-rel subcommands

Available subcommands for the release tool.

## Subcommands

| Subcommand | Description |
|------------|-------------|
| [bump](bump/) | Bump version in all required files |
| [tag](tag/) | Commit changes and create git tag |
| [databases](databases/) | Package and upload databases to GitHub Releases |
| [homebrew](homebrew/) | Update Homebrew formula with new version |
| [docs-update](docs-update/) | Update documentation databases and bump minor version |
| [full](full/) | Run the complete release workflow (default) |

## Default

If no subcommand is specified, `full` is executed.

```bash
cupertino-rel              # runs 'full'
cupertino-rel full         # explicit
```
