#!/usr/bin/env bash
# Git Release Template

slackbuild="mergerfs"
repo_category="system"
git_repo="trapexit"
git_name="$slackbuild"

latest_version="${latest_version:-}"

working_dir="$repo_category/$slackbuild"
upload_dir="/tmp/slackbuild-uploads"

set -e

source_info () {

    if [ -d "$working_dir" ]; then
        cd "$working_dir" >/dev/null
    else
        echo "cannot find $working_dir"
        exit 1
    fi

    if [ -f $slackbuild.info ]; then
        . $slackbuild.info
    else
        echo "Cannot find $slackbuild.info"
        exit 1
    fi
}

get_latest_version () {
    # Get latest version automatically
    latest_version="$(curl -s \
        https://api.github.com/repos/$git_repo/$git_name/releases/latest \
        | grep -Po '"tag_name": "\K.*?(?=")' | sed -e 's/v//1')"
}

update () {
    
    # Update the VERSION in info and Slackbuild
    sed -i "s|$VERSION|$latest_version|g" "$slackbuild".{info,SlackBuild} 

    # Re-source the info file with the updated variables
    . "$slackbuild".info

    if [ "$DOWNLOAD" ]; then
	__dl_array=($DOWNLOAD)
	__oldmd5=($MD5SUM)
	for i in "${!__dl_array[@]}"; do
		__newmd5=$(curl -sL ${__dl_array[$i]} | md5sum | cut -d ' ' -f 1)
		if [ $? -ne 0 ]; then
		    echo "Error downloading ${__dl_array[$i]}"
		    exit 1
		fi
		sed -i "s|${__oldmd5[$i]}|${__newmd5}|g" "$slackbuild".info 
	done
    fi

    if [ "$DOWNLOAD_x86_64" ]; then
	__dl_array64=($DOWNLOAD_x86_64)
	__oldmd564=($MD5SUM_x86_64)
	for i in "${!__dl_array64[@]}"; do
		__newmd564=$(curl -sL ${__dl_array64[$i]} | md5sum | cut -d ' ' -f 1)
		if [ $? -ne 0 ]; then
		    echo "Error downloading ${__dl_array64[$i]}"
		    exit 1
		fi
		sed -i "s|${__oldmd564[$i]}|${__newmd564}|g" "$slackbuild".info 
	done
    fi

    sbolint || exit 1

}

prompt () {
    read -p "Do you want to update $slackbuild from $VERSION to $latest_version? " confirm
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

prepare_upload () {
    __upload_file="$upload_dir/$slackbuild.tar.gz"
    if [ ! -e $__upload_file ]; then
        cd ..
        mkdir -p "$upload_dir"
        tar -czvf "$__upload_file" "$slackbuild"
        printf "%s is ready to be submitted from %s.\n" \
            "$slackbuild" "$__upload_file"
    fi
}

main () {
    source_info
    get_latest_version

    if [ "$latest_version" != "$VERSION" ]; then
        prompt
    elif [ "$latest_version" = "$VERSION" ]; then
        echo "$slackbuild is at latest version ($VERSION)."
    else
        echo "Error checking version."
        exit 1
    fi

    prepare_upload
}

main $@
