#!/bin/bash
# install.sh — Install vladyslav-skills
# Adds bin/ to PATH and prints plugin setup instructions.

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"
SHELL_RC="${HOME}/.zshrc"

echo ""
echo -e "${BOLD}Installing vladyslav-skills${RESET}"
echo ""

# Make bin scripts executable
chmod +x "${BIN_DIR}"/vd-*
echo -e "${GREEN}✓${RESET} Made bin scripts executable"

# Add to PATH if not already there
if grep -q "vladyslav-skills/bin" "$SHELL_RC" 2>/dev/null; then
  echo -e "${GREEN}✓${RESET} PATH already configured in ${SHELL_RC}"
else
  echo "" >> "$SHELL_RC"
  echo "# vladyslav-skills" >> "$SHELL_RC"
  echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "$SHELL_RC"
  echo -e "${GREEN}✓${RESET} Added bin/ to PATH in ${SHELL_RC}"
fi

echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo ""
echo "  1. Reload shell:"
echo -e "     ${CYAN}source ${SHELL_RC}${RESET}"
echo ""
echo "  2. Install the Claude Code plugin:"
echo -e "     ${CYAN}claude${RESET}"
echo "     Then run: /plugin install vladyslav from ${SCRIPT_DIR}"
echo ""
echo "  3. Verify:"
echo -e "     ${CYAN}vd-help${RESET}"
echo ""
echo -e "${BOLD}Available commands:${RESET}"
echo "  vd-init      Create new project          (Sonnet)"
echo "  vd-attach    Attach to existing project   (Sonnet)"
echo "  vd-analyze   Analyze codebase             (Opus)"
echo "  vd-feature   Add feature                  (Opus)"
echo "  vd-fix       Fix bug (full cycle)         (Opus)"
echo "  vd-stories   Update user stories          (Sonnet)"
echo "  vd-tests     Test documentation           (Sonnet)"
echo "  vd-docs      Human documentation          (Sonnet)"
echo "  vd-release   Pre-release check            (Sonnet)"
echo "  vd-help      Show help                    (Sonnet)"
echo ""
