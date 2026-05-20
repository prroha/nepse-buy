#!/usr/bin/env bash
#
# create-project.sh - Create a new project from the fullstack-starter template
#
# Usage:
#   ./scripts/create-project.sh <project-name> [--modules module1,module2] [--tier basic|standard|premium|enterprise]
#
# Examples:
#   ./scripts/create-project.sh my-app
#   ./scripts/create-project.sh my-app --tier premium
#   ./scripts/create-project.sh my-app --modules email,payments
#

set -euo pipefail

# ============================================================================
# COLORS AND FORMATTING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}║${NC}        ${CYAN}${BOLD}Fullstack Starter - Project Creator${NC}                      ${BLUE}${BOLD}║${NC}"
    echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    echo -e "${DIM}  $1${NC}"
}

die() {
    print_error "$1"
    exit 1
}

# ============================================================================
# USAGE
# ============================================================================

usage() {
    cat << EOF
${BOLD}Usage:${NC}
    $(basename "$0") <project-name> [options]

${BOLD}Options:${NC}
    --modules <list>    Comma-separated list of modules to install
    --tier <tier>       Preset tier: basic, standard, premium, enterprise
    --output <dir>      Output directory (default: current directory)
    -h, --help          Show this help message

${BOLD}Tier Presets:${NC}
    ${GREEN}basic${NC}       Core only (free)
    ${BLUE}standard${NC}    Core + email + file-upload
    ${MAGENTA}premium${NC}     Core + email + file-upload + payments + analytics
    ${YELLOW}enterprise${NC}  All available modules

${BOLD}Examples:${NC}
    $(basename "$0") my-app
    $(basename "$0") my-app --tier premium
    $(basename "$0") my-app --modules email,payments,push-notifications
    $(basename "$0") my-app --tier standard --output ~/projects

EOF
}

# ============================================================================
# TIER DEFINITIONS
# ============================================================================

get_tier_modules() {
    local tier="$1"
    case "$tier" in
        basic)
            echo ""
            ;;
        standard)
            echo "email,file-upload"
            ;;
        premium)
            echo "email,file-upload,payments,analytics"
            ;;
        enterprise)
            echo "email,file-upload,payments,analytics,push-notifications,social-auth,admin-dashboard,audit-log"
            ;;
        *)
            die "Unknown tier: $tier. Available tiers: basic, standard, premium, enterprise"
            ;;
    esac
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

PROJECT_NAME=""
MODULES=""
TIER=""
OUTPUT_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --modules)
            [[ -z "${2:-}" ]] && die "Missing value for --modules"
            MODULES="$2"
            shift 2
            ;;
        --tier)
            [[ -z "${2:-}" ]] && die "Missing value for --tier"
            TIER="$2"
            shift 2
            ;;
        --output)
            [[ -z "${2:-}" ]] && die "Missing value for --output"
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -*)
            die "Unknown option: $1"
            ;;
        *)
            [[ -n "$PROJECT_NAME" ]] && die "Project name already specified: $PROJECT_NAME"
            PROJECT_NAME="$1"
            shift
            ;;
    esac
done

# ============================================================================
# VALIDATION
# ============================================================================

[[ -z "$PROJECT_NAME" ]] && { usage; die "Project name is required"; }

