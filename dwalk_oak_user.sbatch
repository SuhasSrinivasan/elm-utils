#!/bin/bash
# Script to dwalk Oak user directory to find issues that prevent tarring
# Modify $1 and OAKDIR for script to work for any directory

#SBATCH -J dwalk_user                           # Default job name
#SBATCH -o dwalk_user.out                       # Default output file
#SBATCH -e dwalk_user.err                       # Default error file
#SBATCH --time=0-1:00:00                        # Default wall time, 1 hour
#SBATCH --ntasks=8                              # Change this as needed
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
