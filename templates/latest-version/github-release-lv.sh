#!/usr/bin/env bash
# Latest Version check for a Git Release SLACKBUILD

LOCAL_PRGNAM="github-release"
LOCAL_VERSION="0.1"

SLACKBUILD="${SLACKBUILD:-}"
REPO_CATEGORY="${REPO_CATEGORY:-}"
GIT_REPO="${GIT_REPO:-}"
GIT_NAME="${GIT_NAME:-$SLACKBUILD}"
REPO_DIR="${REPO_DIR:-.}"
SLKBLD_DIR="${SLKBLD_DIR:-$REPO_DIR/$REPO_CATEGORY/$SLACKBUILD}"
UPLOAD_DIR="${UPLOAD_DIR:-/tmp/$LOCAL_PRGNM}"
LATEST_VERSION="${LATEST_VERSION:-}"

set -e

usage() {
    printf "%s: Version:%s\n\n\
        Usage: %s -s <slackbuild> -c <category> -r <git repo>\n\n\
        Optional: -n <git-name> -d <slackbuild-dir> -u <upload-dir> -l <latest-version>\n" \
        "$LOCAL_PRGNAM" "$LOCAL_VERSION" "$LOCAL_PRGNAM"
}


printerr() {
    printf "Error: %s" "$1"
}


prompt_yn() {
    read -p "$1" confirm
    case $confirm in
        [Yy]* )
	    return 0
	    ;;
	[Nn]* )
        return 1
	    ;;
	    * )
	    echo "Invalid response."
	    exit 1
	    ;;
    esac
}

source_info () {

    if [ -d "$SLKBLD_DIR" ]; then
        cd "$SLKBLD_DIR" >/dev/null
    else
        printerr "Cannot find $SLKBLD_DIR"
        exit 1
    fi

    if [ -f $SLACKBUILD.info ]; then
        . $SLACKBUILD.info
    else
        printerr "Cannot find $SLACKBUILD.info"
        exit 1
    fi
}


get_latest_version () {
    # Get latest version automatically
    LATEST_VERSION="$(curl -s \
        https://api.github.com/repos/$GIT_REPO/$GIT_NAME/releases/latest \
    | grep -Po '"tag_name": "\K.*?(?=")' | sed -e 's/v//1')"

}

prepare_upload () {
    __upload_file="$UPLOAD_DIR/$SLACKBUILD.tar.gz"
        cd ..
        mkdir -p "$UPLOAD_DIR"
        tar -czvf "$__upload_file" "$SLACKBUILD"
        printf "%s is ready to be submitted from %s.\n" \
            "$SLACKBUILD" "$__upload_file"
}

update () {
    
    # Update the VERSION in info and SLACKBUILD
    sed -i "s|$VERSION|$LATEST_VERSION|g" "$SLACKBUILD".{info,SLACKBUILD} 

    # Re-source the info file with the updated variables
    . "$SLACKBUILD".info

    if [ "$DOWNLOAD" ]; then
	__dl_array=($DOWNLOAD)
	__oldmd5=($MD5SUM)
	for i in "${!__dl_array[@]}"; do
		__newmd5=$(curl -sL ${__dl_array[$i]} | md5sum | cut -d ' ' -f 1)
		if [ $? -ne 0 ]; then
		    echo "Error downloading ${__dl_array[$i]}"
		    exit 1
		fi
		sed -i "s|${__oldmd5[$i]}|${__newmd5}|g" "$SLACKBUILD".info 
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
		sed -i "s|${__oldmd564[$i]}|${__newmd564}|g" "$SLACKBUILD".info 
	done
    fi

    sbolint || exit 1
    prepare_upload

}

check_exists () {
    __req_var=("$@")

    for i in "${__req_var[@]}"; do
        if [ -z "$i" ]; then
            return 1
        fi
    done
    return 0
}


main () {

    while [ $# -gt 0 ]; do
        case $1 in
            -s|--slackbuild)
                SLACKBUILD="$2"
                shift 2
                ;;
            -c|--category)
                REPO_CATEGORY="$2"
                shift 2
                ;;
            -r|--git-repo)
                GIT_REPO="$2"
                shift 2
                ;;
            -n|--git-name)
                GIT_NAME="$2"
                shift 2
                ;;
            -d|--slackbuild-dir)
                SLKBLD_DIR="$2"
                shift 2
                ;;
            -u|--upload-dir)
                UPLOAD_DIR="$2"
                shift 2
                ;;
            -l|--latest-version)
                LATEST_VERSION="$2"
                shift 2
                ;;
            *)
                usage
                exit 1
                ;;
        esac
    done

    if ! check_exists "$SLACKBUILD" "$REPO_CATEGORY" "$GIT_REPO"; then
        usage
        exit 1
    fi

    source_info

    if ! check_exists "$LATEST_VERSION"; then
        get_latest_version
    fi

    if [ "$LATEST_VERSION" != "$VERSION" ]; then
        if prompt_yn "Do you want to update $SLACKBUILD from $VERSION to $LATEST_VERSION? "; then
            update
        fi
    elif [ "$LATEST_VERSION" = "$VERSION" ]; then
        echo "$SLACKBUILD is at latest version ($VERSION)."
        if prompt_yn "Do you want to create an upload tar for $SLACKBUILD?"; then
            prepare_upload
        fi
    else
        printerr "Cannot check version."
        exit 1
    fi

}

main $@
