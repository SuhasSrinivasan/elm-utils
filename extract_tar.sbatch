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
if [ -z "$1" ]; then
  echo "Usage: sbatch [options] $0 <username>"
  exit 1
fi

USERNAME="$1"
USERDIR="/oak/stanford/groups/howchang/users/${USERNAME}/"

# === Load required modules ===
ml system
ml mpifileutils

# === Go to user's directory ===
cd "$USERDIR" || {
  echo "[ERROR] Directory not found: $USERDIR"
  exit 2
}

echo "[INFO] Current directory: $(pwd)"

# === Loop through each split tar file ===
for f in ${USERNAME}_0*.tar; do
  echo "[INFO] Processing: $f..."
  srun -n 16 dtar -x -f "$f"
  
  if [ $? -ne 0 ]; then
    echo "[ERROR] dtar failed on: $f. Exiting."
    exit 3
  else
    echo "[INFO] Successfully extracted: $f. Removing..."
    rm -f "$f"
  fi
done

echo "[INFO] All archives processed successfully."

