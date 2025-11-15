#!/usr/bin/env bash
# Dependency graph parser - parses JSON format dependency graphs
# Provides efficient querying functions for bash scripts

set -eo pipefail

# Resolve relative path to absolute path
_resolve_path() {
    local input_path="$1"
    local cwd="${2:-$(pwd)}"

    # If already absolute, return as-is
    if [[ "$input_path" == /* ]]; then
        echo "$input_path"
        return 0
    fi

    # Resolve relative path
    local resolved="$cwd/$input_path"
    # Normalize the path (remove ./ and resolve ../)
    python3 -c "import os; print(os.path.normpath('$resolved'))"
}

# Find file in graph (supports both absolute and relative paths)
_find_file_in_graph() {
    local graph_file="$1"
    local target_file="$2"

    if [ ! -f "$graph_file" ]; then
        return 1
    fi

    # Try as-is first (absolute path)
    if python3 -c "import json,sys; d=json.load(open('$graph_file')); sys.exit(0 if '$target_file' in d.get('Files', {}) else 1)" 2>/dev/null; then
        echo "$target_file"
        return 0
    fi

    # Try resolving as relative path
    local abs_path=$(_resolve_path "$target_file")
    if python3 -c "import json,sys; d=json.load(open('$graph_file')); sys.exit(0 if '$abs_path' in d.get('Files', {}) else 1)" 2>/dev/null; then
        echo "$abs_path"
        return 0
    fi

    # Search for partial matches (filename only)
    local matches=$(python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    target = '$target_file'
    matches = [p for p in data.get('Files', {}).keys() if p.endswith('/' + target) or p.endswith(target)]
    if matches:
        print(matches[0])  # Return first match
" 2>/dev/null)

    if [ -n "$matches" ]; then
        echo "$matches"
        return 0
    fi

    return 1
}

toon_get_file_info() {
    local graph_file="$1"
    local target_file="$2"

    if [ ! -f "$graph_file" ]; then
        return 1
    fi

    local resolved_file=$(_find_file_in_graph "$graph_file" "$target_file")
    if [ $? -ne 0 ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    file_data = data.get('Files', {}).get('$resolved_file', {})
    if file_data:
        print('FILE:$resolved_file')
        print('LANG:' + file_data.get('Language', 'unknown'))

        imports = file_data.get('Imports', [])
        if imports:
            import_paths = ','.join([imp.get('Path', '') for imp in imports if imp.get('Path')])
            if import_paths:
                print('IMPORTS:' + import_paths)

        exports = file_data.get('Exports', [])
        if exports:
            export_names = ','.join([exp.get('Name', '') for exp in exports if exp.get('Name')])
            if export_names:
                print('EXPORTS:' + export_names)

        imported_by = file_data.get('ImportedBy', [])
        if imported_by:
            print('IMPORTEDBY:' + ','.join(imported_by))
    else:
        exit(1)
" 2>/dev/null
}

toon_get_imports() {
    local graph_file="$1"
    local target_file="$2"

    local resolved_file=$(_find_file_in_graph "$graph_file" "$target_file")
    if [ $? -ne 0 ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    file_data = data.get('Files', {}).get('$resolved_file', {})
    imports = file_data.get('Imports', [])
    for imp in imports:
        path = imp.get('Path', '')
        line = imp.get('Line', 0)
        if path:
            print(f'{path}:{line}')
" 2>/dev/null
}

toon_get_exports() {
    local graph_file="$1"
    local target_file="$2"

    local resolved_file=$(_find_file_in_graph "$graph_file" "$target_file")
    if [ $? -ne 0 ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    file_data = data.get('Files', {}).get('$resolved_file', {})
    exports = file_data.get('Exports', [])
    for exp in exports:
        name = exp.get('Name', '')
        exp_type = exp.get('Type', '')
        if name:
            print(f'{name} ({exp_type})')
" 2>/dev/null
}

toon_get_importers() {
    local graph_file="$1"
    local target_file="$2"

    local resolved_file=$(_find_file_in_graph "$graph_file" "$target_file")
    if [ $? -ne 0 ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    file_data = data.get('Files', {}).get('$resolved_file', {})
    imported_by = file_data.get('ImportedBy', [])
    for importer in imported_by:
        print(importer)
" 2>/dev/null
}

toon_get_language() {
    local graph_file="$1"
    local target_file="$2"

    local resolved_file=$(_find_file_in_graph "$graph_file" "$target_file")
    if [ $? -ne 0 ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    file_data = data.get('Files', {}).get('$resolved_file', {})
    print(file_data.get('Language', 'unknown'))
" 2>/dev/null
}

toon_count_importers() {
    local graph_file="$1"
    local target_file="$2"

    toon_get_importers "$graph_file" "$target_file" | wc -l | tr -d ' '
}

toon_file_exists() {
    local graph_file="$1"
    local target_file="$2"

    _find_file_in_graph "$graph_file" "$target_file" >/dev/null 2>&1
}

toon_list_files() {
    local graph_file="$1"

    if [ ! -f "$graph_file" ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    for path in data.get('Files', {}).keys():
        print(path)
" 2>/dev/null
}

toon_get_circular() {
    local graph_file="$1"

    if [ ! -f "$graph_file" ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    circular = data.get('CircularDependencies', [])
    for cycle in circular:
        if isinstance(cycle, list):
            print(' -> '.join(cycle))
        else:
            print(cycle)
" 2>/dev/null
}

toon_get_deadcode() {
    local graph_file="$1"

    if [ ! -f "$graph_file" ]; then
        return 1
    fi

    python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    for path, file_data in data.get('Files', {}).items():
        imported_by = file_data.get('ImportedBy', [])
        if not imported_by or len(imported_by) == 0:
            print(path)
" 2>/dev/null
}

toon_count_files() {
    local graph_file="$1"

    toon_list_files "$graph_file" | wc -l | tr -d ' '
}

toon_get_meta() {
    local graph_file="$1"
    local key="${2:-}"

    if [ ! -f "$graph_file" ]; then
        return 1
    fi

    if [ -z "$key" ]; then
        python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    meta = data.get('Metadata', {})
    for k, v in meta.items():
        print(f'{k}={v}')
" 2>/dev/null
    else
        python3 -c "
import json
with open('$graph_file') as f:
    data = json.load(f)
    meta = data.get('Metadata', {})
    print(meta.get('$key', ''))
" 2>/dev/null
    fi
}

toon_search_files() {
    local graph_file="$1"
    local pattern="$2"

    toon_list_files "$graph_file" | grep "$pattern" || true
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f _resolve_path
    export -f _find_file_in_graph
    export -f toon_get_file_info
    export -f toon_get_imports
    export -f toon_get_exports
    export -f toon_get_importers
    export -f toon_get_language
    export -f toon_count_importers
    export -f toon_file_exists
    export -f toon_list_files
    export -f toon_get_circular
    export -f toon_get_deadcode
    export -f toon_count_files
    export -f toon_get_meta
    export -f toon_search_files
fi
