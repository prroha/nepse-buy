#!/usr/bin/env bash
#
# list-modules.sh - List available modules for fullstack-starter
#
# Usage:
#   ./scripts/list-modules.sh [options]
#
# Examples:
#   ./scripts/list-modules.sh
#   ./scripts/list-modules.sh --json
#   ./scripts/list-modules.sh --tier premium
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

# Tier colors
TIER_FREE="${GREEN}"
TIER_STANDARD="${BLUE}"
TIER_PREMIUM="${MAGENTA}"
TIER_ENTERPRISE="${YELLOW}"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}            ${CYAN}${BOLD}Fullstack Starter - Available Modules${NC}                ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Parse JSON value
json_get() {
    local json="$1"
    local key="$2"

    if command -v jq &> /dev/null; then
        echo "$json" | jq -r "$key // empty"
    else
        echo "$json" | grep -oP "\"${key#.}\"\s*:\s*\"\K[^\"]*" 2>/dev/null | head -1 || echo ""
    fi
}

format_price() {
    local price="$1"
    local tier="$2"

    if [[ "$price" == "0" ]] || [[ "$price" == "free" ]] || [[ -z "$price" ]]; then
        echo -e "${GREEN}Free${NC}"
    elif [[ "$price" == "included" ]]; then
        echo -e "${DIM}Included${NC}"
    else
        case "$tier" in
            standard)
                echo -e "${BLUE}\$$price${NC}"
                ;;
            premium)
                echo -e "${MAGENTA}\$$price${NC}"
                ;;
            enterprise)
                echo -e "${YELLOW}\$$price${NC}"
                ;;
            *)
                echo -e "\$$price"
                ;;
        esac
    fi
}

get_tier_badge() {
    local tier="$1"

    case "$tier" in
        free|basic)
            echo -e "${GREEN}[FREE]${NC}"
            ;;
        standard)
            echo -e "${BLUE}[STANDARD]${NC}"
            ;;
        premium)
            echo -e "${MAGENTA}[PREMIUM]${NC}"
            ;;
        enterprise)
            echo -e "${YELLOW}[ENTERPRISE]${NC}"
            ;;
        *)
            echo -e "${DIM}[$tier]${NC}"
            ;;
    esac
}

get_platform_icons() {
    local platforms="$1"
    local icons=""

    if [[ "$platforms" == *"backend"* ]]; then
        icons+=" B"
    fi
    if [[ "$platforms" == *"web"* ]]; then
        icons+=" W"
    fi
    if [[ "$platforms" == *"mobile"* ]]; then
        icons+=" M"
    fi

    echo "$icons"
}

# ============================================================================
# USAGE
# ============================================================================

usage() {
    cat << EOF
${BOLD}Usage:${NC}
    $(basename "$0") [options]

${BOLD}Options:${NC}
    --json          Output in JSON format
    --tier <tier>   Filter by tier (free, standard, premium, enterprise)
    --category <c>  Filter by category
    -h, --help      Show this help message

${BOLD}Tier Descriptions:${NC}
    ${GREEN}free${NC}        Core modules included with the starter
    ${BLUE}standard${NC}    Essential add-ons for most projects
    ${MAGENTA}premium${NC}     Advanced features for production apps
    ${YELLOW}enterprise${NC}  Full-featured modules for large-scale apps

${BOLD}Examples:${NC}
    $(basename "$0")
    $(basename "$0") --tier premium
    $(basename "$0") --json

EOF
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

OUTPUT_JSON=false
FILTER_TIER=""
FILTER_CATEGORY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --tier)
            [[ -z "${2:-}" ]] && { echo "Missing value for --tier"; exit 1; }
            FILTER_TIER="$2"
            shift 2
            ;;
        --category)
            [[ -z "${2:-}" ]] && { echo "Missing value for --category"; exit 1; }
            FILTER_CATEGORY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# ============================================================================
# FIND MODULES DIRECTORY
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$(dirname "$SCRIPT_DIR")/modules"

if [[ ! -d "$MODULES_DIR" ]]; then
    echo -e "${YELLOW}No modules directory found.${NC}"
    echo ""
    echo "Modules should be placed in: $MODULES_DIR"
    echo ""
    echo "Each module should have a module.json file with configuration."
    exit 0
fi

# ============================================================================
# COLLECT MODULE DATA
# ============================================================================

declare -a MODULE_DATA=()
declare -A MODULES_BY_TIER
MODULES_BY_TIER[free]=""
MODULES_BY_TIER[standard]=""
MODULES_BY_TIER[premium]=""
MODULES_BY_TIER[enterprise]=""

