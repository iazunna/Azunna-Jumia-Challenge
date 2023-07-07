#!/bin/bash

aws s3api create-bucket --bucket jumia-challenge-tf-bucket --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2

aws dynamodb create-table --table-name terraform-locks --region eu-west-2 \
    --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5