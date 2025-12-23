#!/bin/bash

#This script is used to align the unpaired fastq files that I downloaded from NCBI.

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
echo "Checking if all fastq files exist..."

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


echo "end run"
