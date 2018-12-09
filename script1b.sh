#!/usr/bin/env bash
function htmlfun(){
	local HTML=$(sed -n "$c p" htmlstemp)
	local TOFILE=$(echo $HTML | tr '/' '_s_')
	local ERROR=0
	wget -q $HTML -O "${TOFILE}newTemp" || ERROR=1 
	if [ $ERROR -eq 1 ]
	then
		EXISTS=$(find .tempSites -maxdepth 1 -type f | grep -wc "^.tempSites/$TOFILE$" 2> /dev/null)
		if [ $EXISTS -eq 1 ]
		then
			if [ $(grep -c '^failed$' .tempSites/$TOFILE) -eq 0 ] ; then
				>&2 echo "$HTML FAILED" 
				echo "failed" > .tempSites/$TOFILE
			fi
		fi
		rm "${TOFILE}newTemp"
		return
	fi

	EXISTS=$(find .tempSites -maxdepth 1 -type f | grep -wc "^.tempSites/$TOFILE$" 2> /dev/null)
	if [ $EXISTS -eq 0 ]
	then
		touch .tempSites/$TOFILE
		cp "${TOFILE}newTemp"  .tempSites/$TOFILE 
		echo "$HTML INIT"
	else
		local CHANGED=0
		cmp --silent ".tempSites/$TOFILE" "${TOFILE}newTemp" || CHANGED=1
		if [ $CHANGED -eq 1 ] 
		then
			cp "${TOFILE}newTemp" .tempSites/$TOFILE
			echo "$HTML"
		fi
		
	fi
	rm "${TOFILE}newTemp"
}
HFILE="$1"
ls | grep "^$HFILE$" &> /dev/null
if [ $? -ne 0 ] ; then 
###################
	exit
fi
find . -maxdepth 1 -type d | grep "^./.tempSites$" &>/dev/null
if [ $? -ne 0 ] ; then 
	mkdir ".tempSites"
fi
NUM=$( grep -v '^ *#' $1 | grep -c '^http*' )
touch htmlstemp
grep -v '^ *#' $HFILE | grep '^http*'  > htmlstemp

for ((c=1; c<=$NUM;c++))
do
    htmlfun &
done
wait
rm htmlstemp

