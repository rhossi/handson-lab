# outputs.tf - Show what was created

output "created_users" {
  description = "Information about all created users and their compartments"
  value = {
    for key, user in oci_identity_user.users : key => {
      user_ocid              = user.id
      user_name              = user.name
      original_email         = local.users_map[key].email
      prefixed_email         = local.prefixed_emails[key]
      user_state             = user.state
      display_name           = local.users_map[key].name
      prefix                 = var.prefix
      compartment_ocid       = oci_identity_compartment.user_compartments[key].id
      compartment_name       = oci_identity_compartment.user_compartments[key].name
      compartment_name_clean = local.sanitized_compartment_names[key]
      compartment_state      = oci_identity_compartment.user_compartments[key].state
      group_membership_id    = oci_identity_user_group_membership.user_group_memberships[key].id
      group_name             = var.group_name
      bucket_ocid            = oci_objectstorage_bucket.user_buckets[key].id
      bucket_name            = oci_objectstorage_bucket.user_buckets[key].name
      bucket_namespace       = oci_objectstorage_bucket.user_buckets[key].namespace
      bucket_etag            = oci_objectstorage_bucket.user_buckets[key].etag
      # Generative AI resources
      knowledge_base_ocid     = oci_generative_ai_agent_knowledge_base.hotel_concierge_kb[key].id
      rag_tool_ocid           = oci_generative_ai_agent_tool.hotel_concierge_rag_tool[key].id
      concierge_agent_ocid    = oci_generative_ai_agent_agent.hotel_concierge_agent[key].id
      concierge_endpoint_ocid = oci_generative_ai_agent_agent_endpoint.hotel_concierge_endpoint[key].id
      adk_agent_ocid          = oci_generative_ai_agent_agent.hotel_concierge_adk_agent[key].id
      adk_endpoint_ocid       = oci_generative_ai_agent_agent_endpoint.hotel_concierge_adk_endpoint[key].id
    }
  }
}

output "user_count" {
  description = "Total number of users created"
  value       = length(oci_identity_user.users)
}

output "user_emails" {
  description = "List of all prefixed emails created"
  value       = [for key, email in local.prefixed_emails : email]
}

output "created_compartments" {
  description = "Information about all created compartments"
  value = {
    for key, compartment in oci_identity_compartment.user_compartments : key => {
      compartment_ocid       = compartment.id
      compartment_name       = compartment.name
      compartment_name_clean = local.sanitized_compartment_names[key]
      compartment_state      = compartment.state
      user_email             = local.users_map[key].email
      user_name              = local.users_map[key].name
      prefixed_email         = local.prefixed_emails[key]
    }
  }
}

output "compartment_count" {
  description = "Total number of compartments created"
  value       = length(oci_identity_compartment.user_compartments)
}

output "group_info" {
  description = "Information about the created group"
  value = {
    group_ocid   = oci_identity_group.hands_on_lab_group.id
    group_name   = oci_identity_group.hands_on_lab_group.name
    group_state  = oci_identity_group.hands_on_lab_group.state
    member_count = length(oci_identity_user_group_membership.user_group_memberships)
    member_users = [for key, user in oci_identity_user.users : user.name]
  }
}

output "policy_info" {
  description = "Information about the created policy"
  value = {
    policy_ocid    = oci_identity_policy.hands_on_lab_policy.id
    policy_name    = oci_identity_policy.hands_on_lab_policy.name
    policy_state   = oci_identity_policy.hands_on_lab_policy.state
    policy_version = oci_identity_policy.hands_on_lab_policy.version_date
    statements     = oci_identity_policy.hands_on_lab_policy.statements
    group_name     = var.group_name
  }
}

output "created_buckets" {
  description = "Information about all created buckets"
  value = {
    for key, bucket in oci_objectstorage_bucket.user_buckets : key => {
      bucket_ocid        = bucket.id
      bucket_name        = bucket.name
      bucket_namespace   = bucket.namespace
      bucket_etag        = bucket.etag
      bucket_compartment = local.sanitized_compartment_names[key]
      user_email         = local.users_map[key].email
      user_name          = local.users_map[key].name
      prefixed_email     = local.prefixed_emails[key]
    }
  }
}