# Validate project name (alphanumeric, hyphens, underscores)
if ! [[ "$PROJECT_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    die "Invalid project name: '$PROJECT_NAME'. Must start with a letter and contain only letters, numbers, hyphens, and underscores."
fi

# Get script directory (where fullstack-starter is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_DIR="$(dirname "$SCRIPT_DIR")"

# Validate starter directory structure (core/ contains backend, web, mobile)
CORE_DIR="$STARTER_DIR/core"
[[ -d "$CORE_DIR/backend" ]] || die "Cannot find core/backend/ in starter template"
[[ -d "$CORE_DIR/web" ]] || die "Cannot find core/web/ in starter template"
[[ -d "$CORE_DIR/mobile" ]] || die "Cannot find core/mobile/ in starter template"

# Set target directory
TARGET_DIR="$OUTPUT_DIR/$PROJECT_NAME"

# Check if target already exists
[[ -e "$TARGET_DIR" ]] && die "Directory already exists: $TARGET_DIR"

# Merge tier modules with explicitly specified modules
if [[ -n "$TIER" ]]; then
    TIER_MODULES=$(get_tier_modules "$TIER")
    if [[ -n "$MODULES" ]] && [[ -n "$TIER_MODULES" ]]; then
        MODULES="$TIER_MODULES,$MODULES"
    elif [[ -n "$TIER_MODULES" ]]; then
        MODULES="$TIER_MODULES"
    fi
fi

# Convert modules string to array and deduplicate
IFS=',' read -ra MODULE_ARRAY <<< "$MODULES"
declare -A MODULE_MAP
UNIQUE_MODULES=()
for mod in "${MODULE_ARRAY[@]}"; do
    mod=$(echo "$mod" | xargs) # trim whitespace
    if [[ -n "$mod" ]] && [[ -z "${MODULE_MAP[$mod]:-}" ]]; then
        MODULE_MAP["$mod"]=1
        UNIQUE_MODULES+=("$mod")
    fi
done

# ============================================================================
# CREATE PROJECT
# ============================================================================

print_header

echo -e "${BOLD}Project Configuration:${NC}"
echo -e "  Name:     ${CYAN}$PROJECT_NAME${NC}"
echo -e "  Location: ${CYAN}$TARGET_DIR${NC}"
if [[ -n "$TIER" ]]; then
    echo -e "  Tier:     ${MAGENTA}$TIER${NC}"
fi
if [[ ${#UNIQUE_MODULES[@]} -gt 0 ]]; then
    echo -e "  Modules:  ${GREEN}${UNIQUE_MODULES[*]}${NC}"
else
    echo -e "  Modules:  ${DIM}(core only)${NC}"
fi
echo ""

# Step 1: Copy core files
print_step "Copying core template files..."

mkdir -p "$TARGET_DIR"

# Copy core directories (excluding .git, node_modules, etc.)
EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    ".next"
    "dist"
    "build"
    ".dart_tool"
    ".flutter-plugins"
    ".flutter-plugins-dependencies"
    "*.lock"
    ".env"
    ".env.local"
)

# Build rsync exclude options
RSYNC_EXCLUDES=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    RSYNC_EXCLUDES+=("--exclude=$pattern")
done

# Copy using rsync if available, otherwise use cp
if command -v rsync &> /dev/null; then
    # Copy core components (backend, web, mobile) from core/ directory
    rsync -a "${RSYNC_EXCLUDES[@]}" "$CORE_DIR/backend" "$TARGET_DIR/"
    rsync -a "${RSYNC_EXCLUDES[@]}" "$CORE_DIR/web" "$TARGET_DIR/"
    rsync -a "${RSYNC_EXCLUDES[@]}" "$CORE_DIR/mobile" "$TARGET_DIR/"

    # Copy root files
    [[ -f "$STARTER_DIR/package.json" ]] && cp "$STARTER_DIR/package.json" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/.gitignore" ]] && cp "$STARTER_DIR/.gitignore" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/CLAUDE.md" ]] && cp "$STARTER_DIR/CLAUDE.md" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/.env.example" ]] && cp "$STARTER_DIR/.env.example" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/docker-compose.yml" ]] && cp "$STARTER_DIR/docker-compose.yml" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/docker-compose.dev.yml" ]] && cp "$STARTER_DIR/docker-compose.dev.yml" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/.dockerignore" ]] && cp "$STARTER_DIR/.dockerignore" "$TARGET_DIR/"

    # Copy scripts and modules if they exist
    [[ -d "$STARTER_DIR/scripts" ]] && rsync -a "$STARTER_DIR/scripts" "$TARGET_DIR/"
    [[ -d "$STARTER_DIR/modules" ]] && rsync -a "$STARTER_DIR/modules" "$TARGET_DIR/"
    [[ -d "$STARTER_DIR/docs" ]] && rsync -a "$STARTER_DIR/docs" "$TARGET_DIR/"
