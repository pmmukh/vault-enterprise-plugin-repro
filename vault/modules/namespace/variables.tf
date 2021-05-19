variable "namespace" {
  type = string
}

variable "dependencies" {
  type    = list(string)
  default = []
}
