variable "vpc_cidr" {
  description = "cidr for the vpc"
  type = string
  default = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "cidr for the private subnet"
  type = string
  default = "10.0.0.0/24"
}

variable "public_subnet_cidr" {
  description = "cidr for the public subnet"
  type = string
  default = "10.0.1.0/24"
}

variable "instance_ami" {
  description = "ami id for the instance"
  type = string
}

variable "instance_type" {
  description = "type of the instance"
  type = string
  default = "t2.micro"
}

variable "instance_key_name" {
  description = "key name of the instance"
  type = string
}

variable "username_for_database" {
  description = "Username for admin of database"
  type = string
  default = "shivam"
}

variable "database_password" {
  description = "password for the mysql database"
  type = string
}