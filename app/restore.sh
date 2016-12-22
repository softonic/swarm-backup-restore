#!/bin/bash

if [ ! -z $1 ]
then
	echo "Invalid Usage. Example Usage: $0 http://domain.com/my_backup.tar.gz"
fi

# Download and extract the stacks to be applied.
curl "$1" -o restore.tar.gz
tar xvzf
rm restore.tar.gz

# Apply stacks to be restored
/app/whaleprint apply
 *.dab