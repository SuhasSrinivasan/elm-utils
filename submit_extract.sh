#!/bin/bash
# Helper script to submit extract tar job with required username, tool and time
# This wraps extract_tar.sbatch

# === Usage check ===
if [ $# -ne 4 ]; then
  echo "Usage: $0 <username> <tool:dtar/tar> <ntasks> <time>"
  echo "Example 1: $0 user dtar 8 1-00"
  echo "Example 2: $0 user tar 1 2-00"
  exit 1
fi

USERNAME="$1"
TOOL="$2"
NTASKS="$3"
TIME="$4"

# === Submit the job ===
sbatch \
  --job-name=extract_${USERNAME} \
  --output extract_${USERNAME}.out \
  --error extract_${USERNAME}.err \
  --ntasks ${NTASKS} \
  --time=${TIME} \
  extract_tar.sbatch ${USERNAME} ${TOOL} ${NTASKS}
