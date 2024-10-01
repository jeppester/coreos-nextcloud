#!/usr/bin bash
echo "Checking for backup";
duplicity collection-status --s3-endpoint-url ${AWS_ENDPOINT_URL} --s3-region-name ${AWS_REGION} ${AWS_BUCKET} | grep "Found primary backup"
FOUND_BACKUP=$?;

if [ $FOUND_BACKUP -eq 0 ]; then
  echo "Backup present";
  echo "Emptying state to prepare for restore";
  rm -rf /state/*
  echo "Restoring backup"
  duplicity restore --s3-endpoint-url ${AWS_ENDPOINT_URL} --s3-region-name ${AWS_REGION} ${AWS_BUCKET} /state;
  exit $?;
else
  echo "Backup not present, continuing";
  exit 0;
fi
