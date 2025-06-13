#!/bin/bash
# Script to concatenate, extract and delete tar files downloaded from Elm
# Use the helper script submit_extract.sh

#SBATCH -J extract_tar               # Default job name
#SBATCH -o extract_tar.out           # Default output file
#SBATCH -e extract_tar.err           # Default error file
#SBATCH --time=2-00:00               # Default wall time, 2 days
#SBATCH --partition=                 # Change this to your partition
#SBATCH -C CLASS:SH3_CBASE.1         # Change this to your fastest node type
#SBATCH --cpus-per-task=8            # Change this as needed
#SBATCH --mem=64GB                   # Change this as needed
#SBATCH --mail-type=FAIL,END         # Helps to receive email notifications
#SBATCH --mail-user=                 # Add email address for notifications


# === Check for username argument ===
if [ -z "$1" ]; then
  echo "Usage: sbatch [options] $0 <username>"
  exit 1
fi

USERNAME="$1"

# === Load required modules ===
ml system
ml mpifileutils

# === Switch to user directory ===
USERDIR="/oak/stanford/groups/howchang/users/${USERNAME}/"
if [ ! -d "$USERDIR" ]; then
  echo "Directory $USERDIR not found!"
  exit 2
fi

cd "$USERDIR" || exit 2

# === Concatenate split tar files ===
cat ${USERNAME}_0*.tar > ${USERNAME}_complete.tar

# === Extract using dtar ===
mpirun -n 8 dtar -x -f ${USERNAME}_complete.tar

# === Clean up only if extraction succeeded ===
if [ $? -eq 0 ]; then
  echo "Extraction succeeded. Cleaning up split tar files..."
  rm -f ${USERNAME}_0*.tar
else
  echo "Extraction failed. Split tar files retained for debugging."
  exit 3
fi
