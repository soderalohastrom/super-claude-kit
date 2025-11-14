#!/usr/bin/env bash
# Super Claude Kit v2.0.0 - Sandbox Permission Validator
# Validates tool permissions before execution

set -euo pipefail

# Permission validation function
validate_permissions() {
    local tool_name="$1"
    local tool_metadata="$2"
    local operation="${3:-}"  # read, write, network, execute
    local target_path="${4:-}"  # Path to validate (if applicable)

    # Extract permissions from metadata
    local read_paths=$(echo "$tool_metadata" | jq -r '.permissions.read // [] | .[]' 2>/dev/null || echo "")
    local write_paths=$(echo "$tool_metadata" | jq -r '.permissions.write // [] | .[]' 2>/dev/null || echo "")
    local network_allowed=$(echo "$tool_metadata" | jq -r '.permissions.network // false' 2>/dev/null || echo "false")

    case "$operation" in
        read)
            validate_read_permission "$tool_name" "$read_paths" "$target_path"
            ;;
        write)
            validate_write_permission "$tool_name" "$write_paths" "$target_path"
            ;;
        network)
            validate_network_permission "$tool_name" "$network_allowed"
            ;;
        *)
            return 0  # Unknown operation, allow by default
            ;;
    esac
}

# Validate read permission
validate_read_permission() {
    local tool_name="$1"
    local allowed_paths="$2"
    local target_path="$3"

    # If no target path, skip validation
    if [ -z "$target_path" ]; then
        return 0
    fi

    # Expand target path to absolute
    if [ -e "$target_path" ]; then
        target_path=$(cd "$(dirname "$target_path")" && pwd)/$(basename "$target_path")
    else
        # Path doesn't exist yet, try to resolve relative to pwd
        target_path="$(pwd)/$target_path"
    fi

    # Check against blacklist first (highest priority)
    if is_blacklisted_path "$target_path"; then
        echo "❌ PERMISSION DENIED: $tool_name cannot read sensitive path: $target_path" >&2
        return 1
    fi

    # If allowed_paths is empty, default to project directory only
    if [ -z "$allowed_paths" ]; then
        if is_within_project "$target_path"; then
            return 0
        else
            echo "❌ PERMISSION DENIED: $tool_name can only read project files by default" >&2
            return 1
        fi
    fi

    # Check if target matches any allowed path pattern
    while IFS= read -r allowed_pattern; do
        if path_matches_pattern "$target_path" "$allowed_pattern"; then
            return 0
        fi
    done <<< "$allowed_paths"

    echo "❌ PERMISSION DENIED: $tool_name not allowed to read: $target_path" >&2
    return 1
}

# Validate write permission
validate_write_permission() {
    local tool_name="$1"
    local allowed_paths="$2"
    local target_path="$3"

    # If no target path, skip validation
    if [ -z "$target_path" ]; then
        return 0
    fi

    # Expand target path to absolute
    if [ -e "$target_path" ]; then
        target_path=$(cd "$(dirname "$target_path")" && pwd)/$(basename "$target_path")
    else
        # Path doesn't exist yet, try to resolve relative to pwd
        target_path="$(pwd)/$target_path"
    fi

    # Check against blacklist (critical for writes)
    if is_blacklisted_path "$target_path"; then
        echo "❌ PERMISSION DENIED: $tool_name cannot write to sensitive path: $target_path" >&2
        return 1
    fi

    # If allowed_paths is empty, deny write by default (safer)
    if [ -z "$allowed_paths" ]; then
        echo "❌ PERMISSION DENIED: $tool_name has no write permissions" >&2
        return 1
    fi

    # Check if target matches any allowed path pattern
    while IFS= read -r allowed_pattern; do
        if path_matches_pattern "$target_path" "$allowed_pattern"; then
            return 0
        fi
    done <<< "$allowed_paths"

    echo "❌ PERMISSION DENIED: $tool_name not allowed to write: $target_path" >&2
    return 1
}

# Validate network permission
validate_network_permission() {
    local tool_name="$1"
    local network_allowed="$2"

    if [ "$network_allowed" = "true" ]; then
        return 0
    else
        echo "❌ PERMISSION DENIED: $tool_name not allowed network access" >&2
        return 1
    fi
}

# Check if path is blacklisted
is_blacklisted_path() {
    local path="$1"

    # Sensitive system paths
    local blacklist=(
        "$HOME/.ssh"
        "$HOME/.aws"
        "$HOME/.config/gcloud"
        "$HOME/.kube"
        "/etc/passwd"
        "/etc/shadow"
        "/etc/hosts"
    )

    # Sensitive file patterns
    local sensitive_patterns=(
        ".env"
        ".env.local"
        ".env.production"
        "credentials.json"
        "serviceAccount.json"
        "id_rsa"
        "id_ed25519"
        ".pem"
        ".key"
    )

    # Check blacklist paths
    for blacklisted in "${blacklist[@]}"; do
        if [[ "$path" == "$blacklisted"* ]]; then
            return 0  # Is blacklisted
        fi
    done

    # Check sensitive file patterns
    for pattern in "${sensitive_patterns[@]}"; do
        if [[ "$path" == *"$pattern"* ]]; then
            return 0  # Is blacklisted
        fi
    done

    return 1  # Not blacklisted
}

# Check if path is within project directory
is_within_project() {
    local path="$1"
    local project_root="$(pwd)"

    if [[ "$path" == "$project_root"* ]]; then
        return 0
    else
        return 1
    fi
}

# Check if path matches pattern (supports wildcards)
path_matches_pattern() {
    local path="$1"
    local pattern="$2"

    # Expand ~ to $HOME
    pattern="${pattern/#\~/$HOME}"

    # Convert pattern to regex (order matters!)
    # First, replace ** with a placeholder to avoid conflicts
    pattern="${pattern//\*\*/__DOUBLESTAR__}"
    # Replace single * with [^/]* (matches anything except /)
    pattern="${pattern//\*/[^/]*}"
    # Replace placeholder with .* (matches anything including /)
    pattern="${pattern//__DOUBLESTAR__/.*}"

    # Check if path matches pattern
    if [[ "$path" =~ ^${pattern}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f validate_permissions
    export -f validate_read_permission
    export -f validate_write_permission
    export -f validate_network_permission
    export -f is_blacklisted_path
    export -f is_within_project
    export -f path_matches_pattern
fi
