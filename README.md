# S3 with Email Event
Upload files to S3 send email notification based on tags using Amazon Simple Email Service.


### Context
We have a shared S3 bucket across three departments: IT, Finance and HR.

Once an user puts a file into the bucket, a lambda will be triggered and send an email to recipients from a department, stored in a DynamoDB table. File needs to have `Owner` flag indicating which department it belongs to.

### Requirements
- Terraform
- AWS Account
- AWS CLI

### Set Up
1. Copy the content of `terraform.tfvars.sample` into a new file called `terraform.tfvars` and replace values with desired ones. 
2. `terraform init`
3. `terraform plan`
4. `terraform apply`
5. You will receive an email from AWS to validate identity of your email to be used for sending messages.
6. Create a recipient email into DynamoDB table:

```bash
aws dynamodb put-item --table-name S3UploadEmailRecipients \
    --item '{"Owner": {"S": "IT"}, "Emails": {"L": [{"S": "<email1>"}, {"S": "<email2>"}]}}'
```

**WARNING**: This POC uses SES in sandbox mode, so you will need to verify identities from each receipient email.

```bash
aws ses verify-email-identity --email-address <email1> --region <region>
```

7. Upload a file:
```bash
aws s3api put-object \
  --bucket <bucket> \
  --key <file_name_in_bucket> \
  --body <local_file> \
  --tagging "Owner=IT"
```

### Clean Up
```bash
terraform destroy
```
