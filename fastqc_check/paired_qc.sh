#!/bin/bash

#SLURM_SUBMIT_DIR = "./"   #for use on own computer testbed comment out durng slurm runs!

#This script is to run the fastqc run script to check the quality scores of each sequence.


#/home/cmallory/Genetic_analysis/bd_genetics_analysis/bowtie_alignment/fast_q_files/paired/CJB4_5720-IR-1_GCGTAGTA-CTAGTCGA_S1_R_0011.fastq

# FastQC run settings
memory_per_file=$1
number_of_threads=$2
main_results_folder=$3
run_results_folder="./""$main_results_folder""/paired"
mkdir "$run_results_folder"

# update this location for where your files are located
fastq_file_location="$SLURM_SUBMIT_DIR""/../bowtie_alignment/fast_q_files/paired/"

# update this to point to the csv file that contains the names of fastq files you want to analyze
fastq_files_csv_path="$SLURM_SUBMIT_DIR""/paired_fastq_names.csv"   #Should update this to only look locally


#Uf the csv exists then then makes a list of all the names
if [ -f $fastq_files_csv_path ]; then
    mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_csv_path)
else
    echo "File path $fastq_files_csv_path does not exist"; exit 1
fi


echo "============================"
echo "Looking for fastq files..."
# Steps to check if all new fastq files exist
fastq_files=()

all_files_exist=true
non_existing_files=()
non_readable_fast_q_files=()

# IT figures out the full path to all the files of interest.  If it finds those files it adds the full
# path to the fastq_files list for use later
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
	    echo "START-|""${non_existing_files[$i]}""|-END"
    done
    echo "The following files are not readable:"
    for i in "${!non_readable_fast_q_files[@]}"; do
	    echo "	${non_readable_fast_q_files[$i]}"
    done
    echo "Run Failed"
    exit 1 
fi
# Completed steps to check on new fastq files



# 2. Make a file for output information and settins to be recorded
log_doc_name="paired_fast_qc_settings.txt"
log_doc_full_path="./""$run_results_folder""/""$log_doc_name"
touch "$log_doc_full_path"
echo "FastQC Log" >> "$log_doc_full_path"
echo "date: ""$todays_date" >> "$log_doc_full_path"
echo "Author: Cannon Mallory" >> "$log_doc_full_path"
echo "Ran by SLURM Script on UCSB Pod" >> "$log_doc_full_path"
echo "Results shoudl be located here: ""$run_results_folder" >> "$log_doc_full_path"
echo "Memory allocated to run each file: ""$memory_per_file" >> "$log_doc_full_path"
echo "Number of threads per chunk of files ran: ""$number_of_threads" >> "$log_doc_full_path"

# 3. run the fileqc command on all the files (probably can run one by one tbh)
echo "Lets run Fast qc on the files"
# Runs each qc. Memory is the size of memory variable.   Will run multiple samples at the same time = the number_of_threads.
# Saves output files in the run_results_folder specified
./FastQC/fastqc ${fastq_files[@]} --outdir="./""$run_results_folder" --memory=$memory_per_file -t=$number_of_threads

echo "end run"
