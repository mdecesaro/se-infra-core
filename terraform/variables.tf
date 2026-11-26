variable "namespace_ml" {
  type    = string
  default = "ml-production"
}

variable "team_name" {
  type    = string
  default = "ml-ops"
}

variable "k3s_file_path" {
  type    = string
  default = "/etc/rancher/k3s/k3s.yaml"
}

variable "ml_backend_cpu_request" {
  type    = string
  default = "200m"
}

variable "ml_backend_memory_request" {
  type    = string
  default = "256Mi"
}

variable "ml_backend_replicas" {
  type    = number
  default = 1
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