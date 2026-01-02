function gc --description "Git commit with auto-generated message"
    # Show help
    if test "$argv[1]" = "--help" -o "$argv[1]" = "-h"
        echo "Usage: gc"
        echo "Auto-generates a commit message based on staged changes"
        echo "Prefixes: add: (new files), rm: (deleted), fix:/update: (modified)"
        return 0
    end

    # Check if in a git repo
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git repository"
        return 1
    end

    # Get staged files by type
    set -l added (git diff --cached --name-only --diff-filter=A 2>/dev/null)
    set -l modified (git diff --cached --name-only --diff-filter=M 2>/dev/null)
    set -l deleted (git diff --cached --name-only --diff-filter=D 2>/dev/null)

    # Check if anything is staged
    if test -z "$added" -a -z "$modified" -a -z "$deleted"
        echo "Error: No staged changes"
        echo "Stage files with: git add <files>"
        return 1
    end

    # Determine prefix
    set -l prefix ""
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

    if test -n "$deleted" -a -z "$added" -a -z "$modified"
        # Only deletions
        set prefix "rm"
    else if test -n "$added" -a -z "$modified" -a -z "$deleted"
        # Only new files
        set prefix "add"
    else if test -n "$modified" -a -z "$added" -a -z "$deleted"
        # Only modifications - smart detect
        set -l diff_content (git diff --cached 2>/dev/null | string lower)
        if string match -qr '(fix|bug|error|issue|patch|correct)' -- $diff_content
            set prefix "fix"
        else
            set prefix "update"
        end
    else
        # Mixed changes - determine by what's dominant
        set -l add_count (count $added)
        set -l mod_count (count $modified)
        set -l del_count (count $deleted)

        if test $add_count -ge $mod_count -a $add_count -ge $del_count
            set prefix "add"
        else if test $del_count -ge $add_count -a $del_count -ge $mod_count
            set prefix "rm"
        else
            # Check diff for fix indicators
            set -l diff_content (git diff --cached 2>/dev/null | string lower)
            if string match -qr '(fix|bug|error|issue|patch|correct)' -- $diff_content
                set prefix "fix"
            else
                set prefix "update"
            end
        end
    end

    # Extract feature name from files
    set -l feature_name ""

    # Get the first meaningful file and extract feature name
    set -l primary_file $all_files[1]

    # Strip path and extension to get feature name
    set -l basename (string replace -r '.*/' '' -- $primary_file)
    set -l name_without_ext (string replace -r '\.[^.]+$' '' -- $basename)

    # Convert to lowercase and clean up common suffixes
    set feature_name (string lower -- $name_without_ext)
    set feature_name (string replace -r '(\.test|\.spec|_test|_spec)$' '' -- $feature_name)

    # If multiple files, try to find common pattern or just use first
    if test (count $all_files) -gt 1
        # Check if files share a common directory or pattern
        set -l dirs
        for f in $all_files
            set -l dir (string replace -r '/[^/]+$' '' -- $f)
            set dirs $dirs $dir
        end

        # If all in same directory, use that as context
        set -l unique_dirs (printf '%s\n' $dirs | sort -u)
        if test (count $unique_dirs) -eq 1
            set -l dir_name (string replace -r '.*/' '' -- $unique_dirs[1])
            if test "$dir_name" != "src" -a "$dir_name" != "."
                set feature_name (string lower -- $dir_name)
            end
        end
    end

    # Build the commit message
    set -l commit_msg "$prefix: $feature_name"

    # Show staged files
    echo "Staged:"
    for f in $added
        echo "  + $f (new)"
    end
    for f in $modified
        echo "  ~ $f (modified)"
    end
    for f in $deleted
        echo "  - $f (deleted)"
    end
    echo ""

    # Show preview and confirm
    echo "Commit message: \"$commit_msg\""
    read -l -P "Proceed? [Y/n/e(dit)] " confirm

    switch $confirm
        case '' Y y
            git commit -m "$commit_msg"
        case e E
            # Let user edit the message
            read -l -P "Enter message: $prefix: " custom_msg
            if test -n "$custom_msg"
                git commit -m "$prefix: $custom_msg"
            else
                git commit -m "$commit_msg"
            end
        case '*'
            echo "Aborted"
            return 1
    end
end