else
    # Fallback to cp (less precise exclusion)
    cp -r "$CORE_DIR/backend" "$TARGET_DIR/"
    cp -r "$CORE_DIR/web" "$TARGET_DIR/"
    cp -r "$CORE_DIR/mobile" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/package.json" ]] && cp "$STARTER_DIR/package.json" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/.gitignore" ]] && cp "$STARTER_DIR/.gitignore" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/CLAUDE.md" ]] && cp "$STARTER_DIR/CLAUDE.md" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/.env.example" ]] && cp "$STARTER_DIR/.env.example" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/docker-compose.yml" ]] && cp "$STARTER_DIR/docker-compose.yml" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/docker-compose.dev.yml" ]] && cp "$STARTER_DIR/docker-compose.dev.yml" "$TARGET_DIR/"
    [[ -f "$STARTER_DIR/.dockerignore" ]] && cp "$STARTER_DIR/.dockerignore" "$TARGET_DIR/"
    [[ -d "$STARTER_DIR/scripts" ]] && cp -r "$STARTER_DIR/scripts" "$TARGET_DIR/"
    [[ -d "$STARTER_DIR/modules" ]] && cp -r "$STARTER_DIR/modules" "$TARGET_DIR/"
    [[ -d "$STARTER_DIR/docs" ]] && cp -r "$STARTER_DIR/docs" "$TARGET_DIR/"

    # Clean up unwanted directories
    find "$TARGET_DIR" -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$TARGET_DIR" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$TARGET_DIR" -name ".next" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$TARGET_DIR" -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
fi

print_success "Core files copied"

# Step 2: Update package names
print_step "Updating package names..."

# Convert project name to different formats
PROJECT_SNAKE=$(echo "$PROJECT_NAME" | tr '-' '_' | tr '[:upper:]' '[:lower:]')
PROJECT_CAMEL=$(echo "$PROJECT_NAME" | sed -r 's/(^|[-_])([a-z])/\U\2/g' | sed 's/^./\L&/')
PROJECT_PASCAL=$(echo "$PROJECT_NAME" | sed -r 's/(^|[-_])([a-z])/\U\2/g')

# Update root package.json
if [[ -f "$TARGET_DIR/package.json" ]]; then
    if command -v jq &> /dev/null; then
        jq --arg name "$PROJECT_NAME" '.name = $name' "$TARGET_DIR/package.json" > "$TARGET_DIR/package.json.tmp"
        mv "$TARGET_DIR/package.json.tmp" "$TARGET_DIR/package.json"
    else
        sed -i "s/\"name\": \"fullstack-starter\"/\"name\": \"$PROJECT_NAME\"/" "$TARGET_DIR/package.json"
    fi
    print_info "Updated root package.json"
fi

# Update backend package.json
if [[ -f "$TARGET_DIR/backend/package.json" ]]; then
    if command -v jq &> /dev/null; then
        jq --arg name "${PROJECT_NAME}-backend" '.name = $name' "$TARGET_DIR/backend/package.json" > "$TARGET_DIR/backend/package.json.tmp"
        mv "$TARGET_DIR/backend/package.json.tmp" "$TARGET_DIR/backend/package.json"
    else
        sed -i "s/\"name\": \"fullstack-backend\"/\"name\": \"${PROJECT_NAME}-backend\"/" "$TARGET_DIR/backend/package.json"
    fi
    print_info "Updated backend/package.json"
fi

# Update web package.json
if [[ -f "$TARGET_DIR/web/package.json" ]]; then
    if command -v jq &> /dev/null; then
        jq --arg name "${PROJECT_NAME}-web" '.name = $name' "$TARGET_DIR/web/package.json" > "$TARGET_DIR/web/package.json.tmp"
        mv "$TARGET_DIR/web/package.json.tmp" "$TARGET_DIR/web/package.json"
    else
        sed -i "s/\"name\": \"fullstack-web\"/\"name\": \"${PROJECT_NAME}-web\"/" "$TARGET_DIR/web/package.json"
    fi
    print_info "Updated web/package.json"
fi

# Update mobile pubspec.yaml
if [[ -f "$TARGET_DIR/mobile/pubspec.yaml" ]]; then
    sed -i "s/^name: fullstack_mobile/name: ${PROJECT_SNAKE}_mobile/" "$TARGET_DIR/mobile/pubspec.yaml"
    sed -i "s/^description: .*/description: ${PROJECT_NAME} Mobile App/" "$TARGET_DIR/mobile/pubspec.yaml"
    print_info "Updated mobile/pubspec.yaml"
