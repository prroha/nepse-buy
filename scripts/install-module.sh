#!/usr/bin/env bash
#
# install-module.sh - Install a module into a fullstack-starter project
#
# Usage:
#   ./scripts/install-module.sh <module-name> [project-path] [options]
#
# Examples:
#   ./scripts/install-module.sh email
#   ./scripts/install-module.sh payments /path/to/my-project
#   ./scripts/install-module.sh email --quiet
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

QUIET_MODE=false

print_header() {
    [[ "$QUIET_MODE" == true ]] && return
    echo ""
    echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}${BOLD}║${NC}           ${CYAN}${BOLD}Fullstack Starter - Module Installer${NC}                 ${MAGENTA}${BOLD}║${NC}"
    echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${BLUE}▶${NC} ${BOLD}$1${NC}"
}

print_success() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    [[ "$QUIET_MODE" == true ]] && return
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
    $(basename "$0") <module-name> [project-path] [options]

${BOLD}Arguments:${NC}
    module-name     Name of the module to install
    project-path    Path to the project (default: current directory)

${BOLD}Options:${NC}
    --quiet, -q     Suppress most output
    --dry-run       Show what would be done without making changes
    --force         Overwrite existing files
    -h, --help      Show this help message

${BOLD}Examples:${NC}
    $(basename "$0") email
    $(basename "$0") payments /path/to/my-project
    $(basename "$0") analytics --dry-run

${BOLD}Available Modules:${NC}
    Run ./scripts/list-modules.sh to see all available modules

EOF
}

# ============================================================================
# JSON PARSING HELPERS
# ============================================================================

# Parse JSON value using jq if available, otherwise use basic parsing
json_get() {
    local json="$1"
    local key="$2"

    if command -v jq &> /dev/null; then
        echo "$json" | jq -r "$key // empty"
    else
        # Basic parsing for simple cases (not recommended for production)
        echo "$json" | grep -oP "\"${key#.}\"\s*:\s*\"\K[^\"]*" | head -1
    fi
}

json_get_array() {
    local json="$1"
    local key="$2"

    if command -v jq &> /dev/null; then
        echo "$json" | jq -r "$key[]? // empty"
    else
        # Basic parsing - very limited
        echo ""
    fi
}

# ============================================================================
# DEPENDENCY MERGING
# ============================================================================

merge_package_json_deps() {
    local target_file="$1"
    local deps_json="$2"
    local dep_type="${3:-dependencies}" # dependencies or devDependencies

    if [[ ! -f "$target_file" ]]; then
        print_warning "Target package.json not found: $target_file"
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        print_warning "jq not installed. Manual dependency addition required."
        print_info "Add these $dep_type to $target_file:"
        echo "$deps_json"
        return 0
    fi

    # Merge dependencies
    local temp_file="${target_file}.tmp"
    jq --argjson newdeps "$deps_json" ".$dep_type += \$newdeps" "$target_file" > "$temp_file"
    mv "$temp_file" "$target_file"

    print_info "Merged $dep_type into $(basename "$target_file")"
}

merge_pubspec_deps() {
    local target_file="$1"
    local deps_yaml="$2"

    if [[ ! -f "$target_file" ]]; then
        print_warning "Target pubspec.yaml not found: $target_file"
        return 1
    fi

    # For pubspec.yaml, we need to append dependencies carefully
    # This is a simplified approach - production should use yq or similar

    if command -v yq &> /dev/null; then
        # Use yq for proper YAML merging
        local temp_file="${target_file}.tmp"
        echo "$deps_yaml" | yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$target_file" - > "$temp_file"
        mv "$temp_file" "$target_file"
        print_info "Merged dependencies into pubspec.yaml using yq"
    else
        # Simple append approach - add to end of dependencies section
        print_warning "yq not installed. Dependencies will be listed for manual addition."
        print_info "Add these dependencies to $target_file:"
        echo "$deps_yaml"
    fi
}

# ============================================================================
# FILE COPYING
# ============================================================================

copy_module_files() {
    local source_dir="$1"
    local target_dir="$2"
    local platform="$3"

    if [[ ! -d "$source_dir" ]]; then
        return 0
    fi

    # Copy files maintaining directory structure
    if command -v rsync &> /dev/null; then
        rsync -a "$source_dir/" "$target_dir/"
    else
        cp -r "$source_dir/"* "$target_dir/" 2>/dev/null || true
    fi

    print_info "Copied $platform files"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

MODULE_NAME=""
PROJECT_PATH=""
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -*)
            die "Unknown option: $1"
            ;;
        *)
            if [[ -z "$MODULE_NAME" ]]; then
                MODULE_NAME="$1"
            elif [[ -z "$PROJECT_PATH" ]]; then
                PROJECT_PATH="$1"
            else
                die "Too many arguments"
            fi
            shift
            ;;
    esac
done

# ============================================================================
# VALIDATION
# ============================================================================

[[ -z "$MODULE_NAME" ]] && { usage; die "Module name is required"; }

# Determine project path
if [[ -z "$PROJECT_PATH" ]]; then
    PROJECT_PATH="$(pwd)"
