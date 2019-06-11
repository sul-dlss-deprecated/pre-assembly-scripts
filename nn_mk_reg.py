#This script generates a spreadsheet which can be used to register a list of objects in argo.
#This script is customized especially for the evis / newark newspaper project.
import os
import sys


def main(folder):
    #print("parent_folder_name=" + folder)

    dir_list = os.listdir(folder)

    chopped = folder.replace("_content", "")
    chopped = chopped.replace("/", "")

    #print("chopped= " + chopped)

    # Output content
    output = ""
    for sub_dir in dir_list:

        #print("sub_dir = " + sub_dir)
        tmp_output = "\tevis:" + chopped + "-" + sub_dir + "\t\t" + sub_dir + "\n"

        #print(tmp_output)



        output += tmp_output

    print output

if __name__ == "__main__":

    main(sys.argv[1])
