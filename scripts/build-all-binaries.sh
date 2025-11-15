#!/bin/bash
# Build all tool binaries for all platforms
# Usage: ./scripts/build-all-binaries.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Building All Tool Binaries"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$ROOT_DIR"

# Track success/failure
TOTAL_TOOLS=0
SUCCESS_TOOLS=0
FAILED_TOOLS=()

# Find all tools with Makefiles
for tool_dir in tools/*/; do
  if [ -f "${tool_dir}Makefile" ]; then
    TOOL_NAME=$(basename "$tool_dir")
    TOTAL_TOOLS=$((TOTAL_TOOLS + 1))

    echo "📦 Building: $TOOL_NAME"
    echo "   Location: $tool_dir"

    # Build the tool (source only, users build locally)
    # We only verify the source can build, not create platform-specific binaries
    if (cd "$tool_dir" && make clean > /dev/null 2>&1 && make build); then
      SUCCESS_TOOLS=$((SUCCESS_TOOLS + 1))
      echo "   ✅ Source builds successfully"
    else
      FAILED_TOOLS+=("$TOOL_NAME")
      echo "   ❌ Failed to build"
    fi
    echo ""
  fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Build Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total tools: $TOTAL_TOOLS"
echo "✅ Successful: $SUCCESS_TOOLS"
echo "❌ Failed: ${#FAILED_TOOLS[@]}"
echo ""

if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
  echo "Failed tools:"
  for tool in "${FAILED_TOOLS[@]}"; do
    echo "  - $tool"
  done
  echo ""
  exit 1
fi

echo "✅ All binaries built successfully!"
