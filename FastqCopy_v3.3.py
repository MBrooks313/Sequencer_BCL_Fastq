# -*- coding: utf-8 -*-
"""
FastqCopy_v3.3.py

python3 - tested on v3.6.7 & v3.9.7 

Written and tested by Matthew J Brooks - Mar 10th, 2022
Updated and tested by Zach Batz - January 25th, 2024

This script runs for demultiplexing analysis using BCL Convert v3.9.3

This script copies the fastq files from run folder on Alice to FS1 destination
and runs an md5 checksum. The fastq files will have the name cleaned up and have
NNRL formatted suffix upon copying. The SampleSheet.csv, Demultiplex.csv, and
files for SAV of the run are also copied. A barplot of the demultiplaxing stats
is also generated.
"""

# Load libraries
import sys
import os
import glob
import subprocess
from subprocess import PIPE
import re
import shutil
import hashlib
import pandas as pd
import matplotlib.pyplot as plt


##--------------------##
# Declare input/output directories and variables
##--------------------##

try:
    dir_input = sys.argv[1]
except IndexError:
    raise SystemExit(f"\nUsage: {sys.argv[0]} <run directory> [analysis number]\n")

if len(sys.argv) == 3:
    anal_num = str(sys.argv[2])
else:
    anal_num = str(1)
    

#dir_dest = "/FS1/MasterFASTQs/2024Jun-2024Dec"
dir_dest = "/mnt/SDS/nnrl_ngs/MasterFASTQs/2025Jan-2025May"

#dir_internal = 'Analysis/1/Data'
dir_internal = '/'.join(['Analysis', anal_num, 'Data'])



##--------------------##
## Prepare the destination directory
##--------------------##

# Get run date and number
dest = dir_input.split('_')[0] + '_' + dir_input.split('_')[2]

# Make destination directory on FS1
dir_export = os.path.join(dir_dest, dest)
subprocess.run(['mkdir', '-p', dir_export])


##--------------------##
## Define md5 function
##--------------------##
def hash_file(filename: str, blocksize: int = 4096) -> str:
    hsh = hashlib.md5()
    with open(filename, "rb") as f:
        while True:
            buf = f.read(blocksize)
            if not buf:
                break
            hsh.update(buf)
    return hsh.hexdigest()



##--------------------##
## Copy all the fastq files, modifying their name, and generating the md5 checksum
##--------------------##

# Get the fastq names
path = os.path.join(dir_input, dir_internal, 'fastq')
all_fqs = glob.glob(os.path.join(path, '*fastq.gz'), recursive=True)
print("\nFound " + str(len(all_fqs)) + ' fastq files...\n')

# Open the md5 file
f = open(os.path.join(dir_export,'md5.txt'), "a")

# Loop for each of the fastq files
for i in all_fqs:

    # Replace Illumina FQ suffix with NNRL FQ suffix
    #fq_base = re.sub('_S\d+_L\d+.R1_\d+.fastq.gz', '.R1.fastq.gz', os.path.basename(i)) #
    fq_base = re.sub(r'_S\d+_R1_\d+.fastq.gz', '.R1.fastq.gz', os.path.basename(i))
    fq_base = re.sub(r'_S\d+_R2_\d+.fastq.gz', '.R2.fastq.gz', fq_base)

    # Copy the fastq files
    print('Copying ' + fq_base + ' ...')
    shutil.copy(i, os.path.join(dir_export, fq_base))

    # Generate md5 checksum and write to file
    print('Generating md5 checksum...\n')
    
    checksum = hash_file(os.path.join(dir_export, fq_base))
    
    f.write(''.join([fq_base, " = ", checksum, "\n"]))

# Close the md5 file
f.close()
print('\nCompleted the fastq copying and md5 checksum.\n')


##--------------------##
## Copy SampleSheet, demultiplexing stats, and files for SAV
##--------------------##

# Copy SampleSheet
#samp_sheet = glob.glob(os.path.join(dir_input, '*SampleSheet.csv'))[0]
samp_sheet = os.path.join(dir_input, dir_internal, 'Reports', 'SampleSheet.csv')
shutil.copy(samp_sheet, dir_export)

# Copy Demultiplexing stats
demult_stats = os.path.join(dir_input, dir_internal, 'Reports', 'Demultiplex_Stats.csv')
shutil.copy(demult_stats, dir_export)

# Copy SAV docs
shutil.copy(os.path.join(dir_input, 'RunInfo.xml'), dir_export)
shutil.copy(os.path.join(dir_input, 'RunParameters.xml'), dir_export)
shutil.copytree(os.path.join(dir_input, 'InterOp'), os.path.join(dir_export, 'InterOp'))

print('\nCompleted the run file copying.\n')



##--------------------##
## Generate plot of demultiplexing stats
##--------------------##

#Read in stats
stats = pd.read_csv(demult_stats)

# Prep the df for plotting
stats = stats.loc[:, ['SampleID','# Reads']]
stats.columns = ["Sample", "Fragments"]
stats['ID'] = stats['Sample'].str.split('_').str[0]
stats = stats.assign(FragsMil=lambda x: x.Fragments / 1000000)

# Plot the results
fig, ax = plt.subplots(figsize=(6, 4))
ax.bar(stats['ID'], stats['FragsMil'])
labels = ax.get_xticklabels()
plt.setp(labels, rotation=70, horizontalalignment='right')
ax.set(ylabel = 'Clusters (millions)')
plt.tight_layout()
plt.savefig(os.path.join(dir_export, 'Demultiplex_fig.pdf'))
