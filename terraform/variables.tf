variable "bucket" {
  description = "Central infra bucket"
}
variable "ec2_keypair" {
  default = "michael-infra-key"
  
}
variable "access_key" {
  description = "This is the AWS access key"
}
variable "secret_key" {
  description = "This is the AWS secret key"
}
variable "region" {
  description = "The AWS region for the resource provisioning"
  default = "us-east-1"
}
variable "vpc_id" {
  description = "VPC ID"
}
variable "azs" {
  default = "us-east-1a"
}
variable "aws_account" {}
variable "name" {}
variable "instance_type" {
  type = string
  default = "t2.micro"
}
variable "ec2_ami" {
  type = map

  default = {
  us-east-1 = "ami-0fe472d8a85bc7b0e"
  us-east-2 = "ami-0fc161d91b03576d0"
  }
}
