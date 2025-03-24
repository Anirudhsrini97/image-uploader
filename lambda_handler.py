import json
import boto3

def lambda_handler(event, context):
    s3_client = boto3.client("s3")

    for record in event["Records"]:
        bucket_name = record["s3"]["bucket"]["name"]
        file_key = record["s3"]["object"]["key"]

        print(f"New file uploaded: {file_key} in bucket: {bucket_name}")

        # Process file (example: read file contents)
        response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
        file_content = response["Body"].read().decode("utf-8")

        print(f"File content: {file_content}")  # Debug log

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda executed successfully!")
    }
