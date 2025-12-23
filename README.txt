This folder is to replicate the required packages and run scripts for all analysis scripts and steps.   
This will not contain the raw data fnor the output data.   Simple the code that was used to orchestrate the analysis.
In theory you will make a new folder for each step of the analysis and in that folder will be a:

1. Read me to announce how what the code should do
2. YML file to create teh Conda environment
2. .sh script to handle the code
3. SLURM job to handle the job on the server
4. Any other things needed to run the data!


system_requirements:
	1. linux-64
	2. pixi (helps install things)
		a. pixi.prefix.dev/latest/installation/
		b. $curl -fsSL HTTPS://pixi.sh/install.sh | sh
	2. conda
		a. channels:
			bioconda
			conda-forge
