#!/bin/bash
##############################################################################
# Script to list resources in an AWS account and email the details.
# Author    : DK
# Version   : v1.1.0
#
# Supported AWS services:
# ec2, s3, rds, lambda, dynamodb, sns, vpc, cloudfront, cloudwatch,
# cloudformation, iam, ebs, elb
#
# Usage: ./Aws_resource_list_with_email.sh <region> <service_name> <email>
# Example: ./Aws_resource_list_with_email.sh us-east-1 ec2 your-email@example.com
##############################################################################

# Validate the number of arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <region> <service_name> <email>"
    echo "Example: $0 us-east-1 ec2 your-email@example.com"
    exit 1
fi

# Assign arguments to variables
REGION=$1
SERVICE=$2
EMAIL=$3

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it and try again."
    exit 1
fi

# Check if AWS CLI is configured
if [ ! -d "$HOME/.aws" ]; then
    echo "AWS CLI is not configured. Please configure it and try again."
    exit 1
fi

# Temporary file for storing service details
OUTPUT_FILE="/tmp/aws_${SERVICE}_details.txt"

# AWS service handler using case statement
case $SERVICE in
    ec2)
        echo "Fetching EC2 Instances in region: $REGION"
        aws ec2 describe-instances --region "$REGION" > "$OUTPUT_FILE"
        ;;
    s3)
        echo "Fetching S3 Buckets"
        aws s3api list-buckets --query 'Buckets[].Name' > "$OUTPUT_FILE"
        ;;
    rds)
        echo "Fetching RDS Instances in region: $REGION"
        aws rds describe-db-instances --region "$REGION" > "$OUTPUT_FILE"
        ;;
    dynamodb)
        echo "Fetching DynamoDB Tables in region: $REGION"
        aws dynamodb list-tables --region "$REGION" > "$OUTPUT_FILE"
        ;;
    lambda)
        echo "Fetching Lambda Functions in region: $REGION"
        aws lambda list-functions --region "$REGION" > "$OUTPUT_FILE"
        ;;
    sns)
        echo "Fetching SNS Topics in region: $REGION"
        aws sns list-topics --region "$REGION" > "$OUTPUT_FILE"
        ;;
    vpc)
        echo "Fetching VPCs in region: $REGION"
        aws ec2 describe-vpcs --region "$REGION" > "$OUTPUT_FILE"
        ;;
    cloudfront)
        echo "Fetching CloudFront Distributions"
        aws cloudfront list-distributions > "$OUTPUT_FILE"
        ;;
    cloudwatch)
        echo "Fetching CloudWatch Metrics in region: $REGION"
        aws cloudwatch list-metrics --region "$REGION" > "$OUTPUT_FILE"
        ;;
    cloudformation)
        echo "Fetching CloudFormation Stacks in region: $REGION"
        aws cloudformation list-stacks --region "$REGION" > "$OUTPUT_FILE"
        ;;
    iam)
        echo "Fetching IAM Users"
        aws iam list-users > "$OUTPUT_FILE"
        ;;
    ebs)
        echo "Fetching EBS Volumes in region: $REGION"
        aws ec2 describe-volumes --region "$REGION" > "$OUTPUT_FILE"
        ;;
    elb)
        echo "Fetching Elastic Load Balancers in region: $REGION"
        aws elbv2 describe-load-balancers --region "$REGION" > "$OUTPUT_FILE"
        ;;
    *)
        echo "Error: Unsupported service '$SERVICE'"
        echo "Supported services: ec2, s3, rds, dynamodb, lambda, sns, vpc, cloudfront, cloudwatch, cloudformation, iam, ebs, elb"
        exit 2
        ;;
esac

# Email the output file
echo "Sending service details to $EMAIL"
if command -v mailx &> /dev/null; then
    cat "$OUTPUT_FILE" | mailx -s "AWS $SERVICE Details in $REGION" -a "$OUTPUT_FILE" "$EMAIL"
elif command -v sendmail &> /dev/null; then
    (
        echo "Subject: AWS $SERVICE Details in $REGION"
        echo "To: $EMAIL"
        echo
        cat "$OUTPUT_FILE"
    ) | sendmail "$EMAIL"
else
    echo "Error: No mail utility found. Please install 'mailx' or 'sendmail'."
    rm -f "$OUTPUT_FILE"
    exit 1
fi

# Cleanup
rm -f "$OUTPUT_FILE"
echo "Script completed successfully."