for module_dir in "$MODULES_DIR"/*/; do
    [[ -d "$module_dir" ]] || continue

    module_name=$(basename "$module_dir")
    module_json="$module_dir/module.json"

    if [[ ! -f "$module_json" ]]; then
        continue
    fi

    config=$(cat "$module_json")

    name=$(json_get "$config" '.name')
    version=$(json_get "$config" '.version')
    description=$(json_get "$config" '.description')
    tier=$(json_get "$config" '.tier')
    price=$(json_get "$config" '.price')
    category=$(json_get "$config" '.category')
    platforms=$(json_get "$config" '.platforms')

    [[ -z "$name" ]] && name="$module_name"
    [[ -z "$version" ]] && version="1.0.0"
    [[ -z "$tier" ]] && tier="free"
    [[ -z "$price" ]] && price="0"
    [[ -z "$platforms" ]] && platforms="backend,web,mobile"

    # Apply filters
    if [[ -n "$FILTER_TIER" ]] && [[ "$tier" != "$FILTER_TIER" ]]; then
        continue
    fi

    if [[ -n "$FILTER_CATEGORY" ]] && [[ "$category" != "$FILTER_CATEGORY" ]]; then
        continue
    fi

    # Store module data
    MODULE_DATA+=("$module_name|$name|$version|$description|$tier|$price|$category|$platforms")

    # Group by tier
    if [[ -n "${MODULES_BY_TIER[$tier]:-}" ]]; then
        MODULES_BY_TIER[$tier]="${MODULES_BY_TIER[$tier]},$module_name"
    else
        MODULES_BY_TIER[$tier]="$module_name"
    fi
done

# ============================================================================
# OUTPUT
# ============================================================================

if [[ "$OUTPUT_JSON" == true ]]; then
    # JSON output
    echo "{"
    echo '  "modules": ['

    first=true
    for data in "${MODULE_DATA[@]}"; do
        IFS='|' read -r id name version description tier price category platforms <<< "$data"

        [[ "$first" == true ]] || echo ","
        first=false

        cat << EOF
    {
      "id": "$id",
      "name": "$name",
      "version": "$version",
      "description": "$description",
      "tier": "$tier",
      "price": "$price",
      "category": "$category",
      "platforms": "$platforms"
    }
EOF
    done

    echo ""
    echo "  ],"

    # Tier presets
    cat << EOF
  "tierPresets": {
    "basic": [],
    "standard": ["email", "file-upload"],
    "premium": ["email", "file-upload", "payments", "analytics"],
    "enterprise": ["email", "file-upload", "payments", "analytics", "push-notifications", "social-auth", "admin-dashboard", "audit-log"]
  }
}
EOF

else
    # Pretty output
    print_header

    if [[ ${#MODULE_DATA[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No modules found.${NC}"
        echo ""
        echo "Create modules in: $MODULES_DIR"
        echo ""
        echo "Each module needs a module.json file. Example:"
        echo ""
        cat << 'EOF'
{
  "name": "Email",
  "version": "1.0.0",
  "description": "Email sending with templates",
  "tier": "standard",
  "price": "19",
  "category": "communication",
  "platforms": "backend,web"
}
EOF
        echo ""
        exit 0
    fi

    # Print legend
    echo -e "${BOLD}Platform Legend:${NC} ${DIM}B${NC}=Backend  ${DIM}W${NC}=Web  ${DIM}M${NC}=Mobile"
    echo ""

    # Print tier presets
    echo -e "${BOLD}Tier Presets:${NC}"
    echo -e "  ${GREEN}basic${NC}       Core only (free)"
    echo -e "  ${BLUE}standard${NC}    Core + email + file-upload"
    echo -e "  ${MAGENTA}premium${NC}     Core + email + file-upload + payments + analytics"
    echo -e "  ${YELLOW}enterprise${NC}  All modules"
    echo ""

    # Print modules table
    echo -e "${BOLD}Available Modules:${NC}"
    echo ""

    # Header
    printf "  ${DIM}%-20s %-8s %-35s %s${NC}\n" "MODULE" "TIER" "DESCRIPTION" "PRICE"
    printf "  ${DIM}%-20s %-8s %-35s %s${NC}\n" "────────────────────" "────────" "───────────────────────────────────" "─────────"

    # Sort by tier order: free, standard, premium, enterprise
    for tier_order in free standard premium enterprise; do
        for data in "${MODULE_DATA[@]}"; do
            IFS='|' read -r id name version description tier price category platforms <<< "$data"

            [[ "$tier" != "$tier_order" ]] && continue

            # Truncate description if too long
            if [[ ${#description} -gt 33 ]]; then
                description="${description:0:30}..."
            fi

            # Get tier color
            case "$tier" in
                free|basic) tier_color="${GREEN}" ;;
                standard) tier_color="${BLUE}" ;;
                premium) tier_color="${MAGENTA}" ;;
                enterprise) tier_color="${YELLOW}" ;;
                *) tier_color="${NC}" ;;
            esac

            # Format price
            if [[ "$price" == "0" ]] || [[ -z "$price" ]]; then
                price_display="${GREEN}Free${NC}"
            else
                price_display="\$${price}"
            fi

            # Get platform icons
            platform_icons=$(get_platform_icons "$platforms")

            printf "  ${CYAN}%-20s${NC} ${tier_color}%-8s${NC} %-35s %s ${DIM}[%s]${NC}\n" \
                "$id" "$tier" "$description" "$price_display" "$platform_icons"
        done
    done

    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${DIM}./scripts/install-module.sh <module-name>${NC}    Install a module"
    echo -e "  ${DIM}./scripts/create-project.sh my-app --tier premium${NC}    Create project with tier"
    echo ""

    echo -e "${BOLD}Installation Example:${NC}"
    echo -e "  ${DIM}./scripts/install-module.sh email${NC}"
    echo -e "  ${DIM}./scripts/install-module.sh payments --dry-run${NC}"
    echo ""

    echo -e "${DIM}Total modules: ${#MODULE_DATA[@]}${NC}"
    echo ""
fi
