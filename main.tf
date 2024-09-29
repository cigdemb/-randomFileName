terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.69.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

locals {
  secgr-dynamic-ports = [22,80,443,8080,5000]
  user= "techpro"
}

resource "aws_instance" "tf-docker-ec2" {
    ami = "ami-00c39f71452c08778"
    instance_type = "t2.micro"
    key_name = "ec2_key"
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
    tags = {
        Name = "Bookstore Web Server"
    }
    user_data= <<-EOF
          #! /bin/bash
          yum update -y
          yum install docker git -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          newgrp docker
          curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          cd /home/ec2-user
          git clone https://github.com/cigdemb/Bookstore_Python_API.git
          cd /home/ec2-user/Docker-Project-Bookstore-Api
          docker-compose up -d
          EOF 
}
resource "aws_security_group" "allow_ssh" {
  name        = "${local.user}-docker-instance-sg"
  description = "Allow SSH inbound traffic"
  dynamic "ingress" {
    for_each = local.secgr-dynamic-ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "name" {
	value="http://${aws_instance.tf-docker-ec2.public_ip}"
}
