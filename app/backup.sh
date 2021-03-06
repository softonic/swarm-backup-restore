#!/bin/bash

if [ -z $BUCKET -o -z $REGION -o -z $AWS_KEY_ID_SECRET -o -z $AWS_ACCESS_KEY_SECRET ]
then
	echo "BUCKET/REGION/AWS_KEY_ID_SECRET/AWS_ACCESS_KEY_SECRET env variables not declared.";
	exit 1;
fi

AWS_ACCESS_KEY=$(cat /run/secrets/$AWS_ACCESS_KEY_SECRET)
AWS_KEY_ID=$(cat /run/secrets/$AWS_KEY_ID_SECRET)

function upload {
	objectName=$1
	file=$2
	region=$3
	bucket=$4
	s3Key=$5
	s3Secret=$6

	resource="/${bucket}/${objectName}"
	contentType="text/plain"
	dateValue=`date -R`
	stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
	signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`

	curl -v -i -X PUT -T "${file}" \
		  -H "Host: ${bucket}.$region.amazonaws.com" \
		  -H "Date: ${dateValue}" \
		  -H "Content-Type: ${contentType}" \
		  -H "Authorization: AWS ${s3Key}:${signature}" \
		  https://${bucket}.$region.amazonaws.com/${objectName}
}

/app/whaleprint export

if [ ! -z $IGNORE_STACKS ]
then
	OFS=$IFS
	IFS=","
	for stack in $IGNORE_STACKS
	do
			rm "${stack}.dab"
	done
	IFS=$OFS
fi

TARNAME=$(date +"%s").tar.gz
OBJECT_NAME="$TARNAME"
if [ ! -z $NAMESPACE ]
then
	OBJECT_NAME="$NAMESPACE/$TARNAME"
fi

tar cvzf $TARNAME *.dab
rm *.dab

upload "$OBJECT_NAME" "/app/$TARNAME" "$REGION" "$BUCKET" "$AWS_KEY_ID" "$AWS_ACCESS_KEY"
