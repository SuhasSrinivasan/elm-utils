#!/bin/bash
# Helper script to submit extract tar job with required username and time
# This wraps extract_tar.sbatch

# === Usage check ===
if [ $# -ne 2 ]; then
  echo "Usage: $0 <username> <time>"
  echo "Example: $0 user 2-00:00:00"
  exit 1
fi

USERNAME="$1"
TIME="$2"

# === Submit the job ===
sbatch \
  --job-name=extract_${USERNAME} \
  -o ${USERNAME}.out \
  -e ${USERNAME}.err \
  --time=${TIME} \
  extract_tar.sh ${USERNAME}
