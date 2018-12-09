#! /usr/bin/env bash
mkdir extracted &> /dev/null
FOLDERS=0
S=1
FILES=0
ALLFILES=0
EXIT=1
# 1 depth  #2 folder path
folders() {
	echo $2
	ls -1 $2 &> /dev/null
	if [ $? -ne 0 ] ; then
		EXIT=0
		return 1
	fi
	for FILE in $(find $2 -maxdepth 1 -type f) ; do
		ALLFILES=$(echo "$ALLFILES+1" | bc)
	done
	for FILE in $(find $2 -maxdepth 1 -type f | grep  '\.txt$' ) ; do
		#echo "here"
		FILES=$(echo "$FILES+1" | bc)
	done
	#echo "FILES $1: $FILES" 
	find $2 -maxdepth 1 -type d &> /dev/null 
	if [ $? -eq 0 ]
	then 
	 	local TEMP1=`find $2 -maxdepth 1 -type d`
		
		for D in  $TEMP1
		 do
			if [ "$D" = "$2.git" ] || [ "$D" = "$2" ] ; 
			then 
				continue
			fi
			#local R=
			#echo $D
			#sleep 2
			FOLDERS=$(echo "$FOLDERS+1" | bc)
			folders $(echo "$1 +1" | bc)  "$D"
		done 
	fi
	EXIT=1
}

#folders 0 ""

tar -xzf new1.tar.gz -C extracted/  &> /dev/null

mkdir assignments &> /dev/null
REPOS=()
POS=0
for FILE2 in $(find extracted/ | tr " " "\n" | grep '\.txt$') ; do
	HTTP=$(grep '^https*' $FILE2 | head -1)
	REPOS[$POS]=$HTTP
    POS=$(echo "$POS+1" | bc)
	if [ "$HTTP" != "" ] ; then
		git -C assignments/ clone $HTTP &> /dev/null
	       	if [ $? -eq 0 ] ; then
				echo "$HTTP: Cloning OK"
			else
				echo "$HTTP: Cloning FAILED"
		fi
		##############
	fi

done

for i in ${REPOS[@]} ; do 
	STRUCTURE=1
	REPO="${i##*/}"
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
	FILES=0
	FOLDERS=0
	ALLFILES=0
	folders 0 "assignments/$REPO/"
    if [ $? -ne 0 ] ; then
		continue
	fi
	# ALLFILES=$(find assignments/$REPO/ \( ! -regex '.*/\..*' \) -type f | wc -l)
    RESTFILES=$(echo "$ALLFILES-$FILES" | bc)
	echo "$REPO:"
	echo "Number of directories:: $FOLDERS"
        echo "Number of txt files: $FILES"
	echo "Number of other files: $RESTFILES"
	if [ $STRUCTURE -eq 1 ] ; then
		echo "Directory structure is OK"
	else
		echo "Directory structure is NOT OK"
	fi
	
done

