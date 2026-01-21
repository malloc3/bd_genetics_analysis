#!/bin/bash

#SLURM_SUBMIT_DIR = "./"   #for use on own computer testbed comment out durng slurm runs!

#This script is to run the fastqc run script to check the quality scores of each sequence.

# FastQC run settings
memory_per_file=512
number_of_threads=3



# update this location for where your files are located
fastq_file_location="$SLURM_SUBMIT_DIR""/../bowtie_alignment/fast_q_files/unpaired/"

# update this to point to the csv file that contains the names of fastq files you want to analyze
fastq_files_csv_path="$SLURM_SUBMIT_DIR""/unpaired_fastq_names.csv"   #Should update this to only look locally


#Uf the csv exists then then makes a list of all the names
if [ -f $fastq_files_csv_path ]; then
    mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_csv_path)
else
    echo "File path $fastq_files_csv_path does not exist"; exit 1
fi


echo "============================"
echo "Looking for fastq files..."
echo "These are the names of the files:"
for i in "${!fastq_files_names[@]}"; do
    full_path="$fastq_file_location${fastq_files_names[$i]}"
    echo "$full_path"
done
echo "============================"
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
    echo "The list of all of these files is:"
    echo " $fastq_files"
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



# Get todays date.   
todays_date=$(date '+%Y-%m-%d_%H:%M:%S')

#Make a directoryt o save settings files and setting information
run_results="fast_qc_results""$todays_date"
#mkdir "./""$run_results"

# 2. Make a file for output information and settins to be recorded
log_doc_name="fast_qc_settings.txt"
log_doc_full_path="$run_results""/""$log_doc_name"
#touch "$log_doc_full_path"
#echo "FastQC Log" >> "$log_doc_full_path"
#echo "date: ""$todays_date" >> "$log_doc_full_path"
#echo "Author: Cannon Mallory" >> "$log_doc_full_path"
#echo "Ran by SLURM Script on UCSB Pod" >> "$log_doc_full_path"
#echo "Results shoudl be located here: ""$run_results" >> "$log_doc_full_path"
#echo "Memory allocated to run each file: ""$memory_per_file" >> "$log_doc_full_path"
#echo "Number of threads per chunk of files ran: ""$number_of_threads" >> "$log_doc_full_path"


# 3. write any needed info to that file of note
# 4. run the fileqc command on all the files (probably can run one by one tbh)



# Looks through the fastq files list and runs the fastqc on each of thsoe files
# Then saves it to the run_results folder
echo "Lets run rast qc on the files"

#for file in "${fastq_files[@]}"; do
for ((i=0; i<${#fastq_files[@]}; i+=$number_of_threads)); do
    files=(${fastq_files[@]}:$i:$number_of_threads)
    echo "$files"
    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$start_time] Running FastQC of these files" "$files"

   #./FastQC/fastqc "$files" --outdir="./""$run_results" --memory=$memory_per_file -t=$number_of_threads

    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$end_time]"
    echo "=========================================="
done

echo "end run"
