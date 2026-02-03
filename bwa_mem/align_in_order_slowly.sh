#  This runs the stampy alignment in order slowly on the cluster.
# Not ideal since it is not multithreaded as it hsould be.  But I can
# test the alignment and figure out multithreaded jobs later!
#  What will  probably happen is I submit multiple single threaded jobs
# so this script is ultimately still helpful 

reference_genome_path=$1
fastq_parent_folder=$2
fastq_files_names=$3
run_results_folder=$4
stampy_conda_environment=$5


# For loop over the samples given in the fastq_file names
for i in "${!fastq_files_names[@]}"; do
    full_path="$fastq_file_location${fastq_files_names[$i]}"

    # DO STAMPY
    # Run with BWA and multithreading
    


done