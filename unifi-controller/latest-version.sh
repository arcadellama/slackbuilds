#!/bin/bash
LOCKFILE=$HOME/.local/share/slackbuilds-latest-version/sblv.lock
PRGNAM=$(basename $PWD)
ONLINEVERSION=""
# Example
#ONLINEVERSION=$(curl -s https://api.github.com/repos/Radarr/Radarr/releases/latest \
#    | grep -Po '"tag_name": "\K.*?(?=")' | sed -e 's/v//1')

set -e

if [ "$1" ]; then
    LATEST_VERSION="$1"
elif
   [ "$ONLINEVERSION" ]; then
    LATEST_VERSION="$ONLINEVERSION"
elif
   [ -e "$LOCKFILE" ]; then
    echo "Skipping $PRGNAM"
    exit 0
else
    echo "Usage: $(basename $0) VERSION"
    exit 1
fi

if [ -f $PRGNAM.info ]; then
    source $PRGNAM.info
    else
	echo "Cannot find $PRGNAM.info"
	exit 1
fi

update () {
    cat $PRGNAM.info > $PRGNAM.info.old
    cat $PRGNAM.SlackBuild > $PRGNAM.SlackBuild.old
    sed -i "s|${VERSION}|${LATEST_VERSION}|g" $PRGNAM.{info,SlackBuild} 
    . $PRGNAM.info

    if [ "$MD5SUM" ]; then
	DL_ARRAY=($DOWNLOAD)
	OLDMD5=($MD5SUM)
	for i in "${!DL_ARRAY[@]}"; do
		NEWMD5=$(curl -sL ${DL_ARRAY[$i]} | md5sum | cut -d ' ' -f 1)
		sed -i "s|${OLDMD5[$i]}|${NEWMD5}|g" $PRGNAM.info 
	done
    fi

    if [ "$MD5SUM_x86_64" ]; then
	DL_ARRAY=($DOWNLOAD_x86_64)
	OLDMD5=($MD5SUM_x86_64)
	for i in "${!DL_ARRAY[@]}"; do
		NEWMD5=$(curl -sL ${DL_ARRAY[$i]} | md5sum | cut -d ' ' -f 1)
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

if [ "$LATEST_VERSION" != "$VERSION" ]; then
    prompt
elif [ "$LATEST_VERSION" == "$VERSION" ]; then
    echo "$PRGNAM is at latest version ($VERSION)."
    exit 0
else
    echo "Error checking version."
    exit 1
fi

exit 0
