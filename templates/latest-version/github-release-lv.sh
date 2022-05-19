#!/usr/bin/env bash
# Latest Version check for a Git Release slackbuild

# Global
prgnam="github-release"
prgnam_version="0.1"

# Required options
slackbuild="${slackbuild:-}"
repo_category="${repo_category:-}"
git_repo="${git_repo:-}"

# Optional with defaults
git_name="${git_name:-$slackbuild}"
latest_version="${latest_version:-}"

# Environment defaults
repo_dir="${repo_dir:-.}"
slkbld_dir="${slkbld_dir:-$repo_dir/$repo_category/$slackbuild}"
upload_dir="${upload_dir:-/tmp/$LOCAL_PRGNM}"

latest_commit="${latest_commit:-}"
latest_commit_date="${latest_commit_date:-}"

set -e

usage () {
    printf "%s: Version:%s\n\n\
        Usage: %s -s <slackbuild> -c <category> -r <git repo>\n\n\
        Optional: -n <git-name> -d <slackbuild-dir> -u <upload-dir> -l\
        <latest-version>\n" \
        "$prgnam" "$prgnam_version" "$prgnam"
}


print_err () {
    printf "Error: %s" "$1"
}


prompt_yn () {
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

check_exists () {
    __req_var=("$@")

    for i in "${__req_var[@]}"; do
        if [ -z "$i" ]; then
            return 1
        fi
    done
    return 0
}

is_commit () {
    grep -q "COMMIT=" "$slkbld_dir/$slackbuild.SlackBuild"
    return $?
}

source_info () {

    if [ -d "$slkbld_dir" ]; then
        cd "$slkbld_dir" >/dev/null
    else
        print_err "Cannot find $slkbld_dir."
        exit 1
    fi

    if [ -f $slackbuild.info ]; then
        . $slackbuild.info
    else
        print_err "Cannot find $slackbuild.info"
        exit 1
    fi
}

get_latest_version () {

    if is_commit; then
        # Get latest github COMMIT version
        latest_commit_date=\
            "$(curl -s \
            https://api.github.com/repos/$git_repo/$git_name/commits/main \
            | grep '"date"' \
            | tail -n 1 \
            | tr -d " \"" \
            | cut -d : -f 2 \
            | cut -d T -f 1 \
            | tr -d "-")" # must be a cleaner way???

        latest_commit=\
            "$(git ls-remote https://github.com/$git_repo/$slackbuild main \
            | awk '{print $1}')"

        latest_version="$latest_commit_date"_"$(first_seven $latest_commit)"
    else
        # Get latest github RELEASE version
        latest_version="$(curl -s \
        https://api.github.com/repos/$git_repo/$git_name/releases/latest \
        | grep -Po '"tag_name": "\K.*?(?=")' | sed -e 's/v//1')"

    fi

}

prepare_upload () {
    __upload_file="$upload_dir/$slackbuild.tar.gz"
        cd ..
        mkdir -p "$upload_dir"
        tar -czvf "$__upload_file" "$slackbuild"
        printf "%s is ready to be submitted from %s.\n" \
            "$slackbuild" "$__upload_file"
}

update () {
    
    # Update the VERSION in info and slackbuild
    sed -i "s|$VERSION|$latest_version|g" "$slackbuild".{info,slackbuild} 

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
    prepare_upload

}


main () {

    while [ $# -gt 0 ]; do
        case $1 in
            -s|--slackbuild)
                slackbuild="$2"
                shift 2
                ;;
            -c|--category)
                repo_category="$2"
                shift 2
                ;;
            -r|--git-repo)
                git_repo="$2"
                shift 2
                ;;
            -n|--git-name)
                git_name="$2"
                shift 2
                ;;
            -d|--slackbuild-dir)
                slkbld_dir="$2"
                shift 2
                ;;
            -u|--upload-dir)
                upload_dir="$2"
                shift 2
                ;;
            -l|--latest-version)
                latest_version="$2"
                shift 2
                ;;
            *)
                usage
                exit 1
                ;;
        esac
    done

    if ! check_exists "$slackbuild" "$repo_category" "$git_repo"; then
        usage
        exit 1
    fi

    source_info

    if ! check_exists "$latest_version"; then
        get_latest_version
    fi

    if [ "$latest_version" != "$VERSION" ]; then
        if prompt_yn \
            "Update $slackbuild from $VERSION to $latest_version? "; then
            update
        fi
    elif [ "$latest_version" = "$VERSION" ]; then
        printf "%s is at latest version (%s).\n" "$slackbuild" "$VERSION"
        if prompt_yn \
            "Create an upload tar for $slackbuild? "; then
            prepare_upload
        fi
    else
        print_err "Cannot check version of $slackbuild."
        exit 1
    fi

}

main $@
