#!/usr/bin/env bash

# ==============================================================================
#  embedded readme / documentation
# ==============================================================================
read -r -d '' README_TEXT << 'EOF'
================================================================================
 🔍 LARGE FOLDER EXPLORER & JS LIBRARY CLEANER
================================================================================

DESCRIPTION:
  A smart interactive Bash script to locate unknown large directories (default >10MB)
  and identify potential JavaScript library/dependency folders based on internal
  file signatures (e.g., package.json, node_modules, or multiple .js files).

USAGE:
  ./find_large_js_dirs.sh [TARGET_DIR] [MIN_SIZE] [FLAGS]

ARGUMENTS:
  TARGET_DIR   The root directory to start scanning. (Default: ".")
  MIN_SIZE     Minimum size threshold for folders using 'du' units like 10M, 100M, 1G.
               (Default: "10M")

FLAGS:
  -h, --help   Show this README documentation and exit.

EXAMPLES:
  # Scan current directory for folders larger than 10MB
  ./find_large_js_dirs.sh

  # Scan ~/Projects for folders larger than 50MB
  ./find_large_js_dirs.sh ~/Projects 50M

  # View this README directly
  ./find_large_js_dirs.sh --help

================================================================================
EOF

# Handle --help / -h flags
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "$README_TEXT"
    exit 0
fi

# ==============================================================================
#  configuration & arguments
# ==============================================================================
TARGET_DIR="${1:-.}"
MIN_SIZE="${2:-10M}"

echo "$README_TEXT"
echo " Target Directory: ${TARGET_DIR}"
echo " Minimum Size:     ${MIN_SIZE}"
echo "================================================================================"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# ==============================================================================
#  [1/3] scanning for large folders
# ==============================================================================
echo -e "\n[1/3] Scanning for directories larger than ${MIN_SIZE}..."
echo "This might take a few moments depending on your disk speed..."

# Temporary file to store discovered paths and metadata
TMP_LIST=$(mktemp)

# Scan max 3 levels deep for large folders to prevent endless traversal
du -h -d 3 "$TARGET_DIR" 2>/dev/null | sort -rh > "$TMP_LIST.raw"

if [ ! -s "$TMP_LIST.raw" ]; then
    echo "No folders found matching the criteria."
    rm -f "$TMP_LIST.raw" "$TMP_LIST"
    exit 0
fi

# ==============================================================================
#  [2/3] js signature detection & display
# ==============================================================================
echo -e "\n[2/3] Top Large Folders & JS Detection Status:"
echo "--------------------------------------------------------------------------------"
printf "%-5s | %-8s | %-20s | %s\n" "Index" "Size" "Possible Type" "Path"
echo "--------------------------------------------------------------------------------"

index=1
while read -r size path; do
    # Skip target root directory itself
    if [[ "$path" == "$TARGET_DIR" || "$path" == "$TARGET_DIR/" ]]; then 
        continue 
    fi

    # Heuristic detection for JS libraries / build outputs
    JS_HINT="[ Unknown ]"
    if [ -f "$path/package.json" ]; then
        JS_HINT="[ JS Root/Pkg ]"
    elif [ -d "$path/node_modules" ]; then
        JS_HINT="[ Contains Modules ]"
    elif [ -d "$path/bower_components" ]; then
        JS_HINT="[ Bower Library ]"
    elif [ $(find "$path" -maxdepth 2 -name "*.js" 2>/dev/null | wc -l) -gt 5 ]; then
        JS_HINT="[ Contains JS ]"
    fi

    printf "[%2d]  | %-8s | %-20s | %s\n" "$index" "$size" "$JS_HINT" "$path"
    echo "$path" >> "$TMP_LIST"
    ((index++))

    # Cap display to top 25 largest folders to keep UI clean
    if [ $index -gt 25 ]; then
        break
    fi
done < "$TMP_LIST.raw"

rm -f "$TMP_LIST.raw"

echo "--------------------------------------------------------------------------------"

# ==============================================================================
#  [3/3] interactive selection & cleanup
# ==============================================================================
echo -e "\n[3/3] Interactive Cleanup Options:"
echo "  - Enter item numbers separated by spaces to delete (e.g., '1 3 4')"
echo "  - Type 'q' or press Enter to exit safely"
echo "--------------------------------------------------------------------------------"

read -p "Select folders to delete: " CHOICES

if [[ -z "$CHOICES" || "$CHOICES" =~ ^[Qq]$ ]]; then
    echo "No folders were deleted. Exiting safely..."
    rm -f "$TMP_LIST"
    exit 0
fi

echo -e "\n⚠️  Confirming Deletion for Selected Directories:"
SELECTED_PATHS=()
for num in $CHOICES; do
    if [[ "$num" =~ ^[0-9]+$ ]]; then
        TARGET_PATH=$(sed -n "${num}p" "$TMP_LIST")
        if [ -n "$TARGET_PATH" ]; then
            echo "  - [$num] $TARGET_PATH"
            SELECTED_PATHS+=("$TARGET_PATH")
        fi
    fi
done

if [ ${#SELECTED_PATHS[@]} -eq 0 ]; then
    echo "Invalid selection. Exiting..."
    rm -f "$TMP_LIST"
    exit 1
fi

echo ""
read -p "PERMANENTLY delete these folders? (y/N): " FINAL_CONFIRM

if [[ "$FINAL_CONFIRM" =~ ^[Yy]$ ]]; then
    for path in "${SELECTED_PATHS[@]}"; do
        echo "Deleting: $path ..."
        rm -rf "$path"
    done
    echo -e "\n✨ Selected folders deleted successfully!"
else
    echo "Operation cancelled. No files were removed."
fi

rm -f "$TMP_LIST"
