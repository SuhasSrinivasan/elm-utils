#!/bin/bash
# Helper script to submit extract tar job with required username, tool and time
# This wraps extract_tar.sbatch

# === Usage check ===
if [ $# -ne 3 ]; then
  echo "Usage: $0 <username> <tool:dtar/tar> <time>"
  echo "Example: $0 user dtar 2-00:00:00"
  exit 1
fi

USERNAME="$1"
TOOL="$2"
TIME="$3"

# === Submit the job ===
sbatch \
  --job-name=extract_${USERNAME} \
  -o extract_${USERNAME}.out \
  -e extract_${USERNAME}.err \
  --time=${TIME} \
  extract_tar.sbatch ${USERNAME} ${TOOL}
