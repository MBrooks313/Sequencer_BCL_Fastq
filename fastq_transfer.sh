#!/bin/bash
set -euo pipefail

# -------- USER SETTINGS --------
FASTQ_LIST="fastq_list.txt"
DEST_DIR="/Volumes/data-2/NF-core/rnaseq/Jayshree/FQ"
# -------------------------------

# Create destination if it doesn't exist
mkdir -p "$DEST_DIR"

# Rsync options:
# -a  : archive (preserves permissions, timestamps)
# -v  : verbose
# -h  : human-readable
# --progress : show progress
RSYNC_OPTS="-avh --progress"

while read -r fastq; do
    # Skip empty lines or comments
    [[ -z "$fastq" || "$fastq" =~ ^# ]] && continue

    if [[ ! -f "$fastq" ]]; then
        echo "WARNING: File not found: $fastq" >&2
        continue
    fi

    rsync $RSYNC_OPTS --relative "$fastq" "$DEST_DIR/"

done < "$FASTQ_LIST"
