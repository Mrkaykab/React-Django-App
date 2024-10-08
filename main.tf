# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # Choose your preferred region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create a Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet"
  }
}

# Create a Security Group
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

data "aws_ssm_parameter" "ubuntu_2004_ami" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}


resource "aws_instance" "frontend" {
  ami                    = data.aws_ssm_parameter.ubuntu_2004_ami.value # Ubuntu AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  key_name               = "terraform-testing"


  tags = {
    Name = "frontend-vm"
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ssm_parameter.ubuntu_2004_ami.value # Ubuntu AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  key_name               = "terraform-testing"



  tags = {
    Name = "backend-vm"
  }
}

resource "aws_instance" "database" {
  ami                    = data.aws_ssm_parameter.ubuntu_2004_ami.value # Ubuntu AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  key_name               = "terraform-testing"



  tags = {
    Name = "database-vm"
  }
}

# Create a route table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}


# Output the public IPs of the instances
output "instance_frontend_public_ips" {
  value = aws_instance.frontend.public_ip

}

output "instance_backend_public_ips" {
  value = aws_instance.backend.public_ip

}

output "instance_database_public_ips" {
  value = aws_instance.database.public_ip

}

