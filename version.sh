#!/bin/sh

# --- Safety check
if [ -z "$GIT_DIR" ]; then
	echo "Don't run this script from the command line." >&2
	echo " (if you want, you could supply GIT_DIR then run" >&2
	exit 1
fi
VER_FILE=$GIT_DIR/../VERSION
VERSION=$(cat $VER_FILE)
echo $GIT_DIR
F_VER=$(echo $VERSION |cut -d'.' -f1)
S_VER=$(echo $VERSION |cut -d'.' -f2)
SUBVER=$(echo $VERSION |cut -d'.' -f3)
SUBVER=$(( $SUBVER + 1 ))
echo $F_VER.$S_VER.$SUBVER > $VER_FILE
