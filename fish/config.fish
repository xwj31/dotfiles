# Fish Shell Configuration

# ===========================
# PATH Deduplication Function
# ===========================
function dedupe_path
    set -l clean_path
    for path in $PATH
        if not contains $path $clean_path
            set clean_path $clean_path $path
        end
    end
    set -gx PATH $clean_path
end

# ===========================
# Clear fish_user_paths (prevents persistent duplicates)
# ===========================
set -e fish_user_paths

# ===========================
# Homebrew (Apple Silicon)
# ===========================
if test -f /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# ===========================
# Runtime Version Manager (Mise)
# ===========================
if type -q mise
    mise activate fish | source
end

# ===========================
# Android SDK Configuration
# ===========================
set -gx ANDROID_HOME $HOME/Library/Android/sdk
set -gx ANDROID_SDK_ROOT $HOME/Library/Android/sdk

# Add Android paths only if they exist and aren't already in PATH
if test -d $ANDROID_HOME
    for android_path in \
        $ANDROID_HOME/platform-tools \
        $ANDROID_HOME/emulator \
        $ANDROID_HOME/cmdline-tools/latest/bin \
        $ANDROID_HOME/cmdline-tools/8.0/bin \
        $ANDROID_HOME/tools/bin \
        $ANDROID_HOME/tools
        
        if test -d $android_path; and not contains $android_path $PATH
            set -gx PATH $android_path $PATH
        end
    end
end

# ===========================
# Development Tools
# ===========================
# Composer
if test -d $HOME/.composer/vendor/bin; and not contains $HOME/.composer/vendor/bin $PATH
    set -gx PATH $HOME/.composer/vendor/bin $PATH
end

# Bun
if test -d $HOME/.bun/bin; and not contains $HOME/.bun/bin $PATH
    set -gx PATH $HOME/.bun/bin $PATH
end

# Local bin
if test -d $HOME/.local/bin; and not contains $HOME/.local/bin $PATH
    set -gx PATH $HOME/.local/bin $PATH
end

# Poetry (handle spaces properly)
set -l poetry_path "$HOME/Library/Application Support/pypoetry/venv/bin"
if test -d "$poetry_path"; and not contains "$poetry_path" $PATH
    set -gx PATH "$poetry_path" $PATH
end

# Deno
if test -f /usr/local/bin/deno; and not contains /usr/local/bin $PATH
    set -gx PATH /usr/local/bin $PATH
end

# OrbStack
if test -d $HOME/.orbstack/bin; and not contains $HOME/.orbstack/bin $PATH
    set -gx PATH $HOME/.orbstack/bin $PATH
end

# Postgres.app
if test -d /Applications/Postgres.app/Contents/Versions/latest/bin
    if not contains /Applications/Postgres.app/Contents/Versions/latest/bin $PATH
        set -gx PATH /Applications/Postgres.app/Contents/Versions/latest/bin $PATH
    end
end

# LaTeX
if test -d /Library/TeX/texbin; and not contains /Library/TeX/texbin $PATH
    set -gx PATH /Library/TeX/texbin $PATH
end

# ===========================
# Final PATH Cleanup
# ===========================
dedupe_path

# ===========================
# Git Commit Helper Function
# ===========================
function gc
    if test (count $argv) -eq 0
        set_color yellow
        echo "Usage: "
        set_color normal
        echo "  gc <type> <message>"
        echo ""
        set_color yellow
        echo "Types:"
        set_color normal
        set_color green; echo -n "  add"; set_color normal; echo "      - Add new feature/file"
        set_color red; echo -n "  rm"; set_color normal; echo "       - Remove file/feature"
        set_color blue; echo -n "  chore"; set_color normal; echo "    - Maintenance task"
        set_color magenta; echo -n "  fix"; set_color normal; echo "      - Bug fix"
        set_color cyan; echo -n "  feat"; set_color normal; echo "     - New feature"
        set_color white; echo -n "  docs"; set_color normal; echo "     - Documentation"
        set_color yellow; echo -n "  style"; set_color normal; echo "    - Code style/formatting"
        set_color green; echo -n "  refactor"; set_color normal; echo " - Code refactoring"
        set_color blue; echo -n "  test"; set_color normal; echo "     - Add/update tests"
        return 1
    end
    git commit -m "$argv[1]: $argv[2..-1]"
end

# ===========================
# Yarn/Node Aliases
# ===========================
alias yb "yarn build"
alias ys "yarn start"
alias yc "yarn clean"
alias yd "yarn dev"
alias yt "yarn test"
alias ut "yarn test -u"
alias nk "npx npkill"

# ===========================
# Git Aliases
# ===========================
alias gs "git status"
alias gst "git status"  # You had both gs and gst
alias g- "git checkout -"
alias gpl "git pull"
alias gpu "git push"
alias grb "git rebase origin/main"
alias gco "git checkout"
alias gcm "git commit -m"
alias ga "git add ."
alias gd "git diff"

# ===========================
# Mobile Development
# ===========================
# iOS
alias bepi "bundle exec pod install --verbose"

# Android
alias ab "adb reverse tcp:8081 tcp:8081"

# ===========================
# Laravel Sail
# ===========================
alias sail='bash vendor/bin/sail'
