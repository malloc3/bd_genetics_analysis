# This script hunts for all the files that are required for this run.  Focusing on .fasta files and the reference genome


reference_genome=$1
fastq_file_location=$2 #fasta file parent directory
fastq_files_names=$3  # a .txt file with all the names/sub directories of the fasta files you want

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


all_files_paired=true
unpaired_files=()

# Now lets check if the files are properly paired!
for ((i=0; i < ${#fastq_files[@]}; i+=2)); do
    start_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Get the two fasta files
    first_file="$fastq_parent_folder""/""${fastq_files[i]}"
    second_file="$fastq_parent_folder""/""${fastq_files[i+1]}"

    fist_file_base_name="$(basename "$first_file" .fastq)"
    second_file_base_name=$(basename "$second_file" .fastq)

    # double check that the file names match!
    if ![ "${fist_file_base_name::-5}" == "${second_file_base_name::-5}" ]; then
        unpaired_files+=("$first_file")
        unpaired_files+=("$second_file")
        all_files_paired=false
    fi
done

if ! "$all_files_paired"; then
    echo "It appears some fasta files are not paired properly"
    echo "please check your fasta .txt file and make sure they are ordered properly"
    for i in "${!unpaired_files[@]}"; do
        echo "|-----""${!unpaired_files[@]}""-----|"
    done
    exit 1
else
    echo "all the files are paired properly!"
fi



