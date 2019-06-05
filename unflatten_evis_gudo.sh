#! /bin/bash
shopt -s extglob
shopt -s nullglob

for file in */* ; do                #for all files
   IFS=/ read -ra arr <<< "$file"   #take the file path and name and move to an array, chopped by /
#   echo $file 
   IFS=_. read -ra arrf <<< "${arr[1]}"

   path_orig="${arr[0]}"         #make a variable that is the original path
#   echo path_orig $path_orig

   file_name="${arr[1]}"
#   file_orig="${arrf[0]}_${arrf[1]}_${arrf[2]}_${arrf[3]}_${arrf[4]}_${arrf[5]}.${arrf[6]}"
#   echo original file name: $file_orig

   path_new="./${arrf[5]}_${arrf[4]}"    #make a variable that is the new flattened path
#   echo path_new $path_new


   if [ $file_name != ".DS_Store" ] && [ $file_name != "Thumbs.db" ] && [ $file_name != "Result.md5" ]
   then
      mkdir -p "$path_new/"                         #create the new folder/directory if it does not exist
      #touch $path_new/$file_name                   #for debug, create an empty file
      mv $path_orig/$file_name $path_new/$file_name #for reals, copy the file over
#   else 
#      echo ignore $file_name
   fi
done

#improve this by copying over from the original folder, instead of flattening in the same folder.
#improve this by writing it in python

exit 0

