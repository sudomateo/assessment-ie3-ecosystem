# Implementation 03: AWS EC2

## Deployment

Update your SSH key in `terraform.tfvars`.

```sh
ssh_public_key = "ssh-ed25519 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

Create the AWS EC2 infrastructure and deploy Taskly to it.

```sh
export AWS_ACCESS_KEY_ID='XXXXXXXXXXXXXXXXXXXX'
export AWS_SECRET_ACCESS_KEY='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
terraform init && terraform apply
```

When complete, you'll see the URL you can access Taskly at.

```sh
Outputs:

app_url = "http://taskly20230804173326372200000004-2029619878.us-east-1.elb.amazonaws.com:80"
```
