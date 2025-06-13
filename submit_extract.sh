#!/bin/bash
# Helper script to submit extract job with dynamic job name, output, error, and time

# === Usage check ===
if [ -z "$1" ]; then
  echo "Usage: $0 <username> [time]"
  echo "Example: $0 user 2-00:00:00"
  exit 1
fi

USERNAME="$1"

# === Submit the job ===
sbatch \
  --job-name=extract_${USERNAME} \
  -o ${USERNAME}.out \
  -e ${USERNAME}.err \
  --time="2-00:00:00" \
  extract_script.sh ${USERNAME}
