#!/usr/bin bash
echo "Back up start"
duplicity --full-if-older-than $FULL_IF_OLDER_THAN --s3-endpoint-url $AWS_ENDPOINT_URL --s3-region-name $AWS_REGION --volsize $VOLUME_SIZE --allow-source-mismatch /state $AWS_BUCKET
echo "Back up end"

echo "Deleting old backups start"
duplicity remove-older-than $REMOVE_OLDER_THAN --force --s3-endpoint-url $AWS_ENDPOINT_URL --s3-region-name $AWS_REGION $AWS_BUCKET
echo "Deleting old backups end"

echo "Deleting noncurrent incremental backups start"
duplicity remove-all-inc-of-but-n-full $KEEP_INCS_FOR_FULL_BACKUPS --force --s3-endpoint-url $AWS_ENDPOINT_URL --s3-region-name $AWS_REGION $AWS_BUCKET
echo "Deleting noncurrent incremental backups end"
