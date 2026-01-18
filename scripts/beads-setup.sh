#!/usr/bin/env bash
#
# Beads Setup Helper for Ralph Supreme
# Checks for Beads installation and provides setup instructions
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Beads Setup Helper for Ralph Supreme${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check for bd command
check_beads() {
    if command -v bd &> /dev/null; then
        local version=$(bd --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Beads (bd) is installed${NC}"
        echo -e "  Version: $version"
        return 0
    else
        echo -e "${RED}✗ Beads (bd) is not installed${NC}"
        return 1
    fi
}

# Check for required dependencies
check_dependencies() {
    echo ""
    echo -e "${BLUE}Checking dependencies...${NC}"

    local all_ok=true

    # Node.js
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓ Node.js$(NC) $(node --version)"
    else
        echo -e "${YELLOW}! Node.js not found (required for npm install)${NC}"
        all_ok=false
    fi

    # npm
    if command -v npm &> /dev/null; then
        echo -e "${GREEN}✓ npm${NC} $(npm --version)"
    else
        echo -e "${YELLOW}! npm not found${NC}"
        all_ok=false
    fi

    # jq
    if command -v jq &> /dev/null; then
        echo -e "${GREEN}✓ jq${NC} $(jq --version)"
    else
        echo -e "${YELLOW}! jq not found (recommended for JSON parsing)${NC}"
    fi

    # git
    if command -v git &> /dev/null; then
        echo -e "${GREEN}✓ git${NC} $(git --version | head -1)"
    else
        echo -e "${RED}✗ git not found (required)${NC}"
        all_ok=false
    fi

    # claude
    if command -v claude &> /dev/null; then
        echo -e "${GREEN}✓ claude CLI${NC}"
    else
        echo -e "${RED}✗ claude CLI not found (required)${NC}"
        all_ok=false
    fi

    if [[ "$all_ok" == "false" ]]; then
        return 1
    fi
    return 0
}

# Show installation instructions
show_install_instructions() {
    echo ""
    echo -e "${BLUE}Installation Options:${NC}"
    echo ""
    echo -e "${CYAN}Option 1: npm (recommended)${NC}"
    echo "  npm install -g @anthropic/beads"
    echo ""
    echo -e "${CYAN}Option 2: Homebrew (macOS)${NC}"
    echo "  brew install steveyegge/beads/bd"
    echo ""
    echo -e "${CYAN}Option 3: Go${NC}"
    echo "  go install github.com/steveyegge/beads/cmd/bd@latest"
    echo ""
    echo -e "${CYAN}Option 4: Build from source${NC}"
    echo "  git clone https://github.com/steveyegge/beads"
    echo "  cd beads && make install"
    echo ""
}

# Initialize beads in current directory
init_beads_here() {
    if [[ -d ".beads" ]]; then
        echo -e "${YELLOW}Beads already initialized in this directory${NC}"
        bd status 2>/dev/null || true
        return 0
    fi

    echo -e "${BLUE}Initializing Beads in current directory...${NC}"
    bd init
    echo -e "${GREEN}✓ Beads initialized${NC}"
    echo ""
    echo "Created .beads/ directory for task tracking"
}

# Quick reference
show_quick_reference() {
    echo ""
    echo -e "${BLUE}Beads Quick Reference:${NC}"
    echo ""
    echo -e "${CYAN}Task Management:${NC}"
    echo "  bd create \"Task name\"              Create a new task"
    echo "  bd create \"Epic\" -t epic           Create an epic (container)"
    echo "  bd create \"Sub\" --parent bd-XXX    Create subtask"
    echo ""
    echo -e "${CYAN}Workflow:${NC}"
    echo "  bd ready                            Show unblocked tasks"
    echo "  bd start bd-XXX                     Start working on task"
    echo "  bd close bd-XXX                     Mark task complete"
    echo "  bd status                           Show all tasks"
    echo ""
    echo -e "${CYAN}Dependencies:${NC}"
    echo "  bd dep add bd-Y bd-X                Y waits for X"
    echo "  bd dep list bd-XXX                  Show task dependencies"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo "  bd comment bd-XXX \"note\"            Add context/decision"
    echo "  bd show bd-XXX                      Show task details"
    echo "  bd log                              Recent activity"
    echo ""
}

# Main
main() {
    local cmd="${1:-check}"

    case "$cmd" in
        check)
            if check_beads; then
                check_dependencies
                echo ""
                echo -e "${GREEN}Ready to use Ralph Supreme with Beads!${NC}"
            else
                show_install_instructions
                check_dependencies
            fi
            ;;
        install)
            echo -e "${BLUE}Attempting to install Beads via npm...${NC}"
            npm install -g @anthropic/beads
            check_beads
            ;;
        init)
            if ! check_beads; then
                echo -e "${RED}Please install Beads first${NC}"
                show_install_instructions
                exit 1
            fi
            init_beads_here
            ;;
        help|reference)
            show_quick_reference
            ;;
        *)
            echo "Usage: $0 [check|install|init|help]"
            echo ""
            echo "Commands:"
            echo "  check    - Check if Beads is installed (default)"
            echo "  install  - Attempt to install Beads via npm"
            echo "  init     - Initialize Beads in current directory"
            echo "  help     - Show Beads quick reference"
            exit 1
            ;;
    esac
}

main "$@"
