#! /bin/bash

echo "**************************"
echo "*** file lists for $1 ***"
echo $1:
ls -a $1
echo " "
echo $1_:
ls -a $1_*
echo " "

#Count files/objects for $1: 
files=`find $1 -type f | wc -l`
#objects=`ls -d $1 | wc -l`
objects=`find $1/*/*/* -type d | wc -l`
#objects_-1=`expr ${all_objects} - 1` # and subtract 1
echo "*** $1 files/objects: $files/$objects"

#Count files/objects for $1_content: 
for x in $1_*; do 
#    echo Count files/objects for $x: ; 
    files=`find $x -type f | wc -l` ; 
    all_objects=`find $x -type d | wc -l` ;   # and subtract 1
    objects=`expr ${all_objects} - 1` ;
    echo "*** $x files/objects: $files/$objects" ; 
done

echo "*** .DS_Store files ***"
find $1 -name .DS_Store
find $1_* -name .DS_Store
echo "*** Thumbs.db files ***"
find $1 -name Thumbs.db
find $1 -name Thumbs.db | wc -l
find $1_* -name Thumbs.db
find $1_* -name Thumbs.db | wc -l
echo "*** Result.md5 files ***"
find $1 -name Result.md5
find $1_* -name Result.md5
echo "*** nohup.out files ***"
find $1_* -name nohup.out 
echo "*** *.lnk ***"
find $1* -name *.lnk
echo "*** manifest.csv ***"
find $1_* -name manifest.csv
exit 0

