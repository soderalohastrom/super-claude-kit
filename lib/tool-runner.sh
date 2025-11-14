#!/bin/bash
# Tool Runner - Universal tool execution framework
# Supports tools written in any language (Python, Node, Go, Ruby, etc.)

# Get the directory where this script is located
TOOL_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# When installed, this will be .claude/lib/tool-runner.sh
# So SCK_ROOT should be the project root (two levels up from .claude/lib)
SCK_ROOT="$(cd "$TOOL_RUNNER_DIR/../.." && pwd)"
CLAUDE_TOOLS_DIR="$SCK_ROOT/.claude/tools"
TOOLS_CACHE="$HOME/.claude/.tools_cache.json"

# Logging functions
log_tool() {
    echo "[tool-runner] $*" >&2
}

error_tool() {
    echo "[tool-runner ERROR] $*" >&2
}

# Discover all tools and cache metadata
discover_tools() {
    local tools_json="[]"

    # Find all tool.json files in .claude/tools (where they're installed)
    if [[ -d "$CLAUDE_TOOLS_DIR" ]]; then
        for tool_manifest in "$CLAUDE_TOOLS_DIR"/*/tool.json; do
            if [[ -f "$tool_manifest" ]]; then
                local tool_dir="$(dirname "$tool_manifest")"
                local tool_name="$(basename "$tool_dir")"

                # Read and validate tool.json
                if command -v jq >/dev/null 2>&1; then
                    local tool_meta=$(cat "$tool_manifest")
                    # Add tool_dir to metadata for execution
                    tool_meta=$(echo "$tool_meta" | jq --arg dir "$tool_dir" '. + {tool_dir: $dir}')
                    tools_json=$(echo "$tools_json" | jq --argjson tool "$tool_meta" '. += [$tool]')
                fi
            fi
        done
    fi

    # Save to cache
    echo "$tools_json" > "$TOOLS_CACHE"
    echo "$tools_json"
}

# Get tool metadata from cache
get_tool_metadata() {
    local tool_name="$1"

    # Refresh cache if missing or old (1 hour)
    if [[ ! -f "$TOOLS_CACHE" ]] || [[ $(find "$TOOLS_CACHE" -mmin +60 2>/dev/null) ]]; then
        discover_tools >/dev/null
    fi

    # Extract tool metadata
    if command -v jq >/dev/null 2>&1; then
        cat "$TOOLS_CACHE" | jq -r ".[] | select(.name == \"$tool_name\")"
    else
        error_tool "jq is required for tool metadata parsing"
        return 1
    fi
}

# Execute a tool with given parameters
# Usage: run_tool <tool_name> [params...]
run_tool() {
    local tool_name="$1"
    shift
    local tool_params=("$@")

    if [[ -z "$tool_name" ]]; then
        error_tool "Tool name is required"
        return 1
    fi

    # Get tool metadata
    local metadata=$(get_tool_metadata "$tool_name")
    if [[ -z "$metadata" ]]; then
        error_tool "Tool not found: $tool_name"
        error_tool "Available tools: $(list_tools)"
        return 1
    fi

    # Extract metadata fields
    local tool_type=$(echo "$metadata" | jq -r '.type // "bash"')
    local tool_entry=$(echo "$metadata" | jq -r '.entry')
    local tool_dir=$(echo "$metadata" | jq -r '.tool_dir')

    if [[ -z "$tool_entry" ]] || [[ "$tool_entry" == "null" ]]; then
        error_tool "Tool '$tool_name' has no entry point defined"
        return 1
    fi

    if [[ -z "$tool_dir" ]] || [[ "$tool_dir" == "null" ]]; then
        error_tool "Tool '$tool_name' has no directory defined"
        return 1
    fi

    # Execute based on tool type
    case "$tool_type" in
        bash)
            run_bash_tool "$tool_dir" "$tool_entry" "${tool_params[@]}"
            ;;
        python)
            run_python_tool "$tool_dir" "$tool_entry" "${tool_params[@]}"
            ;;
        node|javascript)
            run_node_tool "$tool_dir" "$tool_entry" "${tool_params[@]}"
            ;;
        go)
            run_go_tool "$tool_dir" "$tool_entry" "${tool_params[@]}"
            ;;
        binary)
            run_binary_tool "$tool_dir" "$tool_entry" "${tool_params[@]}"
            ;;
        *)
            error_tool "Unsupported tool type: $tool_type"
            return 1
            ;;
    esac
}

# Execute bash tool
run_bash_tool() {
    local tool_dir="$1"
    local entry="$2"
    shift 2

    local script_path="$tool_dir/$entry"
    if [[ ! -f "$script_path" ]]; then
        error_tool "Script not found: $script_path"
        return 1
    fi

    bash "$script_path" "$@"
}

# Execute Python tool
run_python_tool() {
    local tool_dir="$1"
    local entry="$2"
    shift 2

    local script_path="$tool_dir/$entry"
    if [[ ! -f "$script_path" ]]; then
        error_tool "Script not found: $script_path"
        return 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        error_tool "python3 is required for this tool"
        return 1
    fi

    python3 "$script_path" "$@"
}

# Execute Node.js tool
run_node_tool() {
    local tool_dir="$1"
    local entry="$2"
    shift 2

    local script_path="$tool_dir/$entry"
    if [[ ! -f "$script_path" ]]; then
        error_tool "Script not found: $script_path"
        return 1
    fi

    if ! command -v node >/dev/null 2>&1; then
        error_tool "node is required for this tool"
        return 1
    fi

    node "$script_path" "$@"
}

# Execute Go tool
run_go_tool() {
    local tool_dir="$1"
    local entry="$2"
    shift 2

    # For Go, entry is the main.go file or directory
    local go_path="$tool_dir/$entry"

    if ! command -v go >/dev/null 2>&1; then
        error_tool "go is required for this tool"
        return 1
    fi

    # Run with go run
    (cd "$tool_dir" && go run "$entry" "$@")
}

# Execute binary tool
run_binary_tool() {
    local tool_dir="$1"
    local entry="$2"
    shift 2

    local bin_path="$tool_dir/$entry"
    if [[ ! -f "$bin_path" ]]; then
        error_tool "Binary not found: $bin_path"
        return 1
    fi

    if [[ ! -x "$bin_path" ]]; then
        error_tool "Binary is not executable: $bin_path"
        return 1
    fi

    "$bin_path" "$@"
}

# List all available tools
list_tools() {
    if [[ ! -f "$TOOLS_CACHE" ]] || [[ $(find "$TOOLS_CACHE" -mmin +60 2>/dev/null) ]]; then
        discover_tools >/dev/null
    fi

    if command -v jq >/dev/null 2>&1; then
        cat "$TOOLS_CACHE" | jq -r '.[].name' | tr '\n' ', ' | sed 's/,$//'
    else
        echo "jq required"
    fi
}

# Show tool info
tool_info() {
    local tool_name="$1"

    if [[ -z "$tool_name" ]]; then
        error_tool "Tool name is required"
        return 1
    fi

    local metadata=$(get_tool_metadata "$tool_name")
    if [[ -z "$metadata" ]]; then
        error_tool "Tool not found: $tool_name"
        return 1
    fi

    echo "$metadata" | jq .
}

# Export functions for use in other scripts
export -f run_tool
export -f list_tools
export -f tool_info
export -f discover_tools
export -f get_tool_metadata
