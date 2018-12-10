#!/usr/bin/env bash
# Alexandros Spitalas AEM:2924
HFILE="$1"
find . -maxdepth 1 -type f | grep "^./$HFILE$" &>/dev/null
if [ $? -ne 0 ] ; then  
# if it doesnt find the file it exits
	exit
fi
find . -maxdepth 1 -type d | grep "^./.tempSites$" &>/dev/null 
# the folder that i save the sites so as to check for changes is thempSites and if it doesnt exist
# i create it here
if [ $? -ne 0 ] ; then 
	mkdir ".tempSites"
fi
NUM=$( grep -v '^ *#' $1 | grep -c '^http*' )
 # in NUM i hold the number of http files
touch htmlstemp
# i copy all the http sites to file htmlstemp
grep -v '^ *#' $HFILE | grep '^http*'  &> htmlstemp 

for ((c=1; c<=$NUM;c++))
do
	HTML=$(sed -n "$c p" htmlstemp)
	 # HTML holds the site
	TOFILE=$(echo $HTML | tr '/' '_s_')
	 # this holds the name of the file that i will save it
	ERROR=0
	 # check if any error happens at wget 
	wget -q $HTML -O "${TOFILE}newTemp" || ERROR=1 
	if [ $ERROR -eq 1 ]
	then 
	# if any error occurs i have to check if the site has been checked before (this happens in EXISTS)
		EXISTS=$(find .tempSites -maxdepth 1 -type f | grep -wc "^.tempSites/$TOFILE$" 2> /dev/null)
		if [ $EXISTS -eq 1 ]
		then
		# and also i have to check if it is the first time it failed or not
			if [ $(grep -c '^failed$' .tempSites/$TOFILE) -eq 0 ] ; then
				>&2 echo "$HTML FAILED" 
				echo "failed" > .tempSites/$TOFILE
			fi
		fi
		rm "${TOFILE}newTemp" 
		continue
	fi
	EXISTS=$(find .tempSites -maxdepth 1 -type f | grep -wc "^.tempSites/$TOFILE$" 2> /dev/null)
	# if there is no error i also have to check if site has been INIT so as to check for diferences
	if [ $EXISTS -eq 0 ]
	then
	# if it hasnt been checked before i initialize it and i create the file
		touch .tempSites/$TOFILE 
		cp "${TOFILE}newTemp"  .tempSites/$TOFILE 
		echo "$HTML INIT"
	else
	#else i compare them and write the apropriate result if it has changed
		CHANGED=0
		cmp --silent ".tempSites/$TOFILE" "${TOFILE}newTemp" || CHANGED=1
		if [ $CHANGED -eq 1 ] 
		then
			cp "${TOFILE}newTemp" .tempSites/$TOFILE
			echo "$HTML"
		fi
		
	fi
	rm ${TOFILE}newTemp

done

rm htmlstemp
