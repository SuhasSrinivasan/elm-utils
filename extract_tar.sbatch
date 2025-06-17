#!/bin/bash
# Script to extract and delete tar files downloaded from Elm
# Use the helper script submit_extract.sh

#SBATCH -J extract_tar               		# Default job name
#SBATCH -o extract_tar.out           		# Default output file
#SBATCH -e extract_tar.err           		# Default error file
#SBATCH --mail-type=FAIL,END         		# Helps to receive email notifications
#SBATCH -C CLASS:SH3_CBASE.1         		# Change this to your fastest node type
#SBATCH --mail-user=                    # Add your email address
#SBATCH --partition=                    # Add your partition

# === Check for arguments ===
if [ -z "$3" ]; then
  echo "Usage: sbatch [options] $0 <username> <tool:dtar/tar> <ntasks>"
  exit 1
fi

USERNAME="$1"
TOOL="$2"
NTASKS="$3"
STATUS="incomplete"
USERDIR="/oak/stanford/groups/howchang/users/${USERNAME}/"

# === Load required modules ===
ml system
ml mpifileutils

cd "$USERDIR" || {
  echo "[ERROR] Directory not found: $USERDIR"
  exit 2
}

# === Validate tool parameter ===
if [ "$TOOL" != "tar" ] && [ "$TOOL" != "dtar" ]; then
  echo "[ERROR] Invalid tool: $TOOL. Must be 'tar' or 'dtar'"
  exit 3
fi

echo "[INFO] Current directory: $(pwd)"

# === Find and sort all split tar files ===
tar_files=( $(ls ${USERNAME}_0*.tar 2>/dev/null | sort) )
num_files=${#tar_files[@]}

if (( num_files == 0 )); then
  echo "[ERROR] No tar files found matching pattern: ${USERNAME}_0*.tar"
  exit 4
fi

echo "[INFO] Found $num_files tar files"

# === Extract with tar ===
if [ "$TOOL" = "tar" ]; then
  echo "[INFO] Starting extraction with tar..."
  
  for ((i=0; i<num_files; i++)); do
    f="${tar_files[i]}"
    echo "[INFO] Extracting with tar ($((i+1))/$num_files): $f"
    tar -x -f "$f"
    if [ $? -ne 0 ]; then
      echo "[ERROR] tar failed on: $f"
      exit 5
    fi
  done
  STATUS="complete"

# === Extract with dtar ===
elif [ "$TOOL" = "dtar" ]; then
  echo "[INFO] Starting extraction with dtar..."
  
  # Handle edge case: only one file
  if [ "$num_files" -eq 1 ]; then
    echo "[INFO] Only one file found, using tar instead of dtar"
    f="${tar_files[0]}"
    echo "[INFO] Extracting with tar (1/1): $f"
    tar -xf "$f"
    if [ $? -ne 0 ]; then
      echo "[ERROR] tar failed on: $f"
      exit 5
    fi
    STATUS="complete"

  else
    # Extract all but the last file with dtar
    echo "[INFO] Extracting $((num_files-1)) files with dtar, last file with tar"
    
    for ((i=0; i<num_files-1; i++)); do
      f="${tar_files[i]}"
      echo "[INFO] Extracting with dtar ($((i+1))/$((num_files-1))): $f"
      srun -n "$NTASKS" dtar -x -f "$f"
      if [ $? -ne 0 ]; then
        echo "[ERROR] dtar failed on: $f"
        exit 5
      fi
    done

    # Extract the last tar file with tar
    # This avoids the .dtaridx index file issue which is stored in the last split
    last_file="${tar_files[num_files-1]}"
    echo "[INFO] Extracting last split with tar ($num_files/$num_files): $last_file"
    tar -xf "$last_file"
    if [ $? -ne 0 ]; then
      echo "[ERROR] tar failed on: $last_file"
      exit 6
    fi
    STATUS="complete"
  fi

fi

# === If all extractions successful delete files ===
if [ "$STATUS" = "complete" ]; then
  echo "[INFO] All extractions successful. Deleting all tar files..."
  rm -f "${tar_files[@]}"
  echo "[INFO] All $num_files split tar files deleted."
  echo "[INFO] Extraction and cleanup completed successfully!"
else
  echo "[ERROR] Extraction not completed. Files not deleted."
  exit 7
fi
