##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
  default = "eu-central-1"
}

variable "network_address_space" {
  default = "10.1.0.0/16"
}

variable "subnet1_address_space" {
  default = "10.1.1.0/24"
}

variable "subnet2_address_space" {
  default = "10.1.2.0/24"
}

variable "subnet3_address_space" {
  default = "10.1.3.0/24"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

##################################################################################
# DATA
##################################################################################

# AWS Cisco Cloud Services Router (CSR) 1000V - BYOL for SD-WAN
# Delivery Method : 64-bit (x86) AMI
# Software Version: 17.3.2 (9th November 2020)
# AMI ID:         : ami-0dd384e05d39fe670
# Product Code    : 8iutjw0bble75gtw5lrq0lwix

data "aws_availability_zones" "available" {}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


##################################################################################
# RESOURCES
##################################################################################

#Create the first VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"

  tags = {
    Name = "osf_tf_vpc1"
  }
}

#Create an Internet Gateway to that VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "osf_tf_igw"
  }
}

#Create the subnets within the VPCs
resource "aws_subnet" "subnet1" {
  cidr_block              = var.subnet1_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "osf_tf_subnet1"
  }
}
resource "aws_subnet" "subnet2" {
  cidr_block              = var.subnet2_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "osf_tf_subnet2"
  }
}
resource "aws_subnet" "subnet3" {
  cidr_block              = var.subnet3_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "osf_tf_subnet3"
  }
}

#Create Routing Route-Table
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "osf_ft_rt"
  }
}

#Create Routing Association
resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}
resource "aws_route_table_association" "rta-subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rtb.id
}
resource "aws_route_table_association" "rta-subnet3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.rtb.id
}

# Create Security-Groups to allow external access to EC2 Instances
resource "aws_security_group" "nginx-sg" {
  name        = "nginx_sg"
  description = "nginx security-group"
  vpc_id      = aws_vpc.vpc.id

  #Allow SSH from any source
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow HTTP from any source
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow ICMP from any source
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow any traffic from inside to outside
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "osf_tf_sg_nginx"
  }
}

#Create three (3) Webserver on NGINX platfom
#Webserver1
resource "aws_instance" "nginx1" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo rm /usr/share/nginx/html/index.html",
      "echo '<html><head><title>osf_Webserver_1</title></head><body style=\"background-color:#FF0000\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:100px;\">osf_Webserver_1</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
    ]
  }
}

#Webserver2
resource "aws_instance" "nginx2" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet2.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo rm /usr/share/nginx/html/index.html",
      "echo '<html><head><title>osf_Webserver_2</title></head><body style=\"background-color:#00FF00\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:100px;\">osf_Webserver_2</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
    ]
  }
}

#Webserver3
resource "aws_instance" "nginx3" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet3.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo rm /usr/share/nginx/html/index.html",
      "echo '<html><head><title>osf_Webserver_3</title></head><body style=\"background-color:#0000FF\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:100px;\">osf_Webserver_3</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
    ]
  }
}

##################################################################################
# OUTPUT
##################################################################################

#Provide FQDN of NGINX_1 Webserver
output "aws_instance1_public_dns" {
  value = aws_instance.nginx1.public_dns
}
#Provide FQDN of NGINX_2 Webserver
output "aws_instance2_public_dns" {
  value = aws_instance.nginx2.public_dns
}
#Provide FQDN of NGINX_3 Webserver
output "aws_instance3_public_dns" {
  value = aws_instance.nginx3.public_dns
}
