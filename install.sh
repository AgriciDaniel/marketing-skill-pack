#!/usr/bin/env bash
# =============================================================================
# Marketing Skill Pack — Ultimate Installer
# https://github.com/AgriciDaniel/marketing-skill-pack
#
# Compatible : bash 3.2+ | macOS 10.14+ | Ubuntu 18.04+ | Debian 10+
# Windows    : use install.ps1 (finds Git Bash automatically)
# Requires   : git 2.x, Node.js 18+, curl
#
# Usage (install or update everything):
#   curl -fsSL https://raw.githubusercontent.com/AgriciDaniel/marketing-skill-pack/main/install.sh | bash
# =============================================================================

# No set -e: each step is handled individually so one failure won't abort all others.
# No declare -A: not available on macOS default bash 3.2.

# ── Color setup ──────────────────────────────────────────────────────────────
# Disabled automatically when stdout is not a terminal (piped / redirected).
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
# Use printf throughout — macOS BSD echo does not support -e (would print literal \033).
info()    { printf "${CYAN}[.] %s${RESET}\n" "$*"; }
success() { printf "${GREEN}[+] %s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}[!] %s${RESET}\n" "$*"; }
error()   { printf "${RED}[-] %s${RESET}\n" "$*"; }
header()  { printf "\n${BOLD}${CYAN}=== %s ===${RESET}\n" "$*"; }
sep()     { printf "${CYAN}%s${RESET}\n" "----------------------------------------------------"; }

# ── Result tracking (individual vars — bash 3.2 compatible) ──────────────────
R_ESSENTIALS="skipped"
R_SEO="skipped"
R_BLOG="skipped"
R_FORGE="skipped"
R_WP="skipped"

# Shared variable used by install_or_update to signal "installed" vs "updated"
INSTALL_ACTION=""

# ── install_or_update <name> <repo_url> ──────────────────────────────────────
# Clones repo to ~/.claude/packs/<name> on first run.
# On subsequent runs: git pull (fast-forward) then re-runs install.sh.
# Sets INSTALL_ACTION to "installed" or "updated".
# Returns 0 on success, 1 on failure.
install_or_update() {
  local name="$1"
  local repo_url="$2"
  local clone_dir="$PACKS_DIR/$name"
  INSTALL_ACTION=""

  if [ -d "$clone_dir/.git" ]; then
    info "Updating $name ..."
    if git -C "$clone_dir" pull --ff-only 2>/dev/null; then
      success "$name is up to date"
    else
      warn "Fast-forward not possible — fetching and resetting to latest ..."
      git -C "$clone_dir" fetch origin 2>/dev/null || true
      # Try main branch, fall back to master
      git -C "$clone_dir" reset --hard origin/main 2>/dev/null \
        || git -C "$clone_dir" reset --hard origin/master 2>/dev/null \
        || true
    fi
    INSTALL_ACTION="updated"
  else
    info "Cloning $name ..."
    if ! git clone --depth 1 "$repo_url" "$clone_dir"; then
      error "Failed to clone $name"
      return 1
    fi
    INSTALL_ACTION="installed"
  fi

  if [ -f "$clone_dir/install.sh" ]; then
    info "Running $name/install.sh ..."
    if ! bash "$clone_dir/install.sh"; then
      error "$name/install.sh exited with an error"
      return 1
    fi
  fi

  return 0
}

# ── Banner ────────────────────────────────────────────────────────────────────
printf "\n"
sep
printf "${BOLD}  AI Marketing Hub -- Marketing Skill Pack${RESET}\n"
printf "${BOLD}  Ultimate Installer${RESET}\n"
sep
printf "\n"

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
header "Checking Prerequisites"

PREREQ_OK=true

if ! command -v git >/dev/null 2>&1; then
  error "git is not installed."
  printf "       Install it: https://git-scm.com/downloads\n"
  PREREQ_OK=false
else
  success "git found: $(git --version)"
fi

if ! command -v node >/dev/null 2>&1; then
  error "Node.js is not installed."
  printf "       Install it: https://nodejs.org  (v18 or newer)\n"
  PREREQ_OK=false
else
  success "Node.js found: $(node --version)"
fi

if ! command -v curl >/dev/null 2>&1; then
  error "curl is not installed."
  printf "       Install it via your package manager (apt install curl / brew install curl)\n"
  PREREQ_OK=false
else
  success "curl found: $(curl --version | head -1)"
fi

if [ "$PREREQ_OK" = "false" ]; then
  error "Missing prerequisites — please install the tools above and re-run."
  exit 1
fi

# Create the packs directory (persistent clone storage for easy future updates)
PACKS_DIR="$HOME/.claude/packs"
mkdir -p "$PACKS_DIR"
success "Packs directory ready: $PACKS_DIR"

# ── 2. Claude Code Essentials + VS Code ──────────────────────────────────────
header "Claude Code Essentials + VS Code"

# Detect whether claude CLI already exists to determine installed vs updated
CLAUDE_PRE_EXISTS=false
command -v claude >/dev/null 2>&1 && CLAUDE_PRE_EXISTS=true

