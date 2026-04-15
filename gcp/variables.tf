variable "project_id" {
  description = "Your GCP Project ID (find it in the console dashboard)"
  type        = string
  # Example: "migration-project-123456"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "northamerica-northeast1"   # Montreal — closest to Toronto
}

variable "zone" {
  description = "GCP zone (zonal cluster = no zonal fees)"
  type        = string
  default     = "northamerica-northeast1-a"
}
