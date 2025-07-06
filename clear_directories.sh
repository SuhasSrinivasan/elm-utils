#!/bin/bash

# Configuration variables
PARENT_DIR="/oak/stanford/groups/<groupname>/users"         # Replace with your parent directory path
INPUT_FILE="clear_directories_list.txt"                     # File containing list of subdirectories

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Check if parent directory exists
if [ ! -d "$PARENT_DIR" ]; then
    echo "Error: Parent directory '$PARENT_DIR' not found."
    exit 1
fi

# Count non-empty lines for accurate progress reporting
TOTAL_DIRS=$(grep -c -v '^[[:space:]]*$' "$INPUT_FILE")
CURRENT=0

# Explicitly open the file for reading
echo "Reading directory list from '$INPUT_FILE'..."
echo "----------------------------------------"

# Process each subdirectory
# This explicitly loads the file into an array for more sequential processing
mapfile -t SUBDIRS < "$INPUT_FILE"

for subdir in "${SUBDIRS[@]}"; do
    # Skip empty lines
    if [ -z "$subdir" ]; then
        continue
    fi

    # Increment counter
    ((CURRENT++))

    # Construct full path
    FULL_PATH="${PARENT_DIR}/${subdir}"

    # Check if directory exists
    if [ ! -d "$FULL_PATH" ]; then
        echo "[$CURRENT/$TOTAL_DIRS] Warning: Directory '$FULL_PATH' does not exist. Skipping."
        continue
    fi

    # Check if directory is already empty
    if [ -z "$(ls -A "$FULL_PATH")" ]; then
        echo "[$CURRENT/$TOTAL_DIRS] Directory already empty: $FULL_PATH"
        continue
    fi

    echo "[$CURRENT/$TOTAL_DIRS] Clearing contents of: $FULL_PATH"

    # Delete all contents but keep the directory itself
    find "$FULL_PATH" -mindepth 1 -delete

    echo "[$CURRENT/$TOTAL_DIRS] Cleared: $FULL_PATH"

done

echo "----------------------------------------"
echo "Operation completed. Cleared contents of $CURRENT directories."
