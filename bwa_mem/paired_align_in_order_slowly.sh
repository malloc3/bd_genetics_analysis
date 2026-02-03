#  This runs the BWA mems in order slowly on the cluster.
# Not ideal since it is not multithreaded as it hsould be.  But I can
# test the alignment and figure out multithreaded jobs later!
#  What will  probably happen is I submit multiple single threaded jobs
# so this script is ultimately still helpful 

reference_index_path=$1
fastq_parent_folder=$2
fastq_files_names=$3
run_results_folder=$4
conda_environ=$5
number_of_threads=$6


for ((i=0; i < ${#fastq_files[@]}; i+=2)); do
    start_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Get the two fasta files
    first_file="$fastq_parent_folder""/""${fastq_files[i]}"
    second_file="$fastq_parent_folder""/""${fastq_files[i+1]}"

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