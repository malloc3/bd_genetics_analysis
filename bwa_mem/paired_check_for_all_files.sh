# This script hunts for all the files that are required for this run.  Focusing on .fasta files and the reference genome


reference_genome=$1
fastq_file_location=$2 #fasta file parent directory
fastq_files_text_path=$3  # a .txt file with all the names/sub directories of the fasta files you want
passed_check_file_confirmation=$4

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

paired_files=()
unpaired_files=()

# Now lets check if the files are properly paired!
for ((i=0; i < ${#fastq_files[@]}; i+=2)); do
    start_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Get the two fasta files
    first_file="${fastq_files[i]}"
    second_file="${fastq_files[i+1]}"

    fist_file_base_name="$(basename "$first_file" .fastq)"
    second_file_base_name=$(basename "$second_file" .fastq)
    
    echo "--------------------------"
    echo "$first_file"
    echo "$second_file"
    echo "--------------------------"
    
    # double check that the file names match!
    if [ "${fist_file_base_name::-5}" == "${second_file_base_name::-5}" ]; then
        paired_files+=("$first_file")
        paired_files+=("$second_file")
    else
        unpaired_files+=("$first_file")
        unpaired_files+=("$second_file")
    fi
done

unpaired_length=${unpaired_files[@]}
paired_length=${paired_files[@]}
all_files_length=${fastq_files[@]}

if ["$paired_length" -eq "$all_files_length"]; then
    echo "It appears some fasta files are not paired properly"
    echo "please check your fasta .txt file and make sure they are ordered properly"
    for i in "${!unpaired_files[@]}"; do
        echo "|-----""${!unpaired_files[@]}""-----|"
    done
    exit 1
else
    echo "all the files are paired properly!"
fi

if ! ["$unpaired_length" -eq "0"]; then
    echo "the unpaired samples length isn't zero which doesn't make sense."
    echo "The previous check should have prevented this"
    echo "$unpaired_length"
    exit 1
fi

#Okay this is funky.  But I need to pass the check results back to the parent 
# bash script.  So I will create a text file with a specific name.
# if it passed the file will exist.  If it didn't pass then the file wont 
# exist
touch "$passed_check_file_confirmation"



