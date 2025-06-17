#!/bin/bash
# Script to extract and delete tar files downloaded from Elm
# Use the helper script submit_extract.sh

#SBATCH -J extract_tar               		# Default job name
#SBATCH -o extract_tar.out           		# Default output file
#SBATCH -e extract_tar.err           		# Default error file
#SBATCH --time=2-00:00               		# Default wall time, 2 days
#SBATCH --partition=                    # Add your partition
#SBATCH -C CLASS:SH3_CBASE.1         		# Change this to your fastest node type
#SBATCH --ntasks=16 							        # Change this as needed
#SBATCH --mem=128GB                   		# Change this as needed
#SBATCH --mail-type=FAIL,END         		# Helps to receive email notifications
#SBATCH --mail-user=                    # Add your email address

# === Check for username argument ===
if [ -z "$2" ]; then
  echo "Usage: sbatch [options] $0 <username> <tool:dtar/tar>"
  echo "Example: sbatch $0 user dtar
  exit 1
fi

USERNAME="$1"
TOOL="$2"
USERDIR="/oak/stanford/groups/howchang/users/${USERNAME}/"

# === Load required modules ===
ml system
ml mpifileutils

cd "$USERDIR" || {
  echo "[ERROR] Directory not found: $USERDIR"
  exit 2
}

echo "[INFO] Current directory: $(pwd)"

# === Find and sort all split tar files ===
tar_files=( $(ls ${USERNAME}_0*.tar | sort) )
num_files=${#tar_files[@]}

if (( num_files == 0 )); then
  echo "[ERROR] No tar files found."
  exit 4
fi

# === Extract all but the last with dtar ===
# This avoids the .dtaridx index file issue which is stored in the last split
for ((i=0; i<num_files-1; i++)); do
  f="${tar_files[i]}"
  echo "[INFO] Extracting with dtar: $f"
  srun -n 16 dtar -x -f "$f"
  if [ $? -ne 0 ]; then
    echo "[ERROR] dtar failed on: $f"
    exit 5
  fi
done

# === Extract the last tar file with tar ===
last_file="${tar_files[num_files-1]}"
echo "[INFO] Extracting last split with tar: $last_file"
tar -xf "$last_file"
if [ $? -ne 0 ]; then
  echo "[ERROR] tar failed on: $last_file"
  exit 6
fi

# === All extractions successful; delete files ===
echo "[INFO] All extractions successful. Deleting all tar files..."
rm -f "${tar_files[@]}"
echo "[INFO] All split tar files deleted."
