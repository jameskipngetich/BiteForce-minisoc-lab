resource "aws_vpc" "mini-socLab-VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "mini-socLab-VPC"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.mini-socLab-VPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_internet_gateway" "mini-socLab-igw" {
  vpc_id = aws_vpc.mini-socLab-VPC.id

  tags = {
    Name = "mini-socLab-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.mini-socLab-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mini-socLab-igw.id
  }

  tags = {
    Name = "route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_wazuh_comm" {
  vpc_id      = aws_vpc.mini-socLab-VPC.id
  name        = "allow_wazuh_comm"
  description = "Facilitate communication between wazuh server and agents"

  tags = {
    Name = "allow_wazuh_comm"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_wazuh_comm.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_wazuh_comm.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_agent_comm_ipv4" {
  security_group_id = aws_security_group.allow_wazuh_comm.id
  cidr_ipv4         = aws_vpc.mini-socLab-VPC.cidr_block
  from_port         = 1515
  ip_protocol       = "tcp"
  to_port           = 1515
}
resource "aws_vpc_security_group_ingress_rule" "allow_aa_ipv4" {
  security_group_id = aws_security_group.allow_wazuh_comm.id
  cidr_ipv4         = aws_vpc.mini-socLab-VPC.cidr_block
  from_port         = 1514
  ip_protocol       = "tcp"
  to_port           = 1514
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_wazuh_comm.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all protocols
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_wazuh_comm.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}
