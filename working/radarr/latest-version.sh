#!/bin/bash
PRGNAM=$(basename $PWD)

set -e

#if [ "$1" ]; then
#    LATEST_VERSION="$1"
#else
#    echo "Usage: latest-version.sh VERSION"
#fi

LATEST_VERSION=$(curl -s https://api.github.com/repos/Radarr/Radarr/releases/latest \
    | grep -Po '"tag_name": "\K.*?(?=")' | sed -e 's/v//1')

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
    cat $PRGNAM.info > $PRGNAM.info.old
    cat $PRGNAM.SlackBuild > $PRGNAM.SlackBuild.old
    sed -i "s|${VERSION}|${LATEST_VERSION}|g" $PRGNAM.{info,SlackBuild} 
    . $PRGNAM.info

    if [ "$DOWNLOAD" ]; then
	DL_ARRAY=($DOWNLOAD)
	OLDMD5=($MD5SUM)
	for i in "${!DL_ARRAY[@]}"; do
		NEWMD5=$(curl -sL ${DL_ARRAY[$i]} | md5sum | cut -d ' ' -f 1)
		if [ $? -ne 0 ]; then
		    echo "Error downloading ${DL_ARRAY[$i]}"
		    exit 1
		fi
		sed -i "s|${OLDMD5[$i]}|${NEWMD5}|g" $PRGNAM.info 
	done
    fi

    if [ "$DOWNLOAD_x86_64" ]; then
	DL_ARRAY=($DOWNLOAD_x86_64)
	OLDMD5=($MD5SUM_x86_64)
	for i in "${!DL_ARRAY[@]}"; do
		NEWMD5=$(curl -sL ${DL_ARRAY[$i]} | md5sum | cut -d ' ' -f 1)
		if [ $? -ne 0 ]; then
		    echo "Error downloading ${DL_ARRAY[$i]}"
		    exit 1
		fi
		sed -i "s|${OLDMD5[$i]}|${NEWMD5}|g" $PRGNAM.info 
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
