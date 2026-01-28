#!/bin/bash

#SLURM_SUBMIT_DIR = "./"   #for use on own computer testbed comment out durng slurm runs!

#This script is to run the fastqc run script to check the quality scores of each sequence.

#/home/cmallory/Genetic_analysis/bd_genetics_analysis/bowtie_alignment/fast_q_files/paired/CJB4_5720-IR-1_GCGTAGTA-CTAGTCGA_S1_R_0011.fastq

todays_date=$1
results_folder=$2
fastq_files_csv_path=$3
number_threads=$4


# update this location for where your files are located
fastq_file_location="$SLURM_SUBMIT_DIR""/../bowtie_alignment/fast_q_files/paired"

vector_file="illumina_adapters_cm_01-27-26.fasta"  #need to find the adapter sequences that I want to trim


#Uf the csv exists then then makes a list of all the names
if [ -f $fastq_files_csv_path ]; then
    #mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_csv_path)
    mapfile -t fastq_files_names < "$fastq_files_csv_path"
else
    echo "File path $fastq_files_csv_path does not exist" >&2
    exit 1
fi

num_files=${#fastq_files_names[@]}

if (( num_files % 2 != 0 )); then
    echo "ERROR: Odd number of FASTQ files ($num_files). Files must be in pairs." >&2
    exit 1
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
    echo "Run Failed because some files are not readable" >&2 
    exit 1 
fi
# Completed steps to check on new fastq files

non_matching_pair_file_names=[]
non_matching_pair=false

# Now lets check if all the fast q files are properly paired.
# To do this we will run through the script and grab files by groups of two and make sure their file names 
# match when we drop the last 6 characters maybe?   That should drop the file 1 and file 2 extentions
for ((i=0; i<num_files; i+= 2)); do
    file_name_1=${fastq_files_names[$i]}     #Grab the first file
    file_name_2=${fastq_files_names[$((i+1))]}   #Grab the second file  (assumes that the files are in order and next to each other)

    shortened_1=${file_name_1::-7}
    shortened_2=${file_name_2::-7}
    if [[ "$shortened_1" != "$shortened_2" ]]; then
        non_matching_pair_file_names+=("$file_name_1")
        non_matching_pair_file_names+=("$file_name_2")
        non_matching_pair=true
    fi
done

if $non_matching_pair; then
    echo "The following files do not have proper matching paires"
    for ((i=0; i<num_files; i+=2)); do
        echo "${fastq_files_names[$i]}"     #Grab the first file
        echo "${fastq_files_names[$((i+1))]}"   #Grab the second file  (assumes that the files are in order and next to each other)
        echo "--------------------------"
    done
    echo "Run failed due to non_matching_pairs" >&2
    exit 1
else
    echo "All files have proper matching pairs!"
fi


echo "Lets run our clean!"
for ((i=0; i<num_files; i+=2)); do
    file_name_1=${fastq_files_names[$i]}     #Grab the first file
    file_name_2=${fastq_files_names[$((i+1))]}   #Grab the second file  (assumes that the files are in order and next to each other)
    
    generic_name=${file_name_1::-6}

    shortened_name_1=${file_name_1::-6}
    shortened_name_2=${file_name_1::-6}

    # Create the full file path names of our fasta files to be cleaned
    full_input_file_path_1="$fastq_file_location""/""$file_name_1"
    full_input_file_path_2="$fastq_file_location""/""$file_name_2"


    #output_prefex_full="$output_folder""/""$output_file_prefex"
    
    output_folder="$results_folder/$generic_name"
    mkdir -p "$output_folder"

    # Name the trim_log and summary files
    trim_log_file="$output_folder""/""trimlog.txt"
    summary_file="$output_folder""/""summary.txt"
    # Create the trim and summary files
    touch "$trim_log_file"
    touch "$summary_file"

        # Create file paths of all output files!
    full_output_file_path_1_paired="$output_folder""/""$todays_date""$shortened_name_1""_output_paired.fasta"
    full_output_file_path_1_unpaired="$output_folder""/""$todays_date""$shortened_name_1""_output_unpaired.fasta"
    full_output_file_path_2_paired="$output_folder""/""$todays_date""$shortened_name_2""_output_paired.fasta"
    full_output_file_path_2_unpaired="$output_folder""/""$todays_date""$shortened_name_2""_output_unpaired.fasta"
    
    #Create those output files!
    touch "$full_output_file_path_1_paired"
    touch "$full_output_file_path_1_unpaired"
    touch "$full_output_file_path_2_paired"
    touch "$full_output_file_path_2_unpaired"



    echo "Running: ""$file_name_1"" and ""$file_name_2"

    echo "All outputs should be saved in folder $output_folder"

    # Can add additional options
    java -jar "./Trimmomatic/target/trimmomatic-0.40.jar" PE -threads $number_threads \
    -trimlog "$trim_log_file" -summary "$summary_file" -compressLevel 9 -version \
    "$full_input_file_path_1" "$full_input_file_path_2"\
    "$full_output_file_path_1_paired" "$full_output_file_path_1_unpaired" \
    "$full_output_file_path_2_paired" "$full_output_file_path_2_unpaired" \
    HEADCROP:15\
    ILLUMINACLIP:Trimmomatic/adapters/NexteraPE-PE.fa:2:30:10 \
    LEADING:3 \
    TRAILING:3 \
    MAXINFO:150:5 \
    MINLEN:36

    # HEADCROP:15 removes the first 15 bases without question (I htink I need this not 100% sure)
    #ILLUMINACLIP:  NexteraPE-PE.fa: :<seed mismatches>:<palindrome clip threshold>:
    #       <simple clip threshold>:<minAdapterLengthPalindrome>:<keepBothReads> :   
    #   ## NexteraPE-PE.fa - is the folder that has the adapters we want to remove.  Specifcally the full path actually!  
    #                   The specific format of this folder is IMPORTANT beyond just normal fasta files.  LOOK IT UP
    #   ## seedMismatches: specifies the maximum mismatch count which will still allow a full match to be performed
    #   ## palindromeClipThreshold: specifies how accurate the match between the two 'adapter ligated' reads must be for PE palindrome read alignment.
    #   ## simpleClipThreshold: specifies how accurate the match between any adapter etc. sequence must be against a read.
    #   ## minAdapterLengthPalindrome: (optional int) specifies the minimum adapter length in palindrome mode [default = 8].
    #   ## keepBothReads: (optional boolean) specifies if both reads should be kept in palindrome mode even when redundant information is found (small inserts)[default = False]. Note: minAdapterLengthPalindrome needs to be set manually to be able to activate keepBothReads.
    #
    #           
    #  MAXINFO uses their special algorthm to maintain maximum read length while getting rid of bad bases. 
    #                Its clever and should do good for us
    # Remove leading low quality or N bases (below quality 3) (LEADING:3)
    # Remove trailing low quality or N bases (below quality 3) (TRAILING:3) 
    # Scan the read with a 4-base wide sliding window, cutting when the average quality per base drops below 15 (SLIDINGWINDOW:4:15)
    # 
    # Drop reads below 36 bases long (MINLEN:36)



    echo "Done with $shortened_name"
    echo ""
    echo ""
    echo "=================================================================================================="
    echo "=================================================================================================="
    echo "=================================================================================================="
done



echo "end run"
