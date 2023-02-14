variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
    description = "Just a Kluster name"
    type = string
    default = "exercise"
}

variable "cluster_version" {
    description = "Just a Kluster name"
    type = string
    default = "1.24"
}

variable "github_token" {
    description = "github token"
    type = string
    default = "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"
}

variable "repo_address" {
    description = "repository address"
    type = string
    default = "ehsandanesh/exercise-env"
}

variable "repo_address_app" {
    description = "repository address for app"
    type = string
    default = "ehsandanesh/exercise-app"
}
