provider "aws" {
  region = "eu-north-1"
}

# Data

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

data "aws_ami" "wazuh" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["Wazuh_v4.14.10-1-79ced6c9*"] # Matches official Wazuh AMI naming patterns
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Resources
resource "aws_instance" "wazuh_server_main" {
  ami                    = data.aws_ami.wazuh.id
  instance_type          = "c5a.xlarge" # Recommended minimum by Wazuh
  key_name               = "debkey"
  vpc_security_group_ids = [aws_security_group.allow_wazuh_comm.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 100 #Minimum 100G gp3 recommended
    volume_type = "gp3"
  }

  tags = {
    Name = "Wazuh-All-In-One"
  }
}

resource "aws_instance" "victim_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = "debkey"
  vpc_security_group_ids = [aws_security_group.allow_wazuh_comm.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "Victim-LinuxServer"
  }
}


