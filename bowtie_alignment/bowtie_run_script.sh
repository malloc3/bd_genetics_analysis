#!/bin/bash

#SLURM_SUBMIT_DIR = "./"   #for use on own computer testbed comment out durng slurm runs!

#This script is used to align the unpaired fastq files that I downloaded from NCBI.

#Add the complete path to the reference genome you want to use!
reference_genome="$SLURM_SUBMIT_DIR""/fast_q_files/Reference_genomes/Near_complete_2025_non_ncbi_fasta/CMM_BatrDend_JEL423_V3.genome.fasta"

#this is the name of the index files that will be created for this reference genome
reference_genome_name="Near_complete_bd"

# update this location for where your files are located
fastq_file_location="$SLURM_SUBMIT_DIR""/fast_q_files/unpaired/"

# update this to point to the csv file that contains the names of fastq files you want to analyze
fastq_files_csv_path="$SLURM_SUBMIT_DIR""/unpaired_fastq_names.csv"


if [ -f $fastq_files_csv_path ]; then
    mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_csv_path)
else
    echo "File path $fastq_files_csv_path does not exist"; exit 1
fi

echo "============================"
echo "Looking for reference genome..."

if [ -f "$reference_genome" ]; then
    echo "Reference Genome found:"
    echo "	$reference_genome"
else
    echo "Reference genome not found."
    echo "	$reference_genome"
    exit 1
fi

if [ -r "$reference_genome" ]; then
    echo "Refrerence genomes is readable"
else
    echo "reference genome is not readable"; exit 1
fi


echo "============================"

echo "Looking for fastq files..."
# Steps to check if all new fastq files exist
fastq_files=()

all_files_exist=true
non_existing_files=()
non_readable_fast_q_files=()

for i in "${!fastq_files_names[@]}"; do
    full_path="$fastq_file_location${fastq_files_names[$i]}"
    if [ -f "$full_path" ]; then
        if [ -r $full_path ]; then
            fastq_files+=("$full_path")
        else
            all_files_exist=false
            non_readable_fast_q_files+=("$full_path")
        fi
    else
	    all_files_exist=false
	    non_existing_files+=("$full_path")
    fi
done

if $all_files_exist; then
    echo "All fastq files exist and are readable!"
    echo "============================"
else
    echo "The following files do not exist:"
    for i in "${!non_existing_files[@]}"; do
	    echo "	${non_existing_files[$i]}"
    done
    echo "The following files are not readable:"
    for i in "${!non_readable_fast_q_files[@]}"; do
	    echo "	${non_readable_fast_q_files[$i]}"
    done
    echo "Run Failed"
    exit 1 
fi
# Completed steps to check on new fastq files

# We have our reference genome sequences (each file should represent a single chromosome in bd)
# We also have the all the files we want to align to our reference.
#First! However!   we must build an index of our reference genomes that will be used for our analysis late!

# Lets move to our output files folder and begin!
mkdir -p  "./output_files/$reference_genome_name" #makes the output data directory if directory doesn't exist
cd "./output_files/$reference_genome_name" #moves to that directory if the directory doesn't exist

echo "Begin bowtie index build"
conda run -n bowtie_environ  bowtie2-build "$reference_genome" "$reference_genome_name" 
echo "Reference genome indexing complete!"
echo "=========================================="

#echo "Lets align things!"

for file in "${fastq_files[@]}"; do
    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$start_time] Aligning $file to $reference_genome_name "
    conda run -n bowtie_environ bowtie2 -x "$reference_genome_name" -U "$file" -p 36 #Need to figure out how to set the outputs#    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$end_time] Alignment complete!"
    echo "=========================================="
done

echo "end run"
