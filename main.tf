terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
    region = "us-east-1" 
    access_key = "paste yours"
    secret_key = "paste yours"
}

#! commands
# 1. terraform init
# 2. terraform plan
# 3. terraform apply
# 4. terraform destroy


# 1. vpc
resource "aws_vpc" "vpc1"{
    cidr_block = "100.0.0.0/16"

    tags = {
    Name = "terr_vpc"
  }
}
# 2. IGW
resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "terra_gw"
  }
}
# 3. route tables
resource "aws_route_table" "route1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw1.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw1.id
  }

  tags = {
    Name = "terra_route"
  }
}
# 4. subnets --- link them to route
resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "100.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "terra_sub"
  }
}
# 5. security groups
resource "aws_security_group" "sg1" {
  name        = "allow_22_80_443"
  description = "allow_22_80_443"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  } 
  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terra_sg"
  }
}
#extra subnet to routetable
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.route1.id
}
#extra network interface
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.sub1.id
  private_ips     = ["100.0.10.12"]
  security_groups = [aws_security_group.sg1.id]

}
# 6. EIP optional
resource "aws_eip" "eip1" {
  vpc = true
  network_interface = aws_network_interface.test.id
  associate_with_private_ip = "100.0.10.12"
  depends_on                = [aws_internet_gateway.gw1]
}
# 7. instance
resource "aws_instance" "foo" {
  ami           = "ami-006dcf34c09e50022" 
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"

  # this is enough to launch a ec2

  network_interface {
    network_interface_id = aws_network_interface.test.id
    device_index         = 0
  }
  user_data = <<-EOF

    #!/bin/bash
    yum update -y
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    cd /var/www/html
    echo "<html><h1>Hello Cloud Gurus Welcome To My Webpage</h1></html>" > index.html
  EOF
  
    tags = {
      Name = "terra_server"
    }

}

