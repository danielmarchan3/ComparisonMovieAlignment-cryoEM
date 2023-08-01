# ComparisonMovieAlignment-cryoEM
Performance and quality comparison of movie alignment software for Cryo-EM

These scripts are designed to make a complete comparison of quality and performance of 5 different software programs for movie alignment in cryoEM.

All the scripts must be in the same folder. The following software and dependencies would need to be installed to run these scripts: CryoSPARC software (patch motion correction job), GCTF software (gctf ctf estimation program), Xmipp software (FlexAlign program and ctf estimation program), MotionCor2 (movie alignment program), Relion 4 (Relion's MotionCo2 implementation), and Warp software (movie alignment program).

Here are the instructions to replicate the experiment as described in the paper:

### 1. Create the dataset:
  - Download the empiar datasets by executing the downloadMovies.sh script (30 movies per dataset will be downloaded).
  - Generate the phantom movies by executing the generateMovie.sh script (23 movies will be generated).
### 2. Run each program script for each dataset (this will generate a .log file which is important to analyze further results): 
  - runProgramEmpiar.sh
  - runProgramPhantoms.sh
  - NOTE: Warp software needs to be run on a Windows OS machine
### 3. Generate the results:
  - Use create_images.sh to generate micrographs, window images and histograms in .jpeg format, and to compute the PSD and CTF estimations.
  - show_maxFeq.sh to extract max frequency limit for both ctf estimations 
  - freq_statistics.py to make the statistical tests of the max frequency limit
  - generate_psd.py to make the PSDs plots 
  - parse_time.py Program1.log Program2.log ... to extract the execution times for all the studied cases

    
It is important to respect the hierarchy and the organization of the directories since the scripts assume the predefined structure. 
