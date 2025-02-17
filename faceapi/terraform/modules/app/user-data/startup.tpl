#!/bin/bash
sleep 5
cd /home/ubuntu/

sed -i "s/AWS_REGION/${AWS_REGION}/g" /home/ubuntu/config.yaml
sed -i "s/WORKER_COUNT/${WORKER_COUNT}/g" /home/ubuntu/config.yaml
sed -i "s/DB_USERNAME/${DB_USERNAME}/g" /home/ubuntu/config.yaml
sed -i "s/DB_PASSD/${DB_PASSD}/g" /home/ubuntu/config.yaml
sed -i "s/DB_NAME/${DB_NAME}/g" /home/ubuntu/config.yaml
sed -i "s/DB_HOST/${DB_HOST}/g" /home/ubuntu/config.yaml
sed -i "s/S3_BUCKET_DETECT_MATCH_NAME/${S3_BUCKET_DETECT_MATCH_NAME}/g" /home/ubuntu/config.yaml
sed -i "s/S3_BUCKET_LIVENESS_NAME/${S3_BUCKET_LIVENESS_NAME}/g" /home/ubuntu/config.yaml

docker compose up -d
sleep 30
