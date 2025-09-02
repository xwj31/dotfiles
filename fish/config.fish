# Fish Shell Configuration

# ===========================
# Homebrew (Apple Silicon)
# ===========================
eval (/opt/homebrew/bin/brew shellenv)

# ===========================
# Runtime Version Manager
# ===========================
mise activate fish | source

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
alias g- "git checkout -"
alias gpl "git pull"
alias gpu "git push"
alias gst "git status"
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
