# main.tf - Create one IAM user with prefixed email

# Configure the OCI Provider for IAM operations (must be in home region)
provider "oci" {
  alias            = "home_region"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.home_region
}

# Configure the OCI Provider for other resources (can be in any region)
provider "oci" {
  alias            = "us_chicago_1_region"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.us_chicago_1_region
}

# Create local values for user processing
locals {
  # Convert list to map with unique keys for for_each
  users_map = {
    for idx, user in var.users : "user-${idx}" => user
  }

  # Helper function to create prefixed email using external prefix
  prefixed_emails = {
    for key, user in local.users_map : key => "${split("@", user.email)[0]}+${var.prefix}@${split("@", user.email)[1]}"
  }

  # Helper function to create sanitized compartment names (alphanumeric only)
  sanitized_compartment_names = {
    for key, user in local.users_map : key => replace(
      replace(
        replace(
          "${split("@", user.email)[0]}-${var.prefix}",
          ".", "-"
        ),
        "+", "-"
      ),
      "[^a-zA-Z0-9-]", ""
    )
  }
}

# Create multiple IAM users
resource "oci_identity_user" "users" {
  for_each = local.users_map
  provider = oci.home_region

  compartment_id = var.tenancy_ocid
  name           = local.prefixed_emails[each.key]
  email          = local.prefixed_emails[each.key]
  description    = "User created by Terraform: ${each.value.name} (${local.prefixed_emails[each.key]})"

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"    = "Terraform"
    "Purpose"      = "Demo"
    "OriginalUser" = each.value.email
    "Prefix"       = var.prefix
    "UserIndex"    = each.key
  }
}

# Give each user API key capability
resource "oci_identity_user_capabilities_management" "user_capabilities" {
  for_each = oci_identity_user.users
  provider = oci.home_region

  user_id = each.value.id

  can_use_api_keys             = true
  can_use_auth_tokens          = false
  can_use_console_password     = false
  can_use_customer_secret_keys = false
  can_use_smtp_credentials     = false
}

# Create a compartment for each user
resource "oci_identity_compartment" "user_compartments" {
  for_each = local.users_map
  provider = oci.home_region

  compartment_id = var.compartment_parent_ocid != null ? var.compartment_parent_ocid : var.tenancy_ocid
  name           = local.sanitized_compartment_names[each.key]
  description    = "Compartment for user: ${each.value.name} (${local.prefixed_emails[each.key]})"

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy" = "Terraform"
    "Purpose"   = "UserWorkspace"
    "UserEmail" = each.value.email
    "UserName"  = each.value.name
    "Prefix"    = var.prefix
    "UserIndex" = each.key
  }
}

# Create a group for all users
resource "oci_identity_group" "hands_on_lab_group" {
  provider       = oci.home_region
  compartment_id = var.tenancy_ocid
  name           = var.group_name
  description    = "Group for HandsOnLab users with prefix: ${var.prefix}"

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy" = "Terraform"
    "Purpose"   = "HandsOnLab"
    "Prefix"    = var.prefix
  }
}

# Create policy for Generative AI services access
# Temporarily commented out due to "No permissions found" error
# The resources are being created successfully without this policy
# resource "oci_identity_policy" "generative_ai_policy" {
#   provider = oci.home_region

#   compartment_id = var.tenancy_ocid
#   name           = "${var.prefix}-generative-ai-policy"
#   description    = "Policy to allow access to Generative AI services for users with prefix ${var.prefix}"

#   statements = [
#     "Allow group ${var.group_name} to use generative-ai-agent in tenancy",
#     "Allow group ${var.group_name} to use generative-ai-knowledge-base in tenancy",
#     "Allow group ${var.group_name} to use generative-ai-model in tenancy",
#     "Allow group ${var.group_name} to use generative-ai-endpoint in tenancy",
#     "Allow group ${var.group_name} to manage generative-ai-agent in tenancy",
#     "Allow group ${var.group_name} to manage generative-ai-knowledge-base in tenancy",
#     "Allow group ${var.group_name} to manage generative-ai-model in tenancy",
#     "Allow group ${var.group_name} to manage generative-ai-endpoint in tenancy",
#     "Allow group ${var.group_name} to manage object-family in tenancy",
#     "Allow group ${var.group_name} to use object-family in tenancy"
#   ]

