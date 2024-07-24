#!/bin/bash
ACCOUNT_ID=aws sts get-caller-identity --query Account --output text
aws ecr get-login-password --region $2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$2.amazonaws.com
docker build -t $1 .
docker tag $1:latest $ACCOUNT_ID.dkr.ecr.$2.amazonaws.com/$1:latest
docker push $ACCOUNT_ID.dkr.ecr.$2.amazonaws.com/$1:latest