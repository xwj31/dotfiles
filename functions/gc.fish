# Helper: Extract scopes from file paths
function _gc_extract_scopes
    set -l files $argv
    set -l scopes
    set -l skip_dirs "src" "." ".." "lib" "app" "packages"

    for f in $files
        set -l path_parts (string split '/' -- $f)
        for part in $path_parts
            # Skip common non-meaningful directories and files
            if contains -- $part $skip_dirs; or string match -qr '\.' -- $part
                continue
            end
            # Found a meaningful scope
            set -l scope_lower (string lower -- $part)
            if not contains -- $scope_lower $scopes
                set scopes $scopes $scope_lower
            end
            break
        end
    end

    # Build scope string (limit to 2 for readability)
    if test (count $scopes) -eq 1
        echo $scopes[1]
    else if test (count $scopes) -ge 2
        echo "$scopes[1],$scopes[2]"
    end
end

# Helper: Generate description from file paths
function _gc_generate_description
    set -l files $argv
    set -l file_count (count $files)

    if test $file_count -eq 1
        # Single file: use filename
        set -l basename (string replace -r '.*/' '' -- $files[1])
        set -l desc (string replace -r '\.[^.]+$' '' -- $basename)
        set desc (string lower -- $desc)
        set desc (string replace -r '(\.test|\.spec|_test|_spec)$' '' -- $desc)
        echo $desc
        return
    end

    # Multiple files: extract meaningful names
    set -l file_names
    for f in $files
        set -l basename (string replace -r '.*/' '' -- $f)
        set -l name (string replace -r '\.[^.]+$' '' -- $basename)
        set name (string lower -- $name)
        set name (string replace -r '(\.test|\.spec|_test|_spec)$' '' -- $name)
        # Skip generic names
        if test "$name" != "index" -a "$name" != "types" -a "$name" != "utils"
            if not contains -- $name $file_names
                set file_names $file_names $name
            end
        end
    end

    # Get scopes for fallback
    set -l scopes (_gc_extract_scopes $files | string split ',')

    if test (count $file_names) -eq 1
        echo "$file_names[1]"
    else if test (count $file_names) -eq 2
        echo "$file_names[1] and $file_names[2]"
    else if test (count $file_names) -gt 2
        if test (count $scopes) -eq 1
            echo "$scopes[1] updates"
        else
            echo "$file_names[1] and $file_names[2]"
        end
    else if test (count $scopes) -gt 0
        # All generic names, use scope-based description
        echo "$scopes[1] updates"
    else
        echo "multiple files"
    end
end

# Helper: Detect commit type
function _gc_detect_type -a change_type files_lower diff_content
    # Only deletions
    if test "$change_type" = "deleted"
        echo "chore"
        return
    end

    # Only new files
    if test "$change_type" = "added"
        if string match -qr '(test|spec)' -- $files_lower
            echo "test"
        else if string match -qr '(readme|docs|\.md)' -- $files_lower
            echo "docs"
        else
            echo "feat"
        end
        return
    end

    # Mixed: new files + modifications → default to feat unless diff suggests otherwise
    if test "$change_type" = "mixed"
        if string match -qr '(fix|bug|error|issue|patch|correct|crash|fail)' -- $diff_content
            echo "fix"
        else
            echo "feat"
        end
        return
    end

    # Modified only - smart detect from diff content and files
    if string match -qr '(fix|bug|error|issue|patch|correct|crash|fail)' -- $diff_content
        echo "fix"
    else if string match -qr '(refactor|rename|move|extract|restructur)' -- $diff_content
        echo "refactor"
    else if string match -qr '(readme|documentation|\.md)' -- $diff_content $files_lower
        echo "docs"
    else if string match -qr '(test|spec|jest|vitest|mocha)' -- $files_lower
        echo "test"
    else if string match -qr '(style|format|lint|prettier|eslint)' -- $diff_content $files_lower
        echo "style"
    else if string match -qr '(perf|optimi|speed|fast|slow|cache)' -- $diff_content
        echo "perf"
    else if string match -qr '(build|webpack|vite|rollup|esbuild|package\.json|tsconfig)' -- $files_lower
        echo "build"
    else if string match -qr '(ci|workflow|github/|\.yml|jenkins|travis)' -- $files_lower
        echo "ci"
    else if string match -qr '(chore|cleanup|maintain|updat|bump|version)' -- $diff_content
        echo "chore"
    else
        echo "refactor"
    end
end

function gc --description "Git commit with Conventional Commits message"
    # Parse arguments
    set -l breaking false
    set -l debug false
    for arg in $argv
        switch $arg
            case -b --breaking
                set breaking true
            case -d --debug
                set debug true
            case -v --version
                echo "gc version 1.1.0"
                return 0
            case -h --help
                echo "Usage: gc [-b|--breaking] [-d|--debug] [-v|--version]"
                echo "Auto-generates a Conventional Commits message"
                echo ""
                echo "Options:"
                echo "  -b, --breaking  Mark as breaking change (adds !)"
                echo "  -d, --debug     Show debug info (scopes, file_names, etc.)"
                echo "  -v, --version   Show version number"
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

    # Determine commit type
    set -l change_type "modified"
    if test -n "$deleted" -a -z "$added" -a -z "$modified"
        set change_type "deleted"
    else if test -n "$added" -a -z "$modified" -a -z "$deleted"
        set change_type "added"
    else if test -n "$added"
        # Mixed: new files + modifications → treat as feature addition
        set change_type "mixed"
    end
    set -l commit_type (_gc_detect_type $change_type $files_lower $diff_content)

    # Extract scope and description using helpers
    set -l scope (_gc_extract_scopes $all_files)
    set -l description (_gc_generate_description $all_files)

    # Debug output
    if test "$debug" = true
        set_color --dim
        echo "Debug:"
        echo "  change_type: $change_type"
        echo "  files: $all_files"
        echo "  diff preview: "(string sub -l 100 -- $diff_content)"..."
        echo "  commit_type: $commit_type"
        echo "  scope: $scope"
        echo "  description: $description"
        set_color normal
        echo ""
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