fi

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || die "Invalid project path: $PROJECT_PATH"

# Find modules directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in a project or the starter template
if [[ -d "$PROJECT_PATH/modules" ]]; then
    MODULES_DIR="$PROJECT_PATH/modules"
elif [[ -d "$SCRIPT_DIR/../modules" ]]; then
    MODULES_DIR="$(cd "$SCRIPT_DIR/../modules" && pwd)"
else
    die "Cannot find modules directory"
fi

# Validate module exists
MODULE_DIR="$MODULES_DIR/$MODULE_NAME"
[[ -d "$MODULE_DIR" ]] || die "Module not found: $MODULE_NAME

Available modules in $MODULES_DIR:
$(ls -1 "$MODULES_DIR" 2>/dev/null | sed 's/^/  - /' || echo "  (none)")

Run ./scripts/list-modules.sh for more information."

# Validate module.json exists
MODULE_JSON="$MODULE_DIR/module.json"
[[ -f "$MODULE_JSON" ]] || die "Module configuration not found: $MODULE_JSON"

# Validate project structure - check for backend in root or core/
if [[ -d "$PROJECT_PATH/backend" ]]; then
    BACKEND_PATH="$PROJECT_PATH/backend"
    WEB_PATH="$PROJECT_PATH/web"
    MOBILE_PATH="$PROJECT_PATH/mobile"
elif [[ -d "$PROJECT_PATH/core/backend" ]]; then
    # Running from starter template directory
    BACKEND_PATH="$PROJECT_PATH/core/backend"
    WEB_PATH="$PROJECT_PATH/core/web"
    MOBILE_PATH="$PROJECT_PATH/core/mobile"
else
    die "Invalid project: Cannot find backend/ or core/backend/ in $PROJECT_PATH"
fi

[[ -d "$BACKEND_PATH" ]] || die "Invalid project: backend not found"
[[ -d "$WEB_PATH" ]] || die "Invalid project: web not found"

# ============================================================================
# LOAD MODULE CONFIGURATION
# ============================================================================

print_header

MODULE_CONFIG=$(cat "$MODULE_JSON")

# Extract module info
MODULE_DISPLAY_NAME=$(json_get "$MODULE_CONFIG" '.name')
MODULE_VERSION=$(json_get "$MODULE_CONFIG" '.version')
MODULE_DESCRIPTION=$(json_get "$MODULE_CONFIG" '.description')

[[ -z "$MODULE_DISPLAY_NAME" ]] && MODULE_DISPLAY_NAME="$MODULE_NAME"
[[ -z "$MODULE_VERSION" ]] && MODULE_VERSION="1.0.0"

echo -e "${BOLD}Installing Module:${NC}"
echo -e "  Name:        ${CYAN}$MODULE_DISPLAY_NAME${NC}"
echo -e "  Version:     ${DIM}$MODULE_VERSION${NC}"
echo -e "  Description: ${DIM}$MODULE_DESCRIPTION${NC}"
echo -e "  Target:      ${CYAN}$PROJECT_PATH${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}${BOLD}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# ============================================================================
# INSTALL MODULE
# ============================================================================

# Step 1: Copy backend files
if [[ -d "$MODULE_DIR/backend" ]]; then
    print_step "Installing backend files..."

    if [[ "$DRY_RUN" == false ]]; then
        copy_module_files "$MODULE_DIR/backend/src" "$BACKEND_PATH/src" "backend"

        # Copy prisma schema additions if present
        if [[ -f "$MODULE_DIR/backend/prisma/schema.prisma.append" ]]; then
            print_info "Prisma schema additions found"
            if [[ "$QUIET_MODE" == false ]]; then
                echo ""
                echo -e "  ${YELLOW}Manual Step Required:${NC}"
                echo -e "  Add the following to ${CYAN}backend/prisma/schema.prisma${NC}:"
                echo ""
                cat "$MODULE_DIR/backend/prisma/schema.prisma.append" | sed 's/^/    /'
                echo ""
            fi
        fi
    else
        print_info "Would copy backend files from $MODULE_DIR/backend"
    fi

    print_success "Backend files installed"
fi

# Step 2: Copy web files
if [[ -d "$MODULE_DIR/web" ]]; then
    print_step "Installing web files..."

    if [[ "$DRY_RUN" == false ]]; then
        copy_module_files "$MODULE_DIR/web/src" "$WEB_PATH/src" "web"
    else
        print_info "Would copy web files from $MODULE_DIR/web"
    fi

    print_success "Web files installed"
fi

# Step 3: Copy mobile files
if [[ -d "$MODULE_DIR/mobile" ]]; then
    print_step "Installing mobile files..."

    if [[ "$DRY_RUN" == false ]]; then
        copy_module_files "$MODULE_DIR/mobile/lib" "$MOBILE_PATH/lib" "mobile"
    else
        print_info "Would copy mobile files from $MODULE_DIR/mobile"
    fi

    print_success "Mobile files installed"
fi

# Step 4: Merge dependencies
print_step "Merging dependencies..."

# Backend dependencies
BACKEND_DEPS=$(json_get "$MODULE_CONFIG" '.dependencies.backend')
BACKEND_DEV_DEPS=$(json_get "$MODULE_CONFIG" '.devDependencies.backend')

