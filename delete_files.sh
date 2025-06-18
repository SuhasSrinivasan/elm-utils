!/bin/bash

# File Deletion Script
# Takes a list of file paths and attempts to delete each file
# WARNING: This script will attempt to delete all file types including special files

# Check if correct number of arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 path_list_file"
    exit 1
fi

PATHS_FILE="$1"

# Check if input file exists
if [ ! -f "$PATHS_FILE" ]; then
    echo "Error: Input file '$PATHS_FILE' not found."
    exit 2
fi

# Initialize counters
TOTAL=0
SUCCESS=0
REGULAR_SUCCESS=0
SPECIAL_SUCCESS=0
FAILED=0
NOT_FOUND=0
PERMISSION_DENIED=0

# Create a log file for operations
LOG_FILE="file_deletion_$(date +%Y%m%d_%H%M%S).log"
echo "File Deletion Log - $(date)" > "$LOG_FILE"

echo "Starting file deletion process..."
echo "WARNING: This script will attempt to delete all file types including special files"
echo "Detailed log will be saved to '$LOG_FILE'"

# Process each path in the file
while IFS= read -r filepath; do
    ((TOTAL++))

    # Check if file exists
    if [ ! -e "$filepath" ]; then
        echo "SKIP: File not found: $filepath" >> "$LOG_FILE"
        ((NOT_FOUND++))
        continue
    fi

    # Check if we have write permission to the directory containing the file
    if [ ! -w "$(dirname "$filepath")" ]; then
        echo "DENIED: No write permission to delete: $filepath" >> "$LOG_FILE"
        ((PERMISSION_DENIED++))
        continue
    fi

    # Note the file type for logging purposes
    file_type="regular file"
    if [ ! -f "$filepath" ]; then
        if [ -d "$filepath" ]; then
            file_type="directory"
        elif [ -L "$filepath" ]; then
            file_type="symbolic link"
        elif [ -p "$filepath" ]; then
            file_type="named pipe (FIFO)"
        elif [ -S "$filepath" ]; then
            file_type="socket"
        elif [ -b "$filepath" ] || [ -c "$filepath" ]; then
            file_type="device file"
        else
            file_type="special file"
        fi
    fi

    # Try to remove the file
    echo "Attempting to delete ($file_type): $filepath"
    if rm -f "$filepath" 2>/dev/null || rm -rf "$filepath" 2>/dev/null; then
        if [ "$file_type" = "regular file" ]; then
            echo "SUCCESS: Deleted regular file: $filepath" >> "$LOG_FILE"
            ((REGULAR_SUCCESS++))
        else
            echo "SUCCESS: Deleted non-regular file ($file_type): $filepath" >> "$LOG_FILE"
            ((SPECIAL_SUCCESS++))
        fi
        ((SUCCESS++))
    else
        echo "FAILED: Could not delete file: $filepath" >> "$LOG_FILE"
        ((FAILED++))
    fi

done < "$PATHS_FILE"

# Print summary
echo
echo "====== Deletion Summary ======"
echo "Total paths processed: $TOTAL"
echo "Successfully deleted: $SUCCESS"
echo "  - Regular files: $REGULAR_SUCCESS"
echo "  - Non-regular files: $SPECIAL_SUCCESS"
echo "Files not found: $NOT_FOUND"
echo "Permission denied: $PERMISSION_DENIED"
echo "Other failures: $((FAILED - PERMISSION_DENIED))"
echo "=============================="
echo "Detailed log saved to: $LOG_FILE"

exit 0
