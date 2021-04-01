# shellcheck disable=2034
# Disable shellcheck warnings about unused variables since the whole
# purpose of this script is to set variables which *might* be used

# Hey, listen dude... I am not going to call tput 21 times
_seq='0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7'

# Disable shellcheck warning about globbing/word splitting and not passing
# enough arguments to printf. We use word splitting to pass an entire
# sequence as arguments
# shellcheck disable=2086,2183
read -r fg0 bg0 fg1 bg1 fg2 bg2 fg3 bg3 \
        fg4 bg4 fg5 bg5 fg6 bg6 fg7 bg7 \
        rst bld it  ul  rev <<EOF
$(printf '\033[3%sm \033[4%s ' $_seq
  printf '\033[0m \033[1m \033[3m \033[4m \033[7m')
EOF
unset _seq
