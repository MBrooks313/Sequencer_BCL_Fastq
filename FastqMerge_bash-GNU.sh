#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# This script designed and run successfully May 19, 2026. It was designed to work with GNU bash version 3.2.57(1)-release (arm64-apple-darwin). 
# This takes a directory of multiple fastq files from the same library and concetenates them into a merged fastq using bgzip. This will result in merged fastq files that pass fqtools validate, gunzip -t, and bgzip -t

NPROC="${NPROC:-8}"
OUTDIR="${OUTDIR:-merged_fastqs}"
LOGDIR="${LOGDIR:-merge_logs}"
SUMMARY_LOG="${SUMMARY_LOG:-merge_summary.log}"

mkdir -p "$OUTDIR" "$LOGDIR"

PWD_DIR="$(pwd)"
LIBS_FILE="$(mktemp)"
trap 'rm -f "$LIBS_FILE"' EXIT

# Build unique library IDs from the R1 files
for f in "$PWD_DIR"/*pf_*R1.fastq.gz
do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    if [[ "$base" =~ ^(.+)_L.+ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    fi
done | sort -u > "$LIBS_FILE"

merge_one() {
    lib="$1"
    log="$LOGDIR/${lib}.log"

    {
        echo "===== $lib ====="

        # R1
        r1_files=()
        while IFS= read -r fq
        do
            r1_files+=("$fq")
        done < <(find "$PWD_DIR" -maxdepth 1 -type f -name "${lib}*R1.fastq.gz" | sort)

        if [ "${#r1_files[@]}" -gt 0 ]; then
            out_r1="$OUTDIR/${lib}_merge.R1.fastq.gz"

            {
                for fq in "${r1_files[@]}"
                do
                    bgzip -dc -- "$fq"
                done
            } | bgzip -c > "$out_r1"

            bgzip -t "$out_r1"
            echo "R1: OK -> $out_r1"
        else
            echo "R1: none"
        fi

        # R2
        r2_files=()
        while IFS= read -r fq
        do
            r2_files+=("$fq")
        done < <(find "$PWD_DIR" -maxdepth 1 -type f -name "${lib}*R2.fastq.gz" | sort)

        if [ "${#r2_files[@]}" -gt 0 ]; then
            out_r2="$OUTDIR/${lib}_merge.R2.fastq.gz"

            {
                for fq in "${r2_files[@]}"
                do
                    bgzip -dc -- "$fq"
                done
            } | bgzip -c > "$out_r2"

            bgzip -t "$out_r2"
            echo "R2: OK -> $out_r2"
        else
            echo "R2: none"
        fi

        echo
    } > "$log" 2>&1
}

export -f merge_one
export OUTDIR LOGDIR PWD_DIR

parallel -j "$NPROC" --halt soon,fail=1 merge_one :::: "$LIBS_FILE"

cat "$LOGDIR"/*.log > "$SUMMARY_LOG"

echo "Done."
echo "Merged files: $OUTDIR"
echo "Summary log: $SUMMARY_LOG"