#   # Optional: Add some tags
#   freeform_tags = {
#     "CreatedBy" = "Terraform"
#     "Purpose"   = "GenerativeAI"
#     "Prefix"    = var.prefix
#   }
# }

# Add all users to the group
resource "oci_identity_user_group_membership" "user_group_memberships" {
  for_each = oci_identity_user.users
  provider = oci.home_region

  user_id  = each.value.id
  group_id = oci_identity_group.hands_on_lab_group.id
}

# Create policy for the HandsOnLab group
resource "oci_identity_policy" "hands_on_lab_policy" {
  provider       = oci.home_region
  compartment_id = var.tenancy_ocid
  name           = var.policy_name
  description    = "Policy for HandsOnLab group with prefix: ${var.prefix}"

  statements = [
    "allow group ${var.group_name} to use cloud-shell in tenancy",
    "allow group ${var.group_name} to use cloud-shell-public-network in tenancy",
    "allow group ${var.group_name} to manage object-family in tenancy",
    "allow group ${var.group_name} to manage buckets in tenancy",
    "allow group ${var.group_name} to manage objects in tenancy",
    "allow group ${var.group_name} to use generative-ai-family in tenancy",
    "allow group ${var.group_name} to manage adm-knowledge-bases in tenancy",
    "allow group ${var.group_name} to manage genai-agent-family in tenancy",
    "allow group ${var.group_name} to inspect compartments in tenancy"
  ]

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy" = "Terraform"
    "Purpose"   = "HandsOnLab"
    "Prefix"    = var.prefix
    "Group"     = var.group_name
  }
}

# Create a bucket for each user in their compartment
resource "oci_objectstorage_bucket" "user_buckets" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  name           = local.sanitized_compartment_names[each.key]
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace

  # Bucket configuration
  storage_tier = var.bucket_storage_tier
  versioning   = var.bucket_versioning

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "UserWorkspace"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }
}

# Get the object storage namespace for each user compartment
data "oci_objectstorage_namespace" "user_namespace" {
  provider = oci.us_chicago_1_region
}

# Upload the TripAdvisorReviewsMultiLang.txt file to each user's bucket
resource "oci_objectstorage_object" "tripadvisor_file" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  bucket    = oci_objectstorage_bucket.user_buckets[each.key].name
  namespace = data.oci_objectstorage_namespace.user_namespace.namespace
  object    = "TripAdvisorReviewsMultiLang.txt"
  source    = "${path.module}/data/TripAdvisorReviewsMultiLang.txt"

  # Optional: Add some metadata
  metadata = {
    "uploaded-by" = "Terraform"
    "user-email"  = each.value.email
    "user-name"   = each.value.name
    "prefix"      = var.prefix
  }

  # Add timeout for large file uploads
  timeouts {
    create = "10m"
  }
}

# Create knowledge base for each user compartment
resource "oci_generative_ai_agent_knowledge_base" "hotel_concierge_kb" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  display_name   = "Hotel_Concierge_KB"
  description    = "Knowledge base for Hotel Concierge agent - ${each.value.name}"

  # Required index configuration
  index_config {
    index_config_type = "DEFAULT_INDEX_CONFIG"
  }

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConcierge"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }
}

# Create data source for each knowledge base
resource "oci_generative_ai_agent_data_source" "hotel_concierge_data_source" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id    = oci_identity_compartment.user_compartments[each.key].id
  knowledge_base_id = oci_generative_ai_agent_knowledge_base.hotel_concierge_kb[each.key].id
  display_name      = "Hotel_Concierge_Data_Source"
  description       = "Data source for Hotel Concierge knowledge base - ${each.value.name}"

  # Configure the data source (object storage)
  data_source_config {
    data_source_config_type = "OCI_OBJECT_STORAGE"
    object_storage_prefixes {
      bucket    = oci_objectstorage_bucket.user_buckets[each.key].name
      namespace = data.oci_objectstorage_namespace.user_namespace.namespace
      prefix    = "TripAdvisorReviewsMultiLang.txt"
    }
  }

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConcierge"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }

  # Wait for knowledge base to be active and object to be uploaded
  depends_on = [
    oci_objectstorage_object.tripadvisor_file,
    oci_generative_ai_agent_knowledge_base.hotel_concierge_kb
  ]

  # Add timeout to wait for knowledge base to become active
  timeouts {
    create = "30m"
  }
}

