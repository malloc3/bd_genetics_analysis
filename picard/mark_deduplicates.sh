
reference_genome_path=$1
sam_files_text_path=$2
save_folder_name_prefix=$3
num_tasks=$4
num_nodes=$5


# maps the text files that we will be using into a single array for use later
if [ -f $sam_files_text_path ]; then
    mapfile -t sam_file_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $sam_files_text_path)
else
    echo "File path $sam_files_text_path does not exist"; exit 1
fi



echo "============================"
echo "Looking for reference genome..."

if [ -f "$reference_genome_path" ]; then
    echo "Reference Genome found:"
    echo "	$reference_genome_path"
else
    echo "Reference genome not found."
    echo "	$reference_genome_path"
    exit 1
fi

if [ -r "$reference_genome_path" ]; then
    echo "Refrerence genomes is readable"
else
    echo "reference genome is not readable"; exit 1
fi


echo "============================"



# Checks that all of our files exist!
echo "Checking that all sam files exist"
sam_files=()  # Creates a list of the FULL file paths to each and every sample

all_files_exist=true
non_existing_files=()
non_readable_fast_q_files=()

for i in "${!sam_file_names[@]}"; do
    full_path="${sam_file_names[$i]}"
    if [ -f "$full_path" ]; then
        if [ -r $full_path ]; then
            sam_files+=("$full_path")
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




# Make the output folder
todays_date=$(date '+%Y-%m-%d_%H-%M-00')
#Make a directoryt o save settings files and setting information
base_save_folder="./""$save_folder_name_prefix""mark_duplicates_""$todays_date"
mkdir "$base_save_folder"

run_results_folder="$base_save_folder""/""sequence_files"
mkdir "$run_results_folder"

metrics_folder_name="$base_save_folder""/""metrics_text_files"

#Make the text metrics file
mkdir "$metrics_folder_name"



today_day=$(date '+%Y-%m-%d')


echo "Okay lets deduplicate some things!"
for i in "${!sam_file_names[@]}"; do
    sam_file_path="${sam_file_names[$i]}"

    sam_file_name=${sam_file_path##*/}

    output_name="picard_mark_dups_""$today_day""--""$sam_file_name"  # should give me just the file name from the whole path

    echo "$sam_file_path"
    echo "$sam_file_name"
    echo "=================="

    sam_results_save_file="./""$run_results_folder""/""$output_name"                      # Sets the save location of the deduplication
    metrics_save_file="./""$metrics_folder_name""/""$output_name"  # Sets the save location of the metrics file

    java -jar ./picard/build/libs/picard.jar MarkDuplicates \
        -I "$sam_file_path"\
        -M "$metrics_save_file" \
        -O "$sam_results_save_file"\
        --REMOVE_DUPLICATES true \
        --REFERENCE_SEQUENCE "$reference_genome_path"


done