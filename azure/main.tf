terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

provider "azuread" {}

data "azuread_client_config" "current" {}

resource "azuread_group" "migration_team" {
  display_name     = "Migration-Project-Team"
  security_enabled = true
  mail_enabled     = false
  description      = "Group for migration project demo — MFA enforced via Conditional Access"
}

resource "azuread_user" "demo_user" {
  user_principal_name         = "migration.demo@Vetri369outlook.onmicrosoft.com"
  display_name                = "Migration Demo User"
  mail_nickname               = "migration-demo"
  password                    = var.demo_user_password
  disable_password_expiration = false
}

resource "azuread_group_member" "demo_user_member" {
  group_object_id  = azuread_group.migration_team.object_id
  member_object_id = azuread_user.demo_user.object_id
}