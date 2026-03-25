variable "namespace_ml" {
  type    = string
  default = "ml-production"
}

variable "namespace_monitoring" {
  type    = string
  description = "Namespace para ferramentas de observabilidade"
  default = "kubecost"
}

variable "pi_ip" {
  type    = string
  default = "192.168.178.31"
}

variable "minio_access_key" {
  type      = string
  sensitive = true
}

variable "minio_secret_key" {
  type      = string
  sensitive = true
}