output "bucket_count" {
  description = "Total number of buckets created"
  value       = length(oci_objectstorage_bucket.user_buckets)
}

output "created_knowledge_bases" {
  description = "Information about all created knowledge bases"
  value = {
    for key, kb in oci_generative_ai_agent_knowledge_base.hotel_concierge_kb : key => {
      knowledge_base_ocid = kb.id
      knowledge_base_name = kb.display_name
      compartment_ocid    = kb.compartment_id
      compartment_name    = local.sanitized_compartment_names[key]
      user_email          = local.users_map[key].email
      user_name           = local.users_map[key].name
      prefixed_email      = local.prefixed_emails[key]
    }
  }
}

output "created_rag_tools" {
  description = "Information about all created RAG tools"
  value = {
    for key, tool in oci_generative_ai_agent_tool.hotel_concierge_rag_tool : key => {
      rag_tool_ocid       = tool.id
      rag_tool_name       = tool.display_name
      knowledge_base_ocid = oci_generative_ai_agent_knowledge_base.hotel_concierge_kb[key].id
      compartment_ocid    = tool.compartment_id
      compartment_name    = local.sanitized_compartment_names[key]
      user_email          = local.users_map[key].email
      user_name           = local.users_map[key].name
      prefixed_email      = local.prefixed_emails[key]
    }
  }
}

output "created_concierge_agents" {
  description = "Information about all created Hotel Concierge agents"
  value = {
    for key, agent in oci_generative_ai_agent_agent.hotel_concierge_agent : key => {
      agent_ocid          = agent.id
      agent_name          = agent.display_name
      agent_endpoint_ocid = oci_generative_ai_agent_agent_endpoint.hotel_concierge_endpoint[key].id
      agent_endpoint_name = oci_generative_ai_agent_agent_endpoint.hotel_concierge_endpoint[key].display_name
      rag_tool_ocid       = oci_generative_ai_agent_tool.hotel_concierge_rag_tool[key].id
      knowledge_base_ocid = oci_generative_ai_agent_knowledge_base.hotel_concierge_kb[key].id
      compartment_ocid    = agent.compartment_id
      compartment_name    = local.sanitized_compartment_names[key]
      user_email          = local.users_map[key].email
      user_name           = local.users_map[key].name
      prefixed_email      = local.prefixed_emails[key]
    }
  }
}

output "created_adk_agents" {
  description = "Information about all created Hotel Concierge ADK agents"
  value = {
    for key, agent in oci_generative_ai_agent_agent.hotel_concierge_adk_agent : key => {
      agent_ocid          = agent.id
      agent_name          = agent.display_name
      agent_endpoint_ocid = oci_generative_ai_agent_agent_endpoint.hotel_concierge_adk_endpoint[key].id
      agent_endpoint_name = oci_generative_ai_agent_agent_endpoint.hotel_concierge_adk_endpoint[key].display_name
      compartment_ocid    = agent.compartment_id
      compartment_name    = local.sanitized_compartment_names[key]
      user_email          = local.users_map[key].email
      user_name           = local.users_map[key].name
      prefixed_email      = local.prefixed_emails[key]
    }
  }
}

output "generative_ai_resource_count" {
  description = "Total number of generative AI resources created per user"
  value = {
    knowledge_bases     = length(oci_generative_ai_agent_knowledge_base.hotel_concierge_kb)
    rag_tools           = length(oci_generative_ai_agent_tool.hotel_concierge_rag_tool)
    concierge_agents    = length(oci_generative_ai_agent_agent.hotel_concierge_agent)
    concierge_endpoints = length(oci_generative_ai_agent_agent_endpoint.hotel_concierge_endpoint)
    adk_agents          = length(oci_generative_ai_agent_agent.hotel_concierge_adk_agent)
    adk_endpoints       = length(oci_generative_ai_agent_agent_endpoint.hotel_concierge_adk_endpoint)
  }
}
