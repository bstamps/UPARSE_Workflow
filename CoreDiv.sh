#!/bin/bash

##### Description
# This script will take data processed by UPARSE/QIIME, and produce basic plots and figures.
# Which really, this is just something to make the path I chose to analyze multiple datasets easily reproducible. 
# You'll need to run biom summarize-table -i otus/otuTable.biom -o summary.txt first, and determine your even sampling depth. 
# Pass the script by typing sh CoreDiv.sh $1
# $1 is REQUIRED BY THE SCRIPT
# Where $1 is the input needed for even sampling depth
# IE "sh CoreDiv.sh 1728" will feed QIIME -e 1728 to all scripts which require it.

##### Needed software
# QIIME (1.9.0)

# First step- making a directory for it all
mkdir DiversityAnalyses/
cp otus/otuTable.biom DiversityAnalyses/otuTable.biom

# Create a quantitative BIOM Summary
echo “Starting… Summarizing Samples by OTU count”
biom summarize-table --qualitative -i DiversityAnalyses/otuTable.biom -o DiversityAnalyses/SampleSummary_ByOTU.txt

# First step- taxa summaries
echo "Creating Taxonomy Summaries"
summarize_taxa_through_plots.py -i DiversityAnalyses/otuTable.biom -o DiversityAnalyses/taxa_summary/ -m tags.txt

# Beta Diversity Plots
echo "Processing Beta Diversity"
beta_diversity_through_plots.py -i DiversityAnalyses/otuTable.biom -m tags.txt -o DiversityAnalyses/bdiv/ -t otus/RepSet.tre -e $1 
make_2d_plots.py -i DiversityAnalyses/bdiv/unweighted_unifrac_pc.txt -o DiversityAnalyses/2D_Unweighted/ -m tags.txt
make_2d_plots.py -i DiversityAnalyses/bdiv/weighted_unifrac_pc.txt -o DiversityAnalyses/2D_Weighted/ -m tags.txt
jackknifed_beta_diversity.py -i DiversityAnalyses/otuTable.biom -t otus/RepSet.tre -m tags.txt -o DiversityAnalyses/bdiv/jackknifedBetaDiv/ -e $1
make_2d_plots.py -i DiversityAnalyses/bdiv/jackknifedBetaDiv/unweighted_unifrac/pcoa/ -o DiversityAnalyses/bdiv/jackknifedBetaDiv/2D_Unweighted/ -m tags.txt
make_2d_plots.py -i DiversityAnalyses/bdiv/jackknifedBetaDiv/weighted_unifrac/pcoa/ -o DiversityAnalyses/bdiv/jackknifedBetaDiv/2D_Weighted/ -m tags.txt
make_bootstrapped_tree.py -m DiversityAnalyses/bdiv/jackknifedBetaDiv/unweighted_unifrac/upgma_cmp/master_tree.tre -s DiversityAnalyses/bdiv/jackknifedBetaDiv/weighted_unifrac/upgma_cmp/jackknife_support.txt -o DiversityAnalyses/bdiv/weightedUPGMA.pdf
make_bootstrapped_tree.py -m DiversityAnalyses/bdiv/jackknifedBetaDiv/weighted_unifrac/upgma_cmp/master_tree.tre -s DiversityAnalyses/bdiv/jackknifedBetaDiv/unweighted_unifrac/upgma_cmp/jackknife_support.txt -o DiversityAnalyses/bdiv/unweightedUPGMA.pdf


# Finally, Alpha Rarefaction
# This one will be edited soon to include evenness metrics.
echo "Alpha Rarefaction. This can take a LONG time. Hold please"
echo "alpha_diversity:metrics shannon,PD_whole_tree,chao1,observed_species" > DiversityAnalyses/alpha_params.txt
alpha_rarefaction.py -i DiversityAnalyses/otuTable.biom -m tags.txt -o DiversityAnalyses/AlphaRarefaction/ -p DiversityAnalyses/alpha_params.txt -t otus/RepSet.tre

#Done
echo “Diversity analysis completed. Now the hard part starts...”
