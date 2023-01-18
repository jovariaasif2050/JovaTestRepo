

# main.tf

 resource "aws_vpc" "project_vpc" {
   cidr_block       = "10.0.0.0/24"
   enable_dns_hostnames = true
   tags = {
    Name = "Project_VPC"
  }
 }

 resource "aws_internet_gateway" "IGW" {
    vpc_id =  "${aws_vpc.project_vpc.id}"
 }

 resource "aws_subnet" "publicsubnets" {
   vpc_id =  "${aws_vpc.project_vpc.id}"
   cidr_block = "${var.public_subnets}"
   map_public_ip_on_launch = true
   tags = {
    Name = "Public_Subnet"
  }
 }

 resource "aws_subnet" "privatesubnets" {
   vpc_id =  "${aws_vpc.project_vpc.id}"
   cidr_block = "${var.private_subnets}"
   tags = {
    Name = "Private_Subnet"
  }
 }

 resource "aws_route_table" "PublicRT" {
    vpc_id =  "${aws_vpc.project_vpc.id}"
         route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
     }
     tags = {
    Name = "Public_RT"
  }
 }

 resource "aws_route_table" "PrivateRT" {
   vpc_id = "${aws_vpc.project_vpc.id}"
   route {
   cidr_block = "0.0.0.0/0"
   nat_gateway_id = "${aws_nat_gateway.NATgw.id}"
   }
   tags = {
    Name = "Private_RT"
  }
 }
 
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = "${aws_subnet.publicsubnets.id}"
    route_table_id = "${aws_route_table.PublicRT.id}"
 }
 
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = "${aws_subnet.privatesubnets.id}"
    route_table_id = "${aws_route_table.PrivateRT.id}"
 }
  resource "aws_eip" "nateIP" {
   vpc   = true
 }
 
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = "${aws_eip.nateIP.id}"
   subnet_id = "${aws_subnet.publicsubnets.id}"
 }


 resource "aws_instance" "ec2_instance" {
    ami = "${var.ami_id}"
    count = "${var.number_of_instances}"
    subnet_id = "${aws_subnet.publicsubnets.id}"
    instance_type = "${var.instance_type}"
    key_name = "${var.ami_key_pair_name}"
    security_groups = [aws_security_group.ssh_sg.id]
    tags = {
    Name = "${element(var.instance_names, count.index)}"
  }
 }


# var.tf

variable "region" {}
 variable "main_vpc_cidr" {}
 variable "public_subnets" {}
 variable "private_subnets" {}
 variable "ami_id" {}
 variable "number_of_instances" {}
 variable "instance_type" {}
 variable "ami_key_pair_name" {}
 variable "bucket_name" {}
 variable "instance_names" {}
 variable "destinationCIDRblock" {}


#terraform.tfvars

 region = "us-east-1"
 main_vpc_cidr = "10.0.0.0/24"
 public_subnets = "10.0.0.128/26"
 private_subnets = "10.0.0.192/26"
 ami_id = "ami-002070d43b0a4f171"
 number_of_instances = "4"
 instance_type = "t2.micro"
 ami_key_pair_name = "JovariaKeyPair"
 bucket_name = "project-s3-bucket-jovaria"
 instance_names = ["Ansible_Master", "Ansible_Slave_1", "Ansible_Slave_2", "Ansible_Slave_3"]
 destinationCIDRblock = "0.0.0.0/0"



# provider.tf

provider "aws" {
   region = "us-east-1"
 }


# security.tf

resource "aws_security_group" "ssh_sg" {
  name = "allow-all-sg"
    vpc_id     = "${aws_vpc.project_vpc.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-all-sg"
  }
}


# bucket.tf

resource "aws_s3_bucket" "onebucket" {
   bucket = "${var.bucket_name}" 
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = "${var.bucket_name}" 
  acl    = "private" 
}

resource "aws_s3_bucket_versioning" "versioning" {
   bucket = "${var.bucket_name}"
  versioning_configuration {
    status = "Enabled"
}
}
