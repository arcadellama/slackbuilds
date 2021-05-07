#!/bin/sh

fetch() {
wget -q -O "$2" "$1"
}

version=$(fetch https://channels-dvr.s3.amazonaws.com/latest.txt -)
echo $version