fi

print_success "Package names updated"

# Step 3: Create environment files from examples
print_step "Creating environment files..."

if [[ -f "$TARGET_DIR/backend/.env.example" ]]; then
    cp "$TARGET_DIR/backend/.env.example" "$TARGET_DIR/backend/.env"
    print_info "Created backend/.env from .env.example"
fi

if [[ -f "$TARGET_DIR/web/.env.local.example" ]]; then
    cp "$TARGET_DIR/web/.env.local.example" "$TARGET_DIR/web/.env.local"
    print_info "Created web/.env.local from .env.local.example"
fi

print_success "Environment files created"

# Step 4: Install modules
if [[ ${#UNIQUE_MODULES[@]} -gt 0 ]]; then
    print_step "Installing modules..."

    INSTALL_SCRIPT="$TARGET_DIR/scripts/install-module.sh"

    if [[ -x "$INSTALL_SCRIPT" ]]; then
        for module in "${UNIQUE_MODULES[@]}"; do
            echo -e "  ${CYAN}Installing: $module${NC}"
            if "$INSTALL_SCRIPT" "$module" "$TARGET_DIR" --quiet 2>/dev/null; then
                print_info "Installed $module"
            else
                print_warning "Module '$module' not found or failed to install (you can install it later)"
            fi
        done
        print_success "Module installation complete"
    else
        print_warning "Module installer not found. Skipping module installation."
        print_info "You can install modules later with: ./scripts/install-module.sh <module-name>"
    fi
fi

# Step 5: Initialize git
print_step "Initializing git repository..."

cd "$TARGET_DIR"
git init --quiet
git add .
git commit --quiet -m "Initial commit from fullstack-starter

Created with: create-project.sh $PROJECT_NAME${TIER:+ --tier $TIER}${MODULES:+ --modules $MODULES}"

print_success "Git repository initialized"

# ============================================================================
# COMPLETION
# ============================================================================

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║${NC}                    ${GREEN}${BOLD}Project created successfully!${NC}                  ${GREEN}${BOLD}║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BOLD}Next Steps:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Navigate to your project:"
echo -e "     ${DIM}cd $TARGET_DIR${NC}"
echo ""
echo -e "  ${CYAN}2.${NC} Install dependencies:"
echo -e "     ${DIM}# Backend + Web (Node.js)${NC}"
echo -e "     npm install"
echo ""
echo -e "     ${DIM}# Mobile (Flutter)${NC}"
echo -e "     cd mobile && flutter pub get && cd .."
echo ""
echo -e "  ${CYAN}3.${NC} Configure environment variables:"
echo -e "     ${DIM}# Edit backend/.env and web/.env.local${NC}"
echo ""
echo -e "  ${CYAN}4.${NC} Set up the database:"
echo -e "     cd backend"
echo -e "     npm run db:push        ${DIM}# Quick setup${NC}"
echo -e "     ${DIM}# or${NC}"
echo -e "     npm run db:migrate:dev ${DIM}# With migrations${NC}"
echo ""
echo -e "  ${CYAN}5.${NC} Start development servers:"
echo -e "     ${DIM}# In separate terminals:${NC}"
echo -e "     npm run dev:backend    ${DIM}# Backend on :8000${NC}"
echo -e "     npm run dev:web        ${DIM}# Web on :3000${NC}"
echo -e "     cd mobile && flutter run ${DIM}# Mobile app${NC}"
echo ""

if [[ ${#UNIQUE_MODULES[@]} -gt 0 ]]; then
    echo -e "${BOLD}Installed Modules:${NC}"
    for module in "${UNIQUE_MODULES[@]}"; do
        echo -e "  ${GREEN}•${NC} $module"
    done
    echo ""
    echo -e "  ${DIM}Check each module's documentation for setup instructions.${NC}"
    echo ""
fi

echo -e "${BOLD}Useful Commands:${NC}"
echo -e "  ${DIM}./scripts/list-modules.sh${NC}     ${DIM}# See available modules${NC}"
echo -e "  ${DIM}./scripts/install-module.sh <name>${NC} ${DIM}# Add a module${NC}"
echo ""

echo -e "${DIM}Happy coding!${NC}"
echo ""
