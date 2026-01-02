function gc --description "Git commit with Conventional Commits message"
    # Parse arguments
    set -l breaking false
    for arg in $argv
        switch $arg
            case -b --breaking
                set breaking true
            case -h --help
                echo "Usage: gc [-b|--breaking]"
                echo "Auto-generates a Conventional Commits message"
                echo ""
                echo "Options:"
                echo "  -b, --breaking  Mark as breaking change (adds !)"
                echo ""
                echo "Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore"
                return 0
        end
    end

    # Check if in a git repo
    if not git rev-parse --git-dir >/dev/null 2>&1
        set_color red
        echo "Error: Not in a git repository"
        set_color normal
        return 1
    end

    # Get staged files by type
    set -l added (git diff --cached --name-only --diff-filter=A 2>/dev/null)
    set -l modified (git diff --cached --name-only --diff-filter=M 2>/dev/null)
    set -l deleted (git diff --cached --name-only --diff-filter=D 2>/dev/null)

    # Check if anything is staged
    if test -z "$added" -a -z "$modified" -a -z "$deleted"
        set_color red
        echo "Error: No staged changes"
        set_color normal
        echo "Stage files with: git add <files>"
        return 1
    end

    # Collect all files
    set -l all_files
    if test -n "$added"
        set all_files $all_files $added
    end
    if test -n "$modified"
        set all_files $all_files $modified
    end
    if test -n "$deleted"
        set all_files $all_files $deleted
    end

    # Get diff content for smart detection
    set -l diff_content (git diff --cached 2>/dev/null | string lower)
    set -l files_lower (string lower -- $all_files | string join ' ')

    # Determine type using Conventional Commits
    set -l commit_type ""

    if test -n "$deleted" -a -z "$added" -a -z "$modified"
        # Only deletions
        set commit_type "chore"
    else if test -n "$added" -a -z "$modified" -a -z "$deleted"
        # Only new files - check what kind
        if string match -qr '(test|spec)' -- $files_lower
            set commit_type "test"
        else if string match -qr '(readme|docs|\.md)' -- $files_lower
            set commit_type "docs"
        else
            set commit_type "feat"
        end
    else
        # Modified or mixed - smart detect from diff content and files
        if string match -qr '(fix|bug|error|issue|patch|correct|crash|fail)' -- $diff_content
            set commit_type "fix"
        else if string match -qr '(refactor|rename|move|extract|restructur)' -- $diff_content
            set commit_type "refactor"
        else if string match -qr '(docs|comment|readme|documentation)' -- $diff_content $files_lower
            set commit_type "docs"
        else if string match -qr '(test|spec|jest|vitest|mocha)' -- $files_lower
            set commit_type "test"
        else if string match -qr '(style|format|lint|prettier|eslint)' -- $diff_content $files_lower
            set commit_type "style"
        else if string match -qr '(perf|optimi|speed|fast|slow|cache)' -- $diff_content
            set commit_type "perf"
        else if string match -qr '(build|webpack|vite|rollup|esbuild|package\.json|tsconfig)' -- $files_lower
            set commit_type "build"
        else if string match -qr '(ci|workflow|github/|\.yml|jenkins|travis)' -- $files_lower
            set commit_type "ci"
        else if string match -qr '(chore|cleanup|maintain|updat|bump|version)' -- $diff_content
            set commit_type "chore"
        else
            # Default based on change type
            if test -n "$added"
                set commit_type "feat"
            else
                set commit_type "refactor"
            end
        end
    end

    # Extract scope from file paths
    set -l scope ""
    set -l primary_file $all_files[1]

    # Try to get meaningful scope from path
    set -l path_parts (string split '/' -- $primary_file)
    if test (count $path_parts) -gt 1
        # Skip src/ and look for meaningful folder
        for part in $path_parts
            if test "$part" != "src" -a "$part" != "." -a "$part" != ".."
                # Check if it's a folder (not the file itself)
                if not string match -qr '\.' -- $part
                    set scope (string lower -- $part)
                    break
                end
            end
        end
    end

    # Extract description from primary file
    set -l basename (string replace -r '.*/' '' -- $primary_file)
    set -l description (string replace -r '\.[^.]+$' '' -- $basename)
    set description (string lower -- $description)
    set description (string replace -r '(\.test|\.spec|_test|_spec)$' '' -- $description)

    # If multiple files in same dir, use that context
    if test (count $all_files) -gt 1
        set -l dirs
        for f in $all_files
            set -l dir (string replace -r '/[^/]+$' '' -- $f)
            set dirs $dirs $dir
        end
        set -l unique_dirs (printf '%s\n' $dirs | sort -u)
        if test (count $unique_dirs) -eq 1
            set -l dir_name (string replace -r '.*/' '' -- $unique_dirs[1])
            if test "$dir_name" != "src" -a "$dir_name" != "."
                set description (string lower -- $dir_name)
            end
        end
    end

    # Build commit message
    set -l breaking_mark ""
    if test "$breaking" = true
        set breaking_mark "!"
    end

    set -l commit_msg ""
    if test -n "$scope"
        set commit_msg "$commit_type($scope)$breaking_mark: $description"
    else
        set commit_msg "$commit_type$breaking_mark: $description"
    end

    # Show staged files
    set_color --bold
    echo "Staged:"
    set_color normal
    for f in $added
        set_color green
        echo "  + $f (new)"
    end
    for f in $modified
        set_color yellow
        echo "  ~ $f (modified)"
    end
    for f in $deleted
        set_color red
        echo "  - $f (deleted)"
    end
    set_color normal
    echo ""

    # Show preview and confirm
    echo -n "Commit message: \""
    set_color cyan
    echo -n "$commit_type"
    if test -n "$scope"
        set_color normal
        echo -n "("
        set_color magenta
        echo -n "$scope"
        set_color normal
        echo -n ")"
    end
    if test -n "$breaking_mark"
        set_color red
        echo -n "!"
    end
    set_color normal
    echo -n ": "
    set_color --bold
    echo -n "$description"
    set_color normal
    echo "\""
    read -l -P "Proceed? [Y/n/e(dit)] " confirm

    switch $confirm
        case '' Y y
            git commit -m "$commit_msg"
        case e E
            # Let user edit the message
            if test -n "$scope"
                read -l -P "Enter message: $commit_type($scope)$breaking_mark: " custom_msg
                if test -n "$custom_msg"
                    git commit -m "$commit_type($scope)$breaking_mark: $custom_msg"
                else
                    git commit -m "$commit_msg"
                end
            else
                read -l -P "Enter message: $commit_type$breaking_mark: " custom_msg
                if test -n "$custom_msg"
                    git commit -m "$commit_type$breaking_mark: $custom_msg"
                else
                    git commit -m "$commit_msg"
                end
            end
        case '*'
            set_color yellow
            echo "Aborted"
            set_color normal
            return 1
    end
end
