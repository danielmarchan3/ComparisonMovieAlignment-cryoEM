#!/bin/bash

set -x # show commands

DIR_BASE="$(dirname "$(dirname "$(readlink -fm "$0")")")"
DIR=$DIR_BASE/empiar_movies

# wget is run multiple times to speed up download
wget --help | grep -q '\--show-progress' && \
  PROGRESS_OPT="-q --show-progress" || PROGRESS_OPT="--progress=bar:force:noscroll"

#: <<'END'
DEST=$DIR/10288
FILE=$DEST/links.txt
mkdir -p $DEST
rm -f $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/10288.xml" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CountRef_CB1__00000_Feb18_23.26.46.dm4" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00004_Feb18_23.33.18.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00005_Feb18_23.34.19.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00006_Feb18_23.39.55.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00007_Feb18_23.40.59.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00008_Feb18_23.42.02.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00009_Feb18_23.43.05.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00010_Feb18_23.44.09.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00011_Feb18_23.45.12.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00012_Feb18_23.48.46.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00013_Feb18_23.49.46.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00014_Feb18_23.50.49.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00015_Feb18_23.51.48.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00016_Feb18_23.52.56.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00017_Feb18_23.54.02.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00018_Feb18_23.55.09.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00019_Feb18_23.56.07.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00020_Feb18_23.57.06.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00021_Feb18_23.58.04.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00022_Feb18_23.59.03.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00023_Feb19_00.00.19.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00024_Feb19_00.01.30.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00025_Feb19_00.02.33.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00026_Feb19_00.03.33.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00027_Feb19_00.04.32.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00028_Feb19_00.05.39.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00029_Feb19_00.06.46.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00030_Feb19_00.07.54.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00031_Feb19_00.08.53.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00032_Feb19_00.10.00.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10288/data/CB1__00033_Feb19_00.11.07.tif" >> $FILE
wget -nc $PROGRESS_OPT -P $DEST -i $FILE & 
#END

#: <<'END'
DEST=$DIR/10196
FILE=$DEST/links.txt
mkdir -p $DEST
rm -f $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/NOTE" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/SuperRef_sq05_3.mrc" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30000_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30001_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30002_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30003_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30004_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30005_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30006_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30007_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30008_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30009_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30010_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30011_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30012_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30013_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30014_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30015_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30016_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30017_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30018_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30019_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30020_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30021_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30022_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30023_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30024_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30025_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30026_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30027_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30028_movie.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10196/data/Dataset0/sq05_30029_movie.tif" >> $FILE
wget -nc $PROGRESS_OPT -P $DEST -i $FILE & 
EOL=$'\n'
MESSAGE=$'\nTo generate a  proper gain for FlexAlign, one can use e.g. Xmipp:\nxsj '"${DEST}"'SuperRef_sq05_3.mrc'"${EOL}"'Advanced -> ImageJ -> Image -> Transform -> Rotate 90 Degrees Left'"${EOL}"'File -> Save -> '"$DEST"'/gain_flexalign.mrc'
echo "$MESSAGE" | tee $DEST/HowToCreateGainForFlexAlign.txt
#END

#: <<'END'
DEST=$DIR/10314
FILE=$DEST/links.txt
mkdir -p $DEST
rm -f $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/10314.xml" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004037_Data_26004896_26004897_20180126_1815_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004037_Data_26004952_26004953_20180126_1816_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004037_Data_26004957_26004958_20180126_1816_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004037_Data_26004965_26004966_20180126_1815_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004038_Data_26004896_26004897_20180126_1818_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004038_Data_26004952_26004953_20180126_1820_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004038_Data_26004957_26004958_20180126_1820_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004038_Data_26004965_26004966_20180126_1819_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004039_Data_26004896_26004897_20180126_1822_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004039_Data_26004952_26004953_20180126_1823_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004039_Data_26004957_26004958_20180126_1824_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004039_Data_26004965_26004966_20180126_1823_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004040_Data_26004896_26004897_20180126_1826_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004040_Data_26004952_26004953_20180126_1827_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004040_Data_26004957_26004958_20180126_1827_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004040_Data_26004965_26004966_20180126_1826_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004041_Data_26004896_26004897_20180126_1829_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004041_Data_26004952_26004953_20180126_1830_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004041_Data_26004957_26004958_20180126_1831_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004041_Data_26004965_26004966_20180126_1830_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004043_Data_26004896_26004897_20180126_1834_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004043_Data_26004952_26004953_20180126_1835_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004043_Data_26004957_26004958_20180126_1835_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004043_Data_26004965_26004966_20180126_1834_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004044_Data_26004896_26004897_20180126_1837_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004044_Data_26004952_26004953_20180126_1838_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004044_Data_26004957_26004958_20180126_1839_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004044_Data_26004965_26004966_20180126_1838_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004045_Data_26004896_26004897_20180126_1841_Fractions.tif" >> $FILE
echo "https://ftp.ebi.ac.uk/empiar/world_availability/10314/data/data/micrographs/Part1/FoilHole_26004045_Data_26004952_26004953_20180126_1842_Fractions.tif" >> $FILE
wget -nc $PROGRESS_OPT -P $DEST -i $FILE & 
#END

