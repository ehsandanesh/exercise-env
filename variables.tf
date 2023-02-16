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
    default = ""
}
 
variable "app_runner_enabled" {
    description  = "github runner enbaled for app repo"
    type = bool
    default = true
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
