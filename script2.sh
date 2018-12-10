#! /usr/bin/env bash
mkdir extracted &> /dev/null
FOLDERS=0
S=1
FILES=0
ALLFILES=0
EXIT=1
# 1 depth  #2 folder path
folders() { # i check the files in function recursively so as not to have problems with .git
	ls -1 $2 &> /dev/null # i check if the folder is empty
	if [ $? -ne 0 ] ; then
		EXIT=0
		return 1
	fi
	# i check the number of files that in the current folder (all the files) 
	for FILE in $(find $2 -maxdepth 1 -type f | tr " " "_") ; do
		ALLFILES=$(echo "$ALLFILES+1" | bc)
	done
	# i check the number of .txt files in the current folder
	for FILE in $(find $2 -maxdepth 1 -type f | grep  '\.txt$' | tr " " "_") ; do
		FILES=$(echo "$FILES+1" | bc)
	done

	find $2 -maxdepth 1 -type d &> /dev/null 
	# i check if there is any subdirectory
	if [ $? -eq 0 ]
	then 
		# i save all subdirectories in TEMP1
	 	local TEMP1=`find $2 -maxdepth 1 -type d`
		for D in  $TEMP1
		 do
		 	# find also returns the current directory and .git and i dont want them
			if [ "$D" = "$2.git" ] || [ "$D" = "$2" ] ; 
			then 
				continue
			fi
			#and for every subdirectory i call the same function while i also change the number of folders
			FOLDERS=$(echo "$FOLDERS+1" | bc)
			folders $(echo "$1 +1" | bc)  "$D"
		done 
	fi
	EXIT=1
}
# i extract the given file to folder extracted
tar -xzf $1 -C extracted/  &> /dev/null

mkdir assignments &> /dev/null
REPOS=() # i save all the repositories in REPOS so as to have them later
POS=0
for FILE2 in $(find extracted/ | tr " " "\n" | grep '\.txt$') ; do
	# the url is copied in HTTP
	HTTP=$(grep '^https*' $FILE2 | head -1)

	if [ "$HTTP" != "" ] ; then
		# every repo is cloned at the folder assignments
		git -C assignments/ clone $HTTP &> /dev/null
	    # if any error occure at cloning i report it or echo Cloning OK
		if [ $? -eq 0 ] ; then
		# if the repo is cloned correctly then i place it at REPOS
			REPOS[$POS]=$HTTP 
    		POS=$(echo "$POS+1" | bc)
			echo "$HTTP: Cloning OK"
		else
			>&2 echo "$HTTP: Cloning FAILED"
		fi
	fi
done

for i in ${REPOS[@]} ; do 
	# for every cloned repo i check the above
	STRUCTURE=1
	REPO="${i##*/}" # i take the name of the repo (which is everything after the last slash)
	# i chache if it has the apropriate files and the folder so as for the structure to be ok
	if [ ! -f assignments/$REPO/dataA.txt ]; then
		STRUCTURE=0
	else
		if [ ! -d assignments/$REPO/more/ ]
		then
			STRUCTURE=0
		else
			if [ ! -f assignments/$REPO/more/dataB.txt ] || [ ! -f assignments/$REPO/more/dataC.txt ]
			then
				STRUCTURE=0
			fi
		fi
	fi
	# for every repo i set files and folders to zero and i run the function
	FILES=0
	FOLDERS=0
	ALLFILES=0
	folders 0 "assignments/$REPO/"
    if [ $? -ne 0 ] ; then
		continue
	fi
	# rest files is all files minus txt files 
    RESTFILES=$(echo "$ALLFILES-$FILES" | bc)
	echo "$REPO:"
	echo "Number of directories:: $FOLDERS"
    echo "Number of txt files: $FILES"
	echo "Number of other files: $RESTFILES"
	# now i also check the structure if it has more files or folders than allowed
	if [ "$FOLDERS" -ne 1 ] || [ "$FILES" -ne 3 ] || [ "$RESTFILES" -ne 0] ; then
		STRUCTURE=0
	fi
	if [ $STRUCTURE -eq 1 ] ; then
		echo "Directory structure is OK"
	else
		>&2 echo "Directory structure is NOT OK"
	fi
done