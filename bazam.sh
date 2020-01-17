#!/bin/bash
#SBATCH -J BAZAM
#SBATCH -o /fast/users/%u/launch/bazam.slurm-%j.out

#SBATCH -A robinson
#SBATCH -p batch            	                            # partition (this is the queue your job will be added to) 
#SBATCH -N 1                                                # number of nodes (due to the nature of sequential processing, here uses single node)
#SBATCH -n 4                                                # number of cores (here uses 4)
#SBATCH --time=04:00:00                                     # time allocation, which has the format (D-HH:MM)
#SBATCH --mem=4G                                            # memory pool for all cores (here set to 4 GB)

# Notification configuration 
#SBATCH --mail-type=END					    # Type of email notifications will be sent (here set to END, which means an email will be sent when the job is done)
#SBATCH --mail-type=FAIL                		    # Type of email notifications will be sent (here set to FAIL, which means an email will be sent when the job is fail to complete)
#SBATCH --mail-user=mark.corbett@adelaide.edu.au  	    # Email to which notification will be sent

# bazam.sh
usage()
{
echo "# bazam.sh Do all the things with bazam.  The result will be some sort of fastq file/s.
# Dependencies:  Java, bazam
# Info: https://github.com/ssadedin/bazam
#
# Usage: sbatch $0 -b /path/to/bam/folder -o /path/to/output/folder -S sampleID | [-h | --help]
#
# Options: 
# -b <arg>           REQUIRED: Path to where your bam file is located
# -S <arg>           REQUIRED: ID of the sample which must be in the bam file name
# -f <arg>           Filter using specified groovy expression 
# -G <arg>           Extract region of given gene symbol
# -L <arg>           Regions to include reads (and mates of reads) from
# -p                 Add original position in BAM to the read names
# -o <arg>           Path to the output default: $FASTDIR/bazam/sampleID/SLURM_JOB_ID
# -e <arg>           Amount extra to pad regions by (0)
# -R                 Flag to indicate you want reads split to R1 and R2 files named sampleID.bazam_R1/2.fastq.gz
# -h | --help	     Prints the message you are reading.
#
# History: 
# Script created by: Mark Corbett on 17/01/2020
# email:mark dot corbett is at adelaide university
# Modified (Date, Name, Description):
#
" 
}
# Set location of bazam.jar
BAZAM=/data/neurogenetics/executables/bazam/bazam.jar

# Set test flag to false
splitReads=false

# Parse script options
while [ "$1" != "" ]; do
	case $1 in
		 -b )	shift
			bamDir=$1
 			;;
		 -S )	shift
			sampleID=$1
 			;;
		 -f )	shift
			filter="-f $1"
 			;;
		 -G )	shift
			GENE="-gene $1"
 			;;
		 -L )	shift
			region="-L $1"
 			;;
		 -p )	shift
			addReadPosition="-namepos"
 			;;
		 -o )	shift
			outDir=$1
 			;;
		 -e )	shift
			pad="-pad $1"
 			;;
		 -R )	shift
			splitReads=true
 			;;
		 -h | --help )	module load Java/10.0.1
		                java -jar $BAZAM --help
		                module unload Java/10.0.1
				usage
				exit
				;;
		* )	module load Java/10.0.1
		        java -jar $BAZAM --help
			module unload Java/10.0.1
			usage
			exit 1
	esac
	shift
done

# Check that your script has everything it needs to start.
if [ -z "$bamDir" ]; then # If bamFile not specified then do not proceed
    usage
    echo "#ERROR: You need to specify -b /path/to/bamfile
    # -b <arg>    REQUIRED: Path to where your bam file is located"
    exit 1
fi
if [ -z "$sampleID" ]; then # If sample not specified then do not proceed
    usage
    echo "#ERROR: You need to specify -S sampleID because I need this to make your file names
    # -S <arg>    ID of the sample which must be in the bam file name"
    exit 1
fi

bamFile=$( find $bamDir/*.bam | grep $sampleID )

if [ -z "$outDir" ]; then # If output directory not specified then make one up
    outDir=$FASTDIR/bazam/$sampleID/$SLURM_JOB_ID
    echo "#INFO: You didn't specify an output directory so I'm going to put your files here.
    $outDir"
fi
if [ ! -d $outDir ]; then
    mkdir -p $outDir
fi
if $splitReads ; then
    R1="$outDir/$sampleID.bazam_R1.fq.gz"
    R2="$outDir/$sampleID.bazam_R2.fq.gz"
    readsOut="-r1 $R1 -r2 $R2"    
    echo "INFO: your read files are $R1 and $R2"
else
    readsOut="-o $outDir/$sampleID.bazam.fq.gz"
    echo "INFO: your read file is $outDir/$sampleID.bazam.fq.gz"
fi
	
allTheFlags="$filter $GENE $region $addReadPosition $pad $readsOut"

# Load modules
module load Java/10.0.1

#Do the thing
java -Xmx4G -jar $BAZAM -bam $bamFile $allTheFlags

