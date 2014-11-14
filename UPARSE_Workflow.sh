#!/bin/bash

##### Description
# This script will take UPARSE, and create an OTU table suitable for integration into QIIME. Assumes your files are in seq/. 

##### Needed software
# QIIME
# USEARCH 7 named as usearch


# Use QIIME to prepare your FASTQ files. 
echo “Starting… Extracting barcodes”
extract_barcodes.py -a -f seq/Amp.fastq -m tags.txt -l 12 -o seq/prepped/

# Use QIIME to demultiplex the data, with -q 0. Store output as fastq format (we will quality filter with usearch)
echo “Splitting Libraries”
split_libraries_fastq.py --store_demultiplexed_fastq --phred_quality_threshold 0 -i seq/prepped/reads.fastq -b seq/prepped/barcodes.fastq -m tags.txt --barcode_type 12 -o seq/SlOut/

#Make a directory for UPARSE Output

mkdir seq/UPARSEout

# get quality stats
usearch -fastq_stats seq/SlOut/seqs.fastq -log seq/UPARSEout/seqs.stats.log

# remove low quality reads (trimming not required for paired-end data)
usearch -fastq_filter seq/SlOut/seqs.fastq -fastaout seq/UPARSEout/seqs.filtered.fasta -fastq_maxee 0.5 -threads 4

# dereplicate seqs
usearch -derep_fulllength seq/UPARSEout/seqs.filtered.fasta  -output seq/UPARSEout/seqs.filtered.derep.fasta -sizeout -threads 4

# filter singletons
usearch -sortbysize seq/UPARSEout/seqs.filtered.derep.fasta -minsize 2 -output seq/UPARSEout/seqs.filtered.derep.mc2.fasta

# cluster OTUs (de novo chimera checking can not be disabled in usearch)
usearch -cluster_otus seq/UPARSEout/seqs.filtered.derep.mc2.fasta -otus seq/UPARSEout/seqs.filtered.derep.mc2.repset.fasta

# reference chimera check
usearch -uchime_ref seq/UPARSEout/seqs.filtered.derep.mc2.repset.fasta -db ~/Fast_Analysis/QIIME/gold.fasta -strand plus -nonchimeras seq/UPARSEout/seqs.filtered.derep.mc2.repset.nochimeras.fasta -threads 4

# label OTUs using UPARSE python script
fasta_number.py seq/UPARSEout/seqs.filtered.derep.mc2.repset.nochimeras.fasta OTU_ > seq/UPARSEout/seqs.filtered.derep.mc2.repset.nochimeras.OTUs.fasta

#Make an otus folder
mkdir otus/

#Copy this file to a repset.fna file for later use
cp seq/UPARSEout/seqs.filtered.derep.mc2.repset.nochimeras.OTUs.fasta otus/RepSet.fna

# map the _original_ quality filtered reads back to OTUs
usearch -usearch_global seq/UPARSEout/seqs.filtered.fasta -db seq/UPARSEout/seqs.filtered.derep.mc2.repset.nochimeras.OTUs.fasta -strand plus -id 0.97 -uc seq/UPARSEout/otu.map.uc -threads 4

#Modify OTU table for input into QIIME
python /home/lab/bin/uc2otutab.py seq/UPARSEout/otu.map.uc > seq/UPARSEout/seqs.filtered.derep.mc2.repset.nochimeras.OTU-table.txt

# convert to biom
biom convert --table-type="otu table" -i seq/UPARSEout/seqs.filtered.derep.mc2.repset.nochimeras.OTU-table.txt -o otus/UPARSE.biom

# assign taxonomy 
echo “Assigning Taxonomy”
parallel_assign_taxonomy_rdp.py -v -O 4 -t /media/lab/Storage/Silva_111_post/taxonomy/97_Silva_111_taxa_map_RDP_6_levels.txt -r /media/lab/Storage/Silva_111_post/rep_set/97_Silva_111_rep_set.fasta --rdp_max_memory 25000 -i otus/RepSet.fna -o otus/TaxonomyOut/

# add taxonomy to BIOM table
echo “Adding Metadata”
biom add-metadata --sc-separated taxonomy --observation-header OTUID,taxonomy --observation-metadata-fp otus/TaxonomyOut/RepSet_tax_assignments.txt -i otus/UPARSE.biom -o otus/otuTable.biom

#Done
echo “Completed! Happy QIIMEing”
