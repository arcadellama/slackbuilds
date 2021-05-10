#!/bin/sh
PRGNAM=channels-dvr

set -e

LATEST_VERSION=$(wget -qO - https://channels-dvr.s3.amazonaws.com/latest.txt)
if [ $? -ne 0 ]; then
    echo "Error getting latest version."
    exit 1
fi

if [ -e $PRGNAM.info ]; then
    . $PRGNAM.info
    else
	echo "Cannot find $PRGNAM.info"
	exit 1
fi

update () {
    sed -e "s|${VERSION}|${LATEST_VERSION}|g" $PRGNAM.info > $PRGNAM.info
}

prompt () {
    read -p "Do you want to update $PRGNAM from $VERSION to $LATEST_VERSION? " confirm
    while true; do
	case $confirm in
	    [Yy]* )
		update
		exit 0
		;;
	    [Nn]* )
		exit 0
		;;
		* )
		echo "Invalid response."
		exit 1
		;;
	esac
    done
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
