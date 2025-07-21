#!/bin/bash
# Script to dwalk Oak user directory to find issues that prevent tarring
# Modify $1 and OAKDIR for script to work for any directory

#SBATCH -J dwalk_user                           # Default job name
#SBATCH -o dwalk_user.out                       # Default output file
#SBATCH -e dwalk_user.err                       # Default error file
#SBATCH --time=0-1:00:00                        # Default wall time, 1 hour
#SBATCH --ntasks=8                              # Change this as needed
#SBATCH --cpus-per-task=4                       # Change this as needed and change NUM_PROCS
#SBATCH --mail-type=FAIL,END                    # Helps to receive email notifications
#SBATCH --mail-user=                            # Add your email address
#SBATCH --partition=                            # Add your partition

# === Check for username argument ===
if [ -z "$1" ]; then
  echo "Usage: sbatch [options] $0 <oak username>"
  exit 1
fi

# === Load modules ===
ml system
ml mpifileutils/0.12

# === Configuration ===
OAKUSER="$1"
OAKDIR="/oak/stanford/groups/howchang/users/${OAKUSER}/"
DWALK_MFU="dwalk_list.mfu"
DWALK_TXT="dwalk_list.txt"
LOG_FILE="dwalk_issues.log"
NUM_PROCS=4

CURR_USER=$(whoami)

> "$LOG_FILE"

echo "Process started at: [$(date '+%Y-%m-%d %H:%M:%S')]"
echo "[INFO] Running dwalk on: $OAKDIR"

# Create binary file
srun -n "$NUM_PROCS" dwalk -o "$DWALK_MFU" "$OAKDIR" || {
  echo "[ERROR] dwalk failed"
  exit 1
}

# Convert binary to text
echo "[INFO] Converting MFU binary to text..."
dwalk --input "$DWALK_MFU" --text --output "$DWALK_TXT"

# Use dfind to identify all special file types in a single pass
echo "[INFO] Finding block devices using dfind..."
srun -n "$NUM_PROCS" dfind -v -i "$DWALK_MFU" --type b -to block_dev.txt

echo "[INFO] Finding character devices using dfind..."
srun -n "$NUM_PROCS" dfind -v -i "$DWALK_MFU" --type c -to char_dev.txt

echo "[INFO] Finding pipes using dfind..."
srun -n "$NUM_PROCS" dfind -v -i "$DWALK_MFU" --type p -to pipes.txt

echo "[INFO] Finding sockets dfind..."
srun -n "$NUM_PROCS" dfind -v -i "$DWALK_MFU" --type s -to sockets.txt

# Count and log the special files
BLOCK_COUNT=$(wc -l < block_dev.txt)
CHAR_COUNT=$(wc -l < char_dev.txt)
PIPE_COUNT=$(wc -l < pipes.txt)
SOCKET_COUNT=$(wc -l < sockets.txt)

echo "[DEBUG] Found $FIFO_COUNT FIFO files, $SOCKET_COUNT sockets, $CHAR_COUNT char devices, $BLOCK_COUNT block devices"

# Process block device files
if [ $BLOCK_COUNT -gt 0 ]; then
  while IFS= read -r filepath; do
    [ -n "$filepath" ] && echo "[UNSUPPORTED TYPE][block dev] $filepath" >> "$LOG_FILE"
  done < block_dev.txt
fi

# Process character device files
if [ $CHAR_COUNT -gt 0 ]; then
  while IFS= read -r filepath; do
    [ -n "$filepath" ] && echo "[UNSUPPORTED TYPE][char dev] $filepath" >> "$LOG_FILE"
  done < char_dev.txt
fi

# Process FIFO files
if [ $PIPE_COUNT -gt 0 ]; then
  while IFS= read -r filepath; do
    [ -n "$filepath" ] && echo "[UNSUPPORTED TYPE][pipe] $filepath" >> "$LOG_FILE"
  done < pipes.txt
fi

# Process socket files
if [ $SOCKET_COUNT -gt 0 ]; then
  while IFS= read -r filepath; do
    [ -n "$filepath" ] && echo "[UNSUPPORTED TYPE][socket] $filepath" >> "$LOG_FILE"
  done < sockets.txt
fi

SPECIAL_COUNT=$((BLOCK_COUNT + CHAR_COUNT + PIPE_COUNT + SOCKET_COUNT))

echo "[INFO] Found $SPECIAL_COUNT special files"

echo "[INFO] Processing permission issues from dwalk output..."

# Process the dwalk text output for permission issues
awk -v cur_user="$CURR_USER" '
function log_issue(tag, msg) {
  print tag " " msg >> "'"$LOG_FILE"'"
  perm_count++
}

BEGIN { perm_count = 0 }

{
  if (NF < 6) next  # Skip lines that do not have enough fields

  perms = $1
  user = $2
  group = $3
  # Path is the last field
  path = $NF

  # Skip if invalid
  if (path == "" || perms == "" || user == "" || group == "") next

  # Check if this is a directory (starts with d)
  is_directory = (substr(perms, 1, 1) == "d")

  # Permission checking - only for current user
  u_read = (substr(perms, 2, 1) == "r")
  u_exec = (substr(perms, 4, 1) == "x")

  # Only check if the file/directory is owned by current user
  if (user == cur_user) {
    has_read = u_read
    has_exec = is_directory ? u_exec : 1

    if (!has_read || (!has_exec && is_directory)) {
      issue = " ["
      if (!has_read) issue = issue "NO_READ "
      if (!has_exec && is_directory) issue = issue "NO_EXEC "
      issue = issue "]"
      issue = issue path
      log_issue("[NO_ACCESS]", issue)
    }
  }
}

END {
  print "[SUMMARY] Permission issues found: " perm_count >> "'"$LOG_FILE"'"
}
' "$DWALK_TXT"

# Final summary
PERM_ISSUES=$(grep -c "^\[NO_ACCESS\]" "$LOG_FILE" 2>/dev/null || echo "0")

# Safety checks to ensure variables are numeric
if [[ ! "$SPECIAL_COUNT" =~ ^[0-9]+$ ]]; then
  SPECIAL_COUNT=0
fi

if [[ ! "$PERM_ISSUES" =~ ^[0-9]+$ ]]; then
  PERM_ISSUES=0
fi

TOTAL_ISSUES=$((SPECIAL_COUNT + PERM_ISSUES))

echo "[SUMMARY] Total issues found: $TOTAL_ISSUES" | tee -a "$LOG_FILE"
echo "  - Special files: $SPECIAL_COUNT" | tee -a "$LOG_FILE"
echo "  - Permission issues: $PERM_ISSUES" | tee -a "$LOG_FILE"

# Cleanup
rm -f block_dev.txt
rm -f char_dev.txt
rm -f pipes.txt
rm -f sockets.txt

echo "[INFO] Scan complete. Issues logged to: $LOG_FILE"
echo "Process ended at: [$(date '+%Y-%m-%d %H:%M:%S')]"
