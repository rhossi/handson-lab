# variables.tf - Super simple version for creating one user

# OCI Authentication
variable "tenancy_ocid" {
  description = "Your OCI tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "Your OCI user OCID"
  type        = string
}

variable "fingerprint" {
  description = "Your OCI API key fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to your OCI private key"
  type        = string
}

variable "home_region" {
  description = "OCI home region for resources that require it"
  type        = string
  default     = "us-phoenix-1"
}

variable "us_chicago_1_region" {
  description = "OCI us-chicago-1 region for resources that require it"
  type        = string
  default     = "us-chicago-1"
}

# Common prefix for all users
variable "prefix" {
  description = "Prefix to add to all user emails (user+prefix@domain.com)"
  type        = string
}

# Group configuration
variable "group_name" {
  description = "Name of the group to create and add all users to"
  type        = string
  default     = "HandsOnLab"
}

# Policy configuration
variable "policy_name" {
  description = "Name of the policy to create for the group"
  type        = string
  default     = "HandsOnLab-Policy"
}

# Bucket configuration
variable "bucket_storage_tier" {
  description = "Storage tier for the user buckets"
  type        = string
  default     = "Standard"
}

variable "bucket_versioning" {
  description = "Enable versioning for user buckets"
  type        = string
  default     = "Disabled"
}

# Compartment configuration
variable "compartment_parent_ocid" {
  description = "Parent compartment OCID where user compartments will be created (defaults to tenancy OCID)"
  type        = string
  default     = null
}

# Users to create
variable "users" {
  description = "List of users to create"
  type = list(object({
    email = string
    name  = string
  }))
  default = []
}
