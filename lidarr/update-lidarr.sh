#!/bin/sh
PRGNAM=lidarr

set -e

LATEST_VERSION=$(curl -s https://api.github.com/repos/lidarr/Lidarr/releases/latest \
    | grep -Po '"tag_name": "\K.*?(?=")' | sed -e 's/v//1')

if [ $? -ne 0 ]; then
    echo "Error getting latest version."
    exit 1
fi

if [ -f $PWD/$PRGNAM.info ]; then
    . $PWD/$PRGNAM.info
    else
	echo "Cannot find $PRGNAM.info"
	exit 1
fi

update () {
    sed -i "s|${VERSION}|${LATEST_VERSION}|g" $PWD/$PRGNAM.* 

    if [ ! -z $DOWNLOAD ]; then
	NEW_MD5SUM=$(curl -sL $DOWNLOAD | md5sum | cut -d ' ' -f 1)
	sed -i 's/MD5SUM=.*/MD5SUM="'"$NEW_MD5SUM"'"/1' $PWD/$PRGNAM.info
    fi

    if [ ! -z $DOWNLOAD_x86_64 ]; then
	NEW_MD5SUM_x86_64=$(curl -sL $DOWNLOAD_x86_64 | md5sum | cut -d ' ' -f 1)
	sed -i 's/MD5SUM_x86_64=.*/MD5SUM_x86_64="'"$NEW_MD5SUM_x86_64"'"/1' $PWD/$PRGNAM.info
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
