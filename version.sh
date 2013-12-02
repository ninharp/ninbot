#!/bin/sh
DIR=/home/michael/workspace/ninbot
VER_FILE=$DIR/VERSION
VERSION=$(cat $VER_FILE)
echo $DIR
F_VER=$(echo $VERSION |cut -d'.' -f1)
S_VER=$(echo $VERSION |cut -d'.' -f2)
SUBVER=$(echo $VERSION |cut -d'.' -f3)
SUBVER=$(( $SUBVER + 1 ))
echo $F_VER.$S_VER.$SUBVER > $VER_FILE
