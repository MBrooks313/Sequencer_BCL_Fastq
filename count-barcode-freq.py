## Simple script to check the top indicies in an undetermined fastq.gz file
## 
## Usage: python3 count-barcode-freq.py <fastq_file.gz> > out.txt
## Example: python3 count-barcode-freq.py sample.fastq.gz > out.txt
##
## Once complete use tail -n 20 out.txt to see the top indices in the file
from operator import itemgetter
import sys, gzip

barcodes = {}
with gzip.open(sys.argv[1]) as fastq:
        for line in fastq:
                if not line.startswith(b'@'): continue
                bc = line.decode("utf-8").split(':')[-1].strip()
                if bc not in barcodes:
                        barcodes[bc] = 1
                else:
                        barcodes[bc]+=1

total = sum(barcodes.values())
for k, v in sorted(barcodes.items(), key=itemgetter(1)):
        print(k, v, round(v/total*100, 2))


