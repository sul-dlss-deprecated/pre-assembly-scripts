#This script works from inside a folder to flatten a deep structure of sub-folders.
#This script is customized especially for the evis / newark newspaper project.
#! /bin/bash
shopt -s extglob
shopt -s nullglob

for file in */*/*/* ; do                         #for all files
   IFS=/ read -ra arr <<< "$file"                #take the file path and name and move to an array, chopped by /
   echo $file

   path_orig="./${arr[0]}/${arr[1]}/${arr[2]}"   #make a variable that is the original path
#   echo path_orig $path_orig

   path_new="./${arr[0]}-${arr[1]}-${arr[2]}"    #make a variable that is the new flattened path
#   echo path_new $path_new

   file_name="${arr[3]}"                         #make a variable that is just the file name, no path
#   echo $file_name

   if [ $file_name != ".DS_Store" ] && [ $file_name != "Thumbs.db" ] && [ $file_name != "Result.md5" ]
   then
      mkdir -p "$path_new/"                         #create the new folder/directory if it does not exist
      #touch $path_new/$file_name                   #for debug, create an empty file
      cp $path_orig/$file_name $path_new/$file_name #for reals, copy the file over
   else
      echo ignore $file_name
   fi
done

#improve this by copying over from the original folder, instead of flattening in the same folder.
#improve this by writing it in python

exit 0
