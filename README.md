# dotfiles

My dotfiles.

## Setup

### Fish Shell

Add this to your `~/.config/fish/config.fish` to load the custom functions:

```fish
set -p fish_function_path ~/projects/dotfiles/functions
```

The `fish/config.fish` file configures:

**PATH Management:**

- Loads custom functions from `~/projects/dotfiles/functions`
- Deduplicates PATH entries automatically
- Configures Homebrew (Apple Silicon)
- Mise (runtime version manager)

**Development Tools:**

- Android SDK
- Composer
- Bun
- Poetry
- Deno
- OrbStack
- Postgres.app
- LaTeX

**Aliases:**

| Alias | Command | Category |
| ------- | --------- | ---------- |
| `yb` | `yarn build` | Node |
| `ys` | `yarn start` | Node |
| `yc` | `yarn clean` | Node |
| `yd` | `yarn dev` | Node |
| `yt` | `yarn test` | Node |
| `ut` | `yarn test -u` | Node |
| `nk` | `npx npkill` | Node |
| `gst` | `git status` | Git |
| `g-` | `git checkout -` | Git |
| `gpl` | `git pull` | Git |
| `gpu` | `git push` | Git |
| `grb` | `git rebase origin/main` | Git |
| `gco` | `git checkout` | Git |
| `gcm` | `git commit -m` | Git |
| `ga` | `git add .` | Git |
| `gd` | `git diff` | Git |
| `bepi` | `bundle exec pod install --verbose` | iOS |
| `ab` | `adb reverse tcp:8081 tcp:8081` | Android |
| `sail` | `bash vendor/bin/sail` | Laravel |

## Functions

### gc

Git commit helper that auto-generates [Conventional Commits](https://www.conventionalcommits.org/) messages based on staged changes.

**Usage:**

```bash
gc [-b|--breaking] [-d|--debug] [-v|--version]
```

**Options:**

- `-b, --breaking` - Mark as a breaking change (adds `!` to the commit type)
- `-d, --debug` - Show debug info (change type, files, diff preview, detected values)
- `-v, --version` - Show version number
- `-h, --help` - Show help

**How it works:**

1. Analyzes staged files and diff content to detect the commit type:
   - `feat` - New files or features (also used for mixed adds + modifications)
   - `fix` - Bug fixes (detected from keywords like "fix", "bug", "error")
   - `docs` - Documentation changes
   - `style` - Formatting/linting changes
   - `refactor` - Code refactoring (default for modifications)
   - `perf` - Performance improvements
   - `test` - Test files
   - `build` - Build config changes (package.json, webpack, etc.)
   - `ci` - CI/CD changes (workflows, yml files)
   - `chore` - Maintenance tasks, deletions

2. Extracts scope from file paths (e.g., `functions/gc.fish` -> `functions`). Supports up to 2 scopes for multi-directory changes.

3. Generates description from filenames:
   - Single file: uses the filename
   - Two files: "file1 and file2"
   - Many files in same scope: "scope updates"

4. Shows a color-coded preview of staged files and the generated commit message

5. Prompts for confirmation:
   - `Y` or Enter - Commit with generated message
   - `e` - Edit the description portion of the message
   - `n` or other - Abort
