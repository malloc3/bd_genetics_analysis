
reference_genome_path=$1
sam_files_text_path=$2
save_folder_name_prefix=$3
num_tasks=$4
num_nodes=$5
conda_environ=$6


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
base_save_folder="./""$save_folder_name_prefix""flagstats""$todays_date"
mkdir "$base_save_folder"


today_day=$(date '+%Y-%m-%d')


echo "Okay lets deduplicate some things!"

for i in "${!sam_file_names[@]}"; do
    sam_file_path="${sam_file_names[$i]}"

    sam_file_name=${sam_file_path##*/}  # This gets only the file name but includes the file type extention
    only_file_name=${sam_file_name%.sam} # This drops the file type extention as well!

    output_name=$base_save_folder"/""samtools-flagstats""$today_day""--""$only_file_name"".txt"  # should give me just the file name from the whole path
    echo "Input file information"
    echo "$sam_file_path"
    echo "$sam_file_name"

    

    sam_results_save_file="./""$run_results_folder""/""$output_name"                      # Sets the save location of the deduplication

    echo ""
    echo ""
    echo "Output  File information"
    echo "$sam_results_save_file"

    #conda run -n $conda_environ /home/cmallory/Genetic_analysis/bd_genetics_analysis/sam_tools/sam_bin/bin/samtools flagstats -X $sam_file_path > $sam_results_save_file

    conda run -n $conda_environ samtools flagstats $sam_file_path > $sam_results_save_file


    echo "=================="

done