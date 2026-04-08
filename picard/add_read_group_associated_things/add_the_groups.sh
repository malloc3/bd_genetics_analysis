sam_files_text_path=$1
save_folder_name_prefix=$2


rgid="1111"
rglb="2222"
rgpu="3333"
rgsm="4444"
rgpl="ILLUMINA"


# maps the text files that we will be using into a single array for use later
if [ -f $sam_files_text_path ]; then
    mapfile -t sam_file_names < <(awk -F',' '{for(i=1;i<=NF;i++) print $i}' $sam_files_text_path)
else
    echo "File path $sam_files_text_path does not exist"; exit 1
fi

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
base_save_folder="./""$save_folder_name_prefix-""add_read_groups_""$todays_date"
mkdir "$base_save_folder"


today_day=$(date '+%Y-%m-%d')


echo "Okay lets add out group pairs testing!"
for i in "${!sam_file_names[@]}"; do
    sam_file_path="${sam_file_names[$i]}"

    sam_file_name=${sam_file_path##*/}

    output_name="picard_add_groups_""$today_day""--""$sam_file_name"  # should give me just the file name from the whole path

    echo "$sam_file_path"
    echo "$sam_file_name"
    

    sam_results_save_file="./""$base_save_folder""/""$output_name"                      # Sets the save location of the deduplication

    echo "$sam_results_save_file"
    echo "======================="

    java -jar .../picard/build/libs/picard.jar AddOrReplaceReadGroups \
        -I "$sam_file_path"\
        -O "$sam_results_save_file" \
        -RGID "$rgid" \
        -RGLB "$rglb" \
        -RGPU "$rgpu" \
        -RGSM "$rgsm" \
        -RGPL "$rgpl"

done
