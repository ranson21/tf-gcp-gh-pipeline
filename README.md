# ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) GCP Github Pipeline

<img width="512" alt="Terraform Logo" src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Terraform_Logo.svg/512px-Terraform_Logo.svg.png?20181016201549">

## Description

This is a minimal terraform module for implementing a github connection and add repositories. It can either be used as a standalone module or within a bigger project using terragrunt, example:

*terragrunt.hcl*
```hcl
source = "git@github.com:ranson21/tf-gcp-gh-pipeline"

inputs = {
  ...
}
```

## Inputs

All inputs and descriptions can be located in the [Variables](./variables.tf) file

## Outputs

All outputs and descriptions can be located in the [Outputs](./outputs.tf) file

## License

[MIT](./LICENSE)
