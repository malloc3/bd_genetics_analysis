#!/bin/bash

#SLURM_SUBMIT_DIR = "./"   #for use on own computer testbed comment out durng slurm runs!

#This script is to run the fastqc run script to check the quality scores of each sequence.


#/home/cmallory/Genetic_analysis/bd_genetics_analysis/bowtie_alignment/fast_q_files/paired/CJB4_5720-IR-1_GCGTAGTA-CTAGTCGA_S1_R_0011.fastq

todays_date=$1
results_folder=$2


# update this location for where your files are located
fastq_file_location="$SLURM_SUBMIT_DIR""/../bowtie_alignment/fast_q_files/paired"

# update this to point to the csv file that contains the names of fastq files you want to analyze
fastq_files_csv_path="$SLURM_SUBMIT_DIR""/paired_names.txt"   #Should update this to only lookq locally

vector_file="illumina_adapters_cm_01-27-26.fasta"  #need to find the adapter sequences that I want to trim


#Uf the csv exists then then makes a list of all the names
if [ -f $fastq_files_csv_path ]; then
    #mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_csv_path)
    mapfile -t fastq_files_names < "$fastq_files_csv_path"
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
    file_name=${fastq_files_names[$i]}
    echo "|--""$file_name""--|"

    full_path="$fastq_file_location""/""$file_name"
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


# Check if all the fastq files exist and are readable
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

non_matching_pair_file_names=[]
non_matching_pair=false

# Now lets check if all the fast q files are properly paired.
# To do this we will run through the script and grab files by groups of two and make sure their file names 
# match when we drop the last 6 characters maybe?   That should drop the file 1 and file 2 extentions
for ((i=0, i<$(#fastq_files_names[@]); i+= 2)); do
    file_name_1=${fastq_files_names[$i]}     #Grab the first file
    file_name_2=${fastq_files_names[$i+1]}   #Grab the second file  (assumes that the files are in order and next to each other)

    shortened_1=$(file_name_1::-7)
    shortened_2=$(file_name_2::-7)
    if [["$shortened_1"!=["$shortened_1"]]]; do
        non_matching_pair_file_names+=["$file_name_1"]
        non_matching_pair_file_names+=["$file_name_2"]
        non_matching_pair=true
    done
done

if $non_matching_pair; then
    echo "The following files do not have proper matching paires"
    for ((i=0, i<$(#non_matching_pair_file_names[@]); i+= 2)); do
        echo "${fastq_files_names[$i]}"     #Grab the first file
        echo "${fastq_files_names[$i+1]}"   #Grab the second file  (assumes that the files are in order and next to each other)
        echo "--------------------------"
    done
    echo "Run failed due to non_matching_pairs"
    exit 1
else
    echo "All files have proper matching pairs!"
fi


echo "Lets run our clean!"
for ((i=0, i<$(#fastq_files_names[@]); i+= 2)); do
    file_name_1=${fastq_files_names[$i]}     #Grab the first file
    file_name_2=${fastq_files_names[$i+1]}   #Grab the second file  (assumes that the files are in order and next to each other)
    
    # Create the full file path names
    full_file_path_1="$fastq_file_location""/""$file_name_1"
    full_file_path_2="$fastq_file_location""/""$file_name_2"

    output_prefex="$results_folder""/""todays_date""$(file_name_1::-7)""_cleaned_"

    echo "Running: ""$file_name_1"" and ""$file_name_2"
    ./seqyclean/bin/seqyclean -qual -dup -verbose -detrep -at 0.75 -v $vector_file -1 $full_file_path_1 -2 $full_file_path_2    -o output_prefex #add options etc
    


done



echo "end run"
