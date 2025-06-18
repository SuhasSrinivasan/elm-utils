!/bin/bash

# Log Parser - Extracts error lines and absolute file paths

# Check if correct number of arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 input_logfile"
    exit 1
fi

INPUT_FILE="$1"

# Extract base filename without extension
BASE_NAME=$(basename "$INPUT_FILE")
BASE_NAME_NO_EXT="${BASE_NAME%.*}"

ERROR_OUTPUT_FILE="${BASE_NAME_NO_EXT}.errors"
PATHS_OUTPUT_FILE="${BASE_NAME_NO_EXT}.paths"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 2
fi

# Check if we can write to output file locations
touch "$ERROR_OUTPUT_FILE" 2>/dev/null || {
    echo "Error: Cannot write to output file '$ERROR_OUTPUT_FILE'."
    exit 3
}

touch "$PATHS_OUTPUT_FILE" 2>/dev/null || {
    echo "Error: Cannot write to output file '$PATHS_OUTPUT_FILE'."
    exit 4
}

echo "Parsing '$INPUT_FILE' for error patterns..."

# Extract lines containing the keywords (case insensitive)
grep -i -E "unsupported type|error" "$INPUT_FILE" > "$ERROR_OUTPUT_FILE"

# Count number of matches
ERROR_COUNT=$(wc -l < "$ERROR_OUTPUT_FILE")

echo "Error extraction complete. Found $ERROR_COUNT matching lines."
echo "Error results saved to '$ERROR_OUTPUT_FILE'"

# Extract absolute file paths from the matched lines, excluding mpifileutils paths
# First extract all absolute paths
grep -o -E '/[^[:space:]]+' "$ERROR_OUTPUT_FILE" |
# Then filter out paths containing mpifileutils
grep -v "mpifileutils" |
# Remove trailing apostrophes from the paths
sed "s/'$//g" > "$PATHS_OUTPUT_FILE"

# Count number of file paths
PATH_COUNT=$(wc -l < "$PATHS_OUTPUT_FILE")

echo "Path extraction complete. Found $PATH_COUNT absolute file paths."
echo "File paths saved to '$PATHS_OUTPUT_FILE'"

exit 0
