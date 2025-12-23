#!/bin/bash

#This script is used to align the unpaired fastq files that I downloaded from NCBI.

#Add the complete path to the reference genome you want to use!
reference_genome="/mnt/c/Users/Briggs Lab/Documents/Cannon/BD_genetics_data/fast_q_files/Reference_genomes/Near_complete_2025_non_ncbi_fasta/CMM_BatrDend_JEL423_V3.genome.fasta"
refernce_genome_name="Near_complete_bd"

# update this location for where your files are located
fastq_file_location="/mnt/c/Users/Briggs Lab/Documents/Cannon/BD_genetics_data/fast_q_files/unpaired/"

# update this location for what the names of files you want to analyze are
fastq_files_csv_path="./unpaired_fastq_names.csv"


if [ -f $fastq_files_csv_path ]; then
    mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_csv_path)
else
    echo "File path $fastq_files_csv_path does not exist"; exit 1
fi

echo "============================"

if [ -f "$reference_genome" ]; then
    echo "Reference Genome used:"
    echo "	$reference_genome"
else
    echo "Reference genome not found."
    echo "	$reference_genome"
    exit 1
fi

echo "============================"

# Steps to check if all new fastq files exist
fastq_files=()

all_files_exist=true
non_existing_files=()

for i in "${!fastq_files_names[@]}"; do
    full_path="$fastq_file_location${fastq_files_names[$i]}"
    if [ -f "$full_path" ]; then
	fastq_files+=("$full_path")
    else
	all_files_exist=false
	non_existing_files+=("$full_path")
    fi
done

if $all_files_exist; then
    echo "All fastq files exist!"
    echo "============================"
else
    echo "The following files do not exist:"
    for i in "${!non_existing_files[@]}"; do
	echo "	${non_existing_files[$i]}"
    done
    echo "Run Failed"
    exit 1 
fi
# Completed steps to check on new fastq files

# We have our reference genome sequences (each file should represent a single chromosome in bd)
# We also have the all the files we want to align to our reference.
#First! However!   we must build an index of our reference genomes that will be used for our analysis late!

# Lets move to our output files folder and begin!
cd output_files
echo "Begin bowtie index build"
conda run -n bowtie_environ  bowtie2-build "$reference_genome" "$reference_genome_name" 


echo "end run"
