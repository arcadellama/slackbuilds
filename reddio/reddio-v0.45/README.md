# reddio

reddio is a command-line interface for Reddit written in POSIX sh.

![example session](example.png?raw=true "Example session")

## Why

Terminal user interfaces suck. Because `reddio` is command-line only, it's way more flexible than a TUI and integrates much better with other command-line utilities.

## Dependencies

* A POSIX compliant shell as `/bin/sh`
* `coreutils` (GNU, busybox or others should work)
* `cURL`
* `jq`
* `netcat` optional (for authentication)

## Installation

### Automatic installation

#### Arch

AUR package is available [here](https://aur.archlinux.org/packages/reddio/).

### Manual installation

By default, reddio is installed to `/usr/local/bin` and `/usr/local/share`.

```shell
make install
```

Use the `PREFIX` environment variable to install it elsewhere.

```shell
PREFIX="$HOME"/.local make install
```

In order to enable `reddio` to locate the library directory at a different location, the `REDDIO_LIB` environment variable can be used.

```shell
export REDDIO_LIB="$HOME"/.local/share/reddio
```

Alternatively, set the `lib_dir` variable in the config file.

```shell
mkdir -p -- "$HOME"/.config/reddio
echo 'lib_dir="$HOME"/.local/share/reddio' \
     >>"$_"/config
```

The environment variable has precedence over the config setting.

## Usage

```
reddio [-chqvV] [<command> [<args>]]

  -c <file>    Use <file> instead of the default config
  -s <session> Use <session> instead of the default
  -q           Quiet
  -v           Verbose mode
  -V           Print version information and exit
  -h           Print this help and exit

Commands:
  comment delete edit login logout message print submit
  (un)follow (un)hide (un)marknsfw (un)read (un)save
  (un)spoiler (un)subscribe upvote downvote unvote.

A unique part, of the beginning of the command, is also valid. For
example, 'p' for print or 'logi' for login.
```

All sub-commands also have a `-h` option for printing usage information.

## Examples

Print the two hottest submissions of r/commandline

```shell
$ reddio print -l 2 r/commandline
18 Suggestions on mp3 streams for background music (self.commandline)
https://www.reddit.com/r/commandline/comments/cdfq7p/suggestions_on_mp3_streams_for_background_music/
14 comments | submitted 8.4 hours ago by jherazob to r/commandline t3_cdfq7p

16 Βulk image resizing (cli) (youtube.com)
https://www.youtube.com/attribution_link?a=NkwKg-k3QY0&u=%2Fwatch%3Fv%3DidyBFtocLaU%26feature%3Dshare
11 comments | submitted 1.2 days ago by vagelis_prokopiou to r/commandline t3_cd2zfg
```

Count the words of a self-post

```shell
$ reddio print -f '$text' by_id/t3_cdfq7p | wc -w
156
```

Print the top 5 urls of the month of r/linux

```shell
$ reddio print -f '$num. $url$nl' -l 5 -t month r/linux/top
1. https://i.redd.it/edqgfmhoew431.jpg
2. https://twitter.com/ISPAUK/status/1146725374455373824
3. https://www.raspberrypi.org/blog/raspberry-pi-4-on-sale-now-from-35/
4. https://i.redd.it/30c8yyn390a31.jpg
5. https://i.redd.it/6k5u6euppn931.jpg
```

Submit a selfpost to r/test

```shell
$ reddio submit -t 'Hello, World!' r/test 'Test submission using reddio - CLI reddit reader'
```

Check for new messages and comment replies

```shell
$ reddio print -l 1 -f '${new:+New message(s)!$nl}' message/unread
New message(s)!
```

More examples in [doc/examples](doc/examples). To learn about the available formatting variables, checkout [doc/formats.md](doc/formats.md).

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

MIT