if [[ -n "$BACKEND_DEPS" ]] && [[ "$BACKEND_DEPS" != "null" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
        merge_package_json_deps "$BACKEND_PATH/package.json" "$BACKEND_DEPS" "dependencies"
    else
        print_info "Would add backend dependencies: $BACKEND_DEPS"
    fi
fi

if [[ -n "$BACKEND_DEV_DEPS" ]] && [[ "$BACKEND_DEV_DEPS" != "null" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
        merge_package_json_deps "$BACKEND_PATH/package.json" "$BACKEND_DEV_DEPS" "devDependencies"
    else
        print_info "Would add backend devDependencies: $BACKEND_DEV_DEPS"
    fi
fi

# Web dependencies
WEB_DEPS=$(json_get "$MODULE_CONFIG" '.dependencies.web')
WEB_DEV_DEPS=$(json_get "$MODULE_CONFIG" '.devDependencies.web')

if [[ -n "$WEB_DEPS" ]] && [[ "$WEB_DEPS" != "null" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
        merge_package_json_deps "$WEB_PATH/package.json" "$WEB_DEPS" "dependencies"
    else
        print_info "Would add web dependencies: $WEB_DEPS"
    fi
fi

if [[ -n "$WEB_DEV_DEPS" ]] && [[ "$WEB_DEV_DEPS" != "null" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
        merge_package_json_deps "$WEB_PATH/package.json" "$WEB_DEV_DEPS" "devDependencies"
    else
        print_info "Would add web devDependencies: $WEB_DEV_DEPS"
    fi
fi

print_success "Dependencies merged"

# Step 5: Add environment variables
print_step "Processing environment variables..."

ENV_VARS=$(json_get "$MODULE_CONFIG" '.env')

if [[ -n "$ENV_VARS" ]] && [[ "$ENV_VARS" != "null" ]] && [[ "$ENV_VARS" != "{}" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
        # Append to backend .env.example
        if [[ -f "$BACKEND_PATH/.env.example" ]]; then
            echo "" >> "$BACKEND_PATH/.env.example"
            echo "# $MODULE_DISPLAY_NAME Module" >> "$BACKEND_PATH/.env.example"

            if command -v jq &> /dev/null; then
                echo "$ENV_VARS" | jq -r 'to_entries[] | "\(.key)=\(.value)"' >> "$BACKEND_PATH/.env.example"
            else
                print_warning "jq not installed. Add environment variables manually."
                print_info "$ENV_VARS"
            fi
            print_info "Updated backend/.env.example"
        fi

        # Also add to .env if it exists
        if [[ -f "$BACKEND_PATH/.env" ]]; then
            echo "" >> "$BACKEND_PATH/.env"
            echo "# $MODULE_DISPLAY_NAME Module" >> "$BACKEND_PATH/.env"

            if command -v jq &> /dev/null; then
                echo "$ENV_VARS" | jq -r 'to_entries[] | "\(.key)=\(.value)"' >> "$BACKEND_PATH/.env"
            fi
            print_info "Updated backend/.env"
        fi
    else
        print_info "Would add environment variables: $ENV_VARS"
    fi

    print_success "Environment variables added"
else
    print_info "No environment variables to add"
fi

# Step 6: Show post-install instructions
POST_INSTALL=$(json_get "$MODULE_CONFIG" '.postInstall')
SETUP_DOCS=$(json_get "$MODULE_CONFIG" '.documentation')

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║${NC}                ${GREEN}${BOLD}Module installed successfully!${NC}                     ${GREEN}${BOLD}║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show required post-installation steps
if [[ -n "$POST_INSTALL" ]] && [[ "$POST_INSTALL" != "null" ]]; then
    echo -e "${BOLD}Post-Installation Steps:${NC}"
    echo ""

    if command -v jq &> /dev/null; then
        echo "$POST_INSTALL" | jq -r '.[]' 2>/dev/null | while IFS= read -r step; do
            echo -e "  ${CYAN}•${NC} $step"
        done
    else
        echo "$POST_INSTALL"
    fi
    echo ""
fi

# Standard next steps
echo -e "${BOLD}Next Steps:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Install new dependencies:"
echo -e "     ${DIM}npm install${NC}                    ${DIM}# In project root${NC}"
echo -e "     ${DIM}cd mobile && flutter pub get${NC}   ${DIM}# If mobile deps added${NC}"
echo ""
echo -e "  ${CYAN}2.${NC} Update environment variables:"
echo -e "     ${DIM}Edit backend/.env with your credentials${NC}"
echo ""
echo -e "  ${CYAN}3.${NC} Run database migrations (if schema changed):"
echo -e "     ${DIM}cd backend && npm run db:migrate:dev${NC}"
echo ""

if [[ -n "$SETUP_DOCS" ]] && [[ "$SETUP_DOCS" != "null" ]]; then
    echo -e "  ${CYAN}Documentation:${NC} $SETUP_DOCS"
    echo ""
fi

echo -e "${DIM}Module: $MODULE_NAME v$MODULE_VERSION${NC}"
echo ""
