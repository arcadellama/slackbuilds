#!/bin/bash
PRGNAM=$(basename $PWD)

set -e

LATEST_VERSION=$(curl -s services.sonarr.tv/v1/download/latetst?version=3 | grep -oP '"version": *\K"[^"]*"' | sed 's/"//g')

if [ $? -ne 0 ]; then
    echo "Error getting latest version."
    exit 1
fi

if [ -f $PRGNAM.info ]; then
    . $PRGNAM.info
    else
	echo "Cannot find $PRGNAM.info"
	exit 1
fi

update () {
    sed -i "s|${VERSION}|${LATEST_VERSION}|g" $PRGNAM.* 
    . $PRGNAM.info

    if [ "$DOWNLOAD" ]; then
	DL_ARRAY=($DOWNLOAD)
	OLDMD5=($MD5SUM)
	for i in "${!DL_ARRAY[@]}"; do
		NEWMD5=$(curl -sL ${DL_ARRAY[$i]} | md5sum | cut -d ' ' -f 1)
		echo "i is $i"
		echo "DL_ARRAY is ${DL_ARRAY[$i]}"
		echo "OLDMD5 is ${OLDMD5[$i]} and NEWMD5 is $NEWMD5"
		sed -i "s|${OLDMD5[$i]}|${NEWMD5}|g" $PRGNAM.* 
	done
    fi

    if [ "$DOWNLOAD_x86_64" ]; then
	DL_ARRAY=($DOWNLOAD_x86_64)
	OLDMD5=($MD5SUM_x86_64)
	for i in "${!DL_ARRAY[@]}"; do
		NEWMD5=$(curl -sL ${DL_ARRAY[$i]} | md5sum | cut -d ' ' -f 1)
		sed -i "s|${OLDMD5[$i]}}|${NEWMD5}|g" $PRGNAM.* 
	done
    fi

}

prompt () {
    read -p "Do you want to update $PRGNAM from $VERSION to $LATEST_VERSION? " confirm
    case $confirm in
        [Yy]* )
	    update
	    ;;
	[Nn]* )
	    exit 0
	    ;;
	    * )
	    echo "Invalid response."
	    exit 1
	    ;;
    esac
}

if [ $LATEST_VERSION != $VERSION ]; then
    prompt
elif [ $LATEST_VERSION = $VERSION ]; then
    echo "$PRGNAM is at latest version ($VERSION)."
    exit 0
else
    echo "Error checking version."
    exit 1
fi

exit 0