# Download to a temp file first — avoids issues where a script behaves differently
# when run through a pipe vs as a real file, and lets us check curl's exit code.
_tmp_setup=$(mktemp /tmp/msp-setup-XXXXXX.sh)
if curl -fsSL \
  "https://raw.githubusercontent.com/AgriciDaniel/claude-code-essentials-vs-code/main/scripts/setup.sh" \
  -o "$_tmp_setup"; then
  if bash "$_tmp_setup"; then
    if [ "$CLAUDE_PRE_EXISTS" = "true" ]; then
      R_ESSENTIALS="updated"
    else
      R_ESSENTIALS="installed"
    fi
    success "Claude Code Essentials done"
  else
    error "claude-code-essentials setup script failed"
    R_ESSENTIALS="failed"
  fi
else
  error "Failed to download claude-code-essentials setup script"
  R_ESSENTIALS="failed"
fi
rm -f "$_tmp_setup"

# ── 3. Claude SEO Skill ───────────────────────────────────────────────────────
header "Claude SEO Skill"

if install_or_update "claude-seo" "https://github.com/AgriciDaniel/claude-seo.git"; then
  R_SEO="$INSTALL_ACTION"
  success "Claude SEO done"
else
  error "Claude SEO installation failed — continuing ..."
  R_SEO="failed"
fi

# ── 4. Claude Blog Skill ──────────────────────────────────────────────────────
header "Claude Blog Skill"

if install_or_update "claude-blog" "https://github.com/AgriciDaniel/claude-blog.git"; then
  R_BLOG="$INSTALL_ACTION"
  success "Claude Blog done"
else
  error "Claude Blog installation failed — continuing ..."
  R_BLOG="failed"
fi

# ── 5. Skill Forge ────────────────────────────────────────────────────────────
header "Skill Forge"

if install_or_update "skill-forge" "https://github.com/AgriciDaniel/skill-forge.git"; then
  R_FORGE="$INSTALL_ACTION"
  success "Skill Forge done"
else
  error "Skill Forge installation failed — continuing ..."
  R_FORGE="failed"
fi

# ── 6. WP MCP Ultimate Plugin ────────────────────────────────────────────────
header "WP MCP Ultimate Plugin"

# Respect XDG_DOWNLOAD_DIR if set (Linux standard), fall back to ~/Downloads
DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
mkdir -p "$DOWNLOAD_DIR"
WP_ZIP="$DOWNLOAD_DIR/wp-mcp-ultimate.zip"

info "Downloading wp-mcp-ultimate ..."
if curl -fsSL \
  "https://github.com/AgriciDaniel/wp-mcp-ultimate/archive/refs/heads/main.zip" \
  -o "$WP_ZIP"; then
  success "Downloaded to: $WP_ZIP"
  R_WP="manual"
else
  error "Failed to download wp-mcp-ultimate — check your connection"
  R_WP="failed"
fi

# ── 7. Summary ────────────────────────────────────────────────────────────────
printf "\n"
sep
printf "${BOLD}  Installation Summary${RESET}\n"
sep

print_result() {
  local label="$1"
  local status="$2"
  case "$status" in
    installed) printf "  ${GREEN}[+]${RESET} %-44s ${GREEN}installed${RESET}\n" "$label" ;;
    updated)   printf "  ${GREEN}[+]${RESET} %-44s ${CYAN}updated${RESET}\n"   "$label" ;;
    manual)    printf "  ${YELLOW}[>]${RESET} %-44s ${YELLOW}manual step below${RESET}\n" "$label" ;;
    failed)    printf "  ${RED}[-]${RESET} %-44s ${RED}FAILED (see errors above)${RESET}\n" "$label" ;;
    skipped)   printf "  ${YELLOW}[.]${RESET} %-44s ${YELLOW}skipped${RESET}\n" "$label" ;;
  esac
}

printf "\n"
print_result "Claude Code + VS Code Essentials" "$R_ESSENTIALS"
print_result "Claude SEO Skill                " "$R_SEO"
print_result "Claude Blog Skill               " "$R_BLOG"
print_result "Skill Forge                     " "$R_FORGE"
print_result "WP MCP Ultimate Plugin          " "$R_WP"
printf "\n"

printf "${BOLD}  Available slash commands in Claude Code:${RESET}\n"
printf "  ${CYAN}/seo${RESET}         -- SEO audits, page analysis, schema, sitemap\n"
printf "  ${CYAN}/blog${RESET}        -- Write, rewrite, analyze, and schedule blog content\n"
printf "  ${CYAN}/skill-forge${RESET} -- Design and build new Claude Code skills\n"
printf "\n"

if [ "$R_WP" = "manual" ]; then
  printf "${BOLD}  WordPress Plugin -- Manual install required:${RESET}\n"
  printf "  ${YELLOW}1.${RESET} WP Admin -> Plugins -> Add New -> Upload Plugin\n"
  printf "  ${YELLOW}2.${RESET} Upload: %s\n" "$WP_ZIP"
  printf "  ${YELLOW}3.${RESET} Activate, then go to Tools -> MCP Ultimate for your API key\n"
  printf "  ${YELLOW}   Cloudways:${RESET} upload via the Cloudways WordPress panel\n"
  printf "\n"
fi

printf "${BOLD}${GREEN}  Done. Restart Claude Code to load all skills.${RESET}\n"
sep
printf "\n"
