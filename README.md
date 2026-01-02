# dotfiles

My dotfiles.

## Functions

### gc

Git commit helper that auto-generates [Conventional Commits](https://www.conventionalcommits.org/) messages based on staged changes.

**Usage:**

```bash
gc [-b|--breaking]
```

**Options:**

- `-b, --breaking` - Mark as a breaking change (adds `!` to the commit type)
- `-h, --help` - Show help

**How it works:**

1. Analyzes staged files and diff content to detect the commit type:
   - `feat` - New files or features
   - `fix` - Bug fixes (detected from keywords like "fix", "bug", "error")
   - `docs` - Documentation changes
   - `style` - Formatting/linting changes
   - `refactor` - Code refactoring
   - `perf` - Performance improvements
   - `test` - Test files
   - `build` - Build config changes (package.json, webpack, etc.)
   - `ci` - CI/CD changes (workflows, yml files)
   - `chore` - Maintenance tasks, deletions

2. Extracts scope from file paths (e.g., `functions/gc.fish` -> `functions`)

3. Shows a preview of staged files and the generated commit message

4. Prompts for confirmation:
   - `Y` or Enter - Commit with generated message
   - `e` - Edit the description portion of the message
   - `n` or other - Abort
