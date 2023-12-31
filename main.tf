# Creating the VPC for the project
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
}

# Declare the data source
data "aws_availability_zones" "available_zones" {
  state = "available"
}

# Creating a private subnet inside the vpc
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available_zones.names[0]
}

# Creating a public subnet inside the vpc
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr
  availability_zone = data.aws_availability_zones.available_zones.names[1]
}

# Internet Gateway for public subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

# Route table for the public subnet
resource "aws_route_table" "route_table_with_gateway" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

# Attaching route table with the subnet
resource "aws_route_table_association" "subnet_and_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_table_with_gateway.id
}

resource "aws_instance" "instance_1" {
  ami = var.instance_ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet.id
  key_name = var.instance_key_name
}

resource "aws_instance" "instance_2" {
  ami = var.instance_ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet.id
  key_name = var.instance_key_name
}

# Creating a Target Group
resource "aws_lb_target_group" "target_group" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

# Attaching instances to target group
resource "aws_lb_target_group_attachment" "target_group_attachment_1" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target_group_attachment_2" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.instance_2.id
  port             = 80
}

# Create Security Group in the vpc
resource "aws_security_group" "security_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  # Inbound rules for the security group
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # Outbound rules for the security group
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Create Application Load Balancer
resource "aws_lb" "load_balancer" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group.id]
  subnets            = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]
}

# Attach target group with load balancer
resource "aws_lb_listener" "attach_target_group_with_load_balancer" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Create a subnet group
resource "aws_db_subnet_group" "subnet_group" {
  name       = "subnet_group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]
}

# Create database in the private subnet
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "terraform_database"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.username_for_database
  password             = var.database_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.subnet_group.name
}

# Get the dns name of the load balancer
output "alb_dns_name" {
  value = aws_lb.load_balancer.dns_name
}