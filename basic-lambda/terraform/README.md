# Terraform

This folder contains the terraform to deploy this application.

## Getting Started

1. **Initialize Terraform**: Run the following command to initialize your Terraform working directory:

```sh
terraform init
```

2. **Plan and Apply**: Use the following commands to plan or apply your configuration:

```sh
terraform plan
terraform apply
```

## Configuring a backend

By default terraform uses a "local" backend. This means that terraform state will be stored locally. See the files `terraform.tfstate*` that are created in the `terraform` folder.

To get setup for a production environment you'll want to store your terraform state in a "backend". The most common backend when using AWS is S3. You can add a file `terraform/backend.tf` with the following contents to configure S3 as your backend. Create the S3 bucket first and then populate it's name and region here and a specify a key under which to store the state.

```
terraform {
  backend "s3" {
    bucket = "<bucket name>"
    key    = "<key-name>.tfstate"
    region = "<your-aws-region>"
    profile= "default"
  }
}
```
