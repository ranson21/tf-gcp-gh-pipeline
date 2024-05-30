variable "project" {
  description = "GCP Project"
  type        = string
}

variable "project_number" {
  type        = string
  description = "Google Cloud project number"
}

variable "deploy_key_id" {
  type        = string
  description = "Secret key id for token used in deployments"
}

variable "deploy_key_version" {
  type        = string
  description = "Secret key version for token used in deployments"
  default     = "latest"
}

variable "region" {
  type        = string
  description = "Geographic region for hosting the project"
}

variable "connection_name" {
  type        = string
  description = "The name of the Github Connection"
}

variable "installation_id" {
  type        = string
  description = "The installation ID of the cloud Build Github app"
}

variable "repo_owner" {
  type        = string
  description = "Owner of the repos being added"
}

variable "repos" {
  type        = set(string)
  description = "List of repos to add to the github cloud build connection"
}

variable "default_branch" {
  type        = string
  description = "Default branch name for matching build triggers"
  default     = "master"
}
