#!/usr/bin/env bash
set -euo pipefail

# Claude Code Setup Installer
# Copies configuration files to ~/.claude/ with backup support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"
DRY_RUN=false
FORCE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --dry-run    Show what would be done without making changes"
  echo "  --force      Overwrite existing files without prompting"
  echo "  -h, --help   Show this help message"
  echo ""
  echo "This script installs Claude Code configuration files to ~/.claude/"
  echo "Existing files are backed up with a .backup.TIMESTAMP extension."
}

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local backup="${file}.backup.${ts}"
    if $DRY_RUN; then
      info "Would backup: $file -> $backup"
    else
      cp "$file" "$backup"
      info "Backed up: $file -> $backup"
    fi
  fi
}

backup_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local backup="${dir}.backup.${ts}"
    if $DRY_RUN; then
      info "Would backup dir: $dir -> $backup"
    else
      cp -r "$dir" "$backup"
      info "Backed up dir: $dir -> $backup"
    fi
  fi
}

copy_dir() {
  local src="$1"
  local dest="$2"
  local name="$3"

  if $DRY_RUN; then
    local count
    count=$(find "$src" -type f | wc -l | tr -d ' ')
    log "Would copy $name ($count files): $src -> $dest"
    return
  fi

  mkdir -p "$dest"
  cp -r "$src"/* "$dest"/ 2>/dev/null || true
  local count
  count=$(find "$dest" -type f | wc -l | tr -d ' ')
  log "Copied $name ($count files)"
}

copy_file() {
  local src="$1"
  local dest="$2"
  local name="$3"

  if $DRY_RUN; then
    log "Would copy: $name -> $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  log "Copied $name"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║    Claude Code Setup Installer       ║"
echo "╚══════════════════════════════════════╝"
echo ""

if $DRY_RUN; then
  warn "DRY RUN MODE — no changes will be made"
  echo ""
fi

# Check prerequisites
if ! command -v node &>/dev/null; then
  warn "Node.js not found. Some hook scripts require Node.js."
fi

if ! command -v npx &>/dev/null; then
  warn "npx not found. MCP servers require npx."
fi

# Confirm installation
if ! $DRY_RUN && ! $FORCE; then
  echo "This will install Claude Code configuration to: $CLAUDE_DIR"
  echo "Existing files will be backed up."
  echo ""
  read -rp "Continue? [y/N] " confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
fi

# Create base directory
if ! $DRY_RUN; then
  mkdir -p "$CLAUDE_DIR"
fi

# Step 1: Settings
log "Step 1/8: Core settings"
backup_file "$CLAUDE_DIR/settings.json"
copy_file "$SCRIPT_DIR/config/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"

# Step 2: Agents
log "Step 2/8: Agent definitions"
backup_dir "$CLAUDE_DIR/agents"
copy_dir "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents" "agents"

# Step 3: Rules
log "Step 3/8: Global rules"
backup_dir "$CLAUDE_DIR/rules"
copy_dir "$SCRIPT_DIR/rules" "$CLAUDE_DIR/rules" "rules"

# Step 4: Hooks
log "Step 4/8: Hook system"
backup_file "$CLAUDE_DIR/hooks/hooks.json"
if ! $DRY_RUN; then
  mkdir -p "$CLAUDE_DIR/hooks"
fi
copy_file "$SCRIPT_DIR/hooks/hooks.json" "$CLAUDE_DIR/hooks/hooks.json" "hooks.json"

# Step 5: Scripts
log "Step 5/8: Scripts"
backup_dir "$CLAUDE_DIR/scripts"
copy_dir "$SCRIPT_DIR/scripts" "$CLAUDE_DIR/scripts" "scripts"

# Set executable permissions on shell scripts
if ! $DRY_RUN; then
  find "$CLAUDE_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
  log "Set executable permissions on .sh files"
fi

# Step 6: Commands
log "Step 6/8: Slash commands"
backup_dir "$CLAUDE_DIR/commands"
copy_dir "$SCRIPT_DIR/commands" "$CLAUDE_DIR/commands" "commands"

# Step 7: Skills
log "Step 7/8: Skills"
backup_dir "$CLAUDE_DIR/skills"
copy_dir "$SCRIPT_DIR/skills" "$CLAUDE_DIR/skills" "skills"

# Step 8: Contexts
log "Step 8/8: Context files"
backup_dir "$CLAUDE_DIR/contexts"
copy_dir "$SCRIPT_DIR/contexts" "$CLAUDE_DIR/contexts" "contexts"

# Fix hook script paths (replace ~ with actual home dir)
if ! $DRY_RUN; then
  if [[ -f "$CLAUDE_DIR/hooks/hooks.json" ]]; then
    sed -i '' "s|~/\.claude/|$CLAUDE_DIR/|g" "$CLAUDE_DIR/hooks/hooks.json" 2>/dev/null || \
    sed -i "s|~/\.claude/|$CLAUDE_DIR/|g" "$CLAUDE_DIR/hooks/hooks.json" 2>/dev/null || true
    log "Updated hook script paths for your environment"
  fi
fi

echo ""
echo "════════════════════════════════════════"
echo ""
log "Installation complete!"
echo ""

# Summary
if ! $DRY_RUN; then
  echo "Installed to: $CLAUDE_DIR"
  echo ""
  echo "  Agents:    $(find "$CLAUDE_DIR/agents" -name "*.md" | wc -l | tr -d ' ') files"
  echo "  Rules:     $(find "$CLAUDE_DIR/rules" -name "*.md" | wc -l | tr -d ' ') files"
  echo "  Commands:  $(find "$CLAUDE_DIR/commands" -name "*.md" | wc -l | tr -d ' ') files"
  echo "  Scripts:   $(find "$CLAUDE_DIR/scripts" -type f | wc -l | tr -d ' ') files"
  echo "  Skills:    $(find "$CLAUDE_DIR/skills" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ') packages"
  echo "  Contexts:  $(find "$CLAUDE_DIR/contexts" -name "*.md" | wc -l | tr -d ' ') files"
fi

echo ""
warn "Post-install checklist:"
echo ""
echo "  1. MCP Servers — Edit ~/.claude.json using config/claude.json.template"
echo "     - Set FIRECRAWL_API_KEY (or remove firecrawl server)"
echo "     - Set filesystem path to your projects directory"
echo "     - Configure project-level MCP servers"
echo ""
echo "  2. GitHub MCP — Run: gh auth login (for GitHub Copilot MCP)"
echo ""
echo "  3. Docker services (optional):"
echo "     docker run -d --name crawl4ai --restart unless-stopped -p 11235:11235 --shm-size=1g unclecode/crawl4ai:latest"
echo "     docker run -d --name searxng --restart unless-stopped -p 8888:8080 searxng/searxng:latest"
echo ""
echo "  4. Plugin — Install dx plugin from within Claude Code:"
echo "     /install-plugin dx@ykdojo"
echo ""
echo "  5. Restart Claude Code to load all configurations"
echo ""
