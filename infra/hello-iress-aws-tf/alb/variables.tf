variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "record_names" {
  type    = set(string)
  default = [
    "hello",
    "welcome"
    ]
}