# Create data ingestion job for each knowledge base
resource "oci_generative_ai_agent_data_ingestion_job" "hotel_concierge_kb_ingestion" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  data_source_id = oci_generative_ai_agent_data_source.hotel_concierge_data_source[each.key].id
  display_name   = "Hotel_Concierge_KB_Ingestion"
  description    = "Data ingestion job for Hotel Concierge knowledge base - ${each.value.name}"

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConcierge"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }

  depends_on = [
    oci_generative_ai_agent_data_source.hotel_concierge_data_source
  ]
}

# Create Hotel Concierge agent for each compartment
resource "oci_generative_ai_agent_agent" "hotel_concierge_agent" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  display_name   = "Hotel_Concierge"
  description    = "Hotel Concierge agent for ${each.value.name}"

  # Associate with knowledge base
  knowledge_base_ids = [oci_generative_ai_agent_knowledge_base.hotel_concierge_kb[each.key].id]

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConcierge"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }

  # Wait for knowledge base to be active
  depends_on = [
    oci_generative_ai_agent_knowledge_base.hotel_concierge_kb
  ]

  # Add timeout to wait for knowledge base to become active
  timeouts {
    create = "30m"
  }
}

# Create RAG tool for each knowledge base using the correct syntax from official docs
resource "oci_generative_ai_agent_tool" "hotel_concierge_rag_tool" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  agent_id       = oci_generative_ai_agent_agent.hotel_concierge_agent[each.key].id
  display_name   = "Hotel_Concierge_RAG_Tool"
  description    = "RAG tool for Hotel Concierge agent - ${each.value.name}"

  # Configure the RAG tool using the correct syntax from official documentation
  tool_config {
    tool_config_type = "RAG_TOOL_CONFIG"
    knowledge_base_configs {
      knowledge_base_id = oci_generative_ai_agent_knowledge_base.hotel_concierge_kb[each.key].id
    }
  }

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConcierge"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }

  depends_on = [
    oci_generative_ai_agent_agent.hotel_concierge_agent,
    oci_generative_ai_agent_data_ingestion_job.hotel_concierge_kb_ingestion
  ]
}

# Create Hotel Concierge agent endpoint
resource "oci_generative_ai_agent_agent_endpoint" "hotel_concierge_endpoint" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  display_name   = "Hotel_Concierge_Endpoint"
  description    = "Endpoint for Hotel Concierge agent - ${each.value.name}"

  # Associate with the agent
  agent_id = oci_generative_ai_agent_agent.hotel_concierge_agent[each.key].id

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConcierge"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }

  depends_on = [
    oci_generative_ai_agent_agent.hotel_concierge_agent
  ]
}

# Create Hotel Concierge ADK agent for each compartment
resource "oci_generative_ai_agent_agent" "hotel_concierge_adk_agent" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  display_name   = "Hotel_Concierge_ADK"
  description    = "Hotel Concierge ADK agent for ${each.value.name}"

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConciergeADK"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }
}

# Create Hotel Concierge ADK agent endpoint
resource "oci_generative_ai_agent_agent_endpoint" "hotel_concierge_adk_endpoint" {
  for_each = local.users_map
  provider = oci.us_chicago_1_region

  compartment_id = oci_identity_compartment.user_compartments[each.key].id
  display_name   = "Hotel_Concierge_ADK_Endpoint"
  description    = "Endpoint for Hotel Concierge ADK agent - ${each.value.name}"

  # Associate with the agent
  agent_id = oci_generative_ai_agent_agent.hotel_concierge_adk_agent[each.key].id

  # Optional: Add some tags
  freeform_tags = {
    "CreatedBy"   = "Terraform"
    "Purpose"     = "HotelConciergeADK"
    "UserEmail"   = each.value.email
    "UserName"    = each.value.name
    "Prefix"      = var.prefix
    "UserIndex"   = each.key
    "Compartment" = local.sanitized_compartment_names[each.key]
  }

  depends_on = [
    oci_generative_ai_agent_agent.hotel_concierge_adk_agent
  ]
}
