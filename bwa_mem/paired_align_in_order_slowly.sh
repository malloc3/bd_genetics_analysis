#  This runs the BWA mems in order slowly on the cluster.
# Not ideal since it is not multithreaded as it hsould be.  But I can
# test the alignment and figure out multithreaded jobs later!
#  What will  probably happen is I submit multiple single threaded jobs
# so this script is ultimately still helpful 

reference_index_path=$1
fastq_file_location=$2
fastq_files_text_path=$3
run_results_folder=$4
number_of_threads=$5



# maps the text files that we will be using into a single array for use later
if [ -f $fastq_files_text_path ]; then
    mapfile -t fastq_files_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $fastq_files_text_path)
else
    echo "File path $fastq_files_text_path does not exist"; exit 1
fi


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

    fist_file_base_name="$(basename "$first_file" .fastq)"
    second_file_base_name=$(basename "$second_file" .fastq)

    # double check that the file names match!
    if ![ "${fist_file_base_name::-5}" == "${second_file_base_name::-5}" ]; then
        echo "$fist_file_base_name doesn't appear to pair with $second_file_base_name"
        echo "We need paired file names to ensure paired end alignment works properly"
        exit 1   
    fi

    #make output file
    sam_save_file="$run_results_folder""/""${fist_file_base_name::-5}"".sam"

    touch "$sam_save_file"
    echo "[$start_time] Aligning $sam_save_file to $reference_genome_name"
    echo "Results will be saved in $sam_save_file"

        /bwa-mem2-2.2.1_x64-linux/bwa-mem2 -o "$sam_save_file" -t "$number_of_threads" -v 3 "$reference_index_path" "$first_file" "$second_file"

    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$end_time] Alignment of $fist_file_base_name complete!"
    echo "=========================================="
done