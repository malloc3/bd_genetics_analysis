#  This runs the BWA mems in order slowly on the cluster.
# Not ideal since it is not multithreaded as it hsould be.  But I can
# test the alignment and figure out multithreaded jobs later!
#  What will  probably happen is I submit multiple single threaded jobs
# so this script is ultimately still helpful 

fastq_file_location=$1
fastq_files_text_path=$2
run_results_folder=$3
number_of_threads=$4

#This is the number of characters to drop from the tail end of the file names
# to check if they are actualy the proerply paired files.   THis number will change depending 
# on YOUR files.   It is probably good to keep them consistently named.
number_of_characters_to_drop_for_paired=$5



# maps the text files that we will be using into a single array for use later
if [ -f $fastq_files_text_path ]; then
    mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_text_path)
else
    echo "File path $fastq_files_text_path does not exist"; exit 1
fi

echo "---------"
echo "begin paired align in order script"


# Steps to check if all new fastq files exist
fastq_files=()  # Creates a list of the FULL file paths to each and every sample

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




for ((i=0; i < ${#fastq_files[@]}; i+=2)); do
    start_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Get the two fasta files
    first_file="${fastq_files[i]}"
    second_file="${fastq_files[i+1]}"

    fist_file_base_name="$(basename "$first_file" .fastq)"
    second_file_base_name=$(basename "$second_file" .fastq)


    shortened_1="${fist_file_base_name::-$number_of_characters_to_drop_for_paired}"
    shortened_2="${second_file_base_name::-$number_of_characters_to_drop_for_paired}"

    # double check that the file names match!
    if [ "$shortened_1" == "$shortened_2" ]; then
        echo "$fist_file_base_name matches $second_file_base_name"  
    else
        echo "$fist_file_base_name does not matche $second_file_base_name"  
        echo "We need paired file names to ensure paired end alignment works properly"
        echo "we should not have gotten here because the paired_check_for_all_fiels.sh script should have confirmed this"
        exit 1 
    fi

    #make output file
    sam_save_file="$run_results_folder""/""${fist_file_base_name::-$number_of_characters_to_drop_for_paired}"".sam"

    touch "$sam_save_file"
    echo "[$start_time] Aligning $sam_save_file to $reference_genome_name"
    echo "Results will be saved in $sam_save_file"

        #STAMPY RUN

    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$end_time] q of $fist_file_base_name complete!"
    echo "=========================================="
done