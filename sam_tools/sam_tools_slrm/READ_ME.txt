This sub folder is where I will keep all of my scripts and associated files that will run the slurm jobs and outputs from those slurm jobs on all my sequences.

On the cluster samtools and bcf tools appear to be operational.  You must remmeber to give the full path to the exacutable files though!   Currently the samtools exacutables are not directly in the system PATH which is fine for me.  Keeps versioning a little easier.  Just be explicit!


Please note.  For this to work you will need to create a conda envionrment by the name of "sam_tools_env"

In this environment you will need:

1. libdeflate
