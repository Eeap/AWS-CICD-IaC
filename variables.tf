variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "aws_region" {
  type = string
  default = "us-west-2"
}
variable "vpc_cidr_block" {
  type = string
  default = "10.255.0.0/16"
}
variable "vpc_name" {
  type = string
  default = "ecs-vpc"
}