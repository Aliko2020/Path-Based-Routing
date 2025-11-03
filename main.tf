provider "aws" {
  region = "us-east-1"
}

# --- Default VPC & Subnets ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# --- S3 Bucket ---
resource "aws_s3_bucket" "path_based" {
  bucket        = "arr-bucket-123456"
  force_destroy = true

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# --- Security Group ---
resource "aws_security_group" "WebsiteSG" {
  name        = "WebsiteSG"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = data.aws_vpc.default.id  

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
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
    Name = "allow_http_ssh"
  }
}

# --- IAM Policy: EC2 -> S3 Read Access ---
resource "aws_iam_policy" "ec2_read_s3" {
  name        = "ec2_read_s3_policy"
  description = "Allow EC2 instances to read data from S3 bucket"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowS3ReadAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::arr-bucket-123456/*"]
      }
    ]
  })
}

# --- IAM Role ---
resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_read_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --- Attach Policy to Role ---
resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_read_s3.arn
}

# --- Instance Profile ---
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_s3_read_profile"
  role = aws_iam_role.ec2_role.name
}

# --- EC2 Instances ---
resource "aws_instance" "Red" {
  ami                         = "ami-0bdd88bd06d16ba03"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.WebsiteSG.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  user_data                   = file("user-data-red.sh")

  tags = {
    Name = "Red-EC2"
  }
}

resource "aws_instance" "Blue" {
  ami                         = "ami-0bdd88bd06d16ba03"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[1]
  vpc_security_group_ids      = [aws_security_group.WebsiteSG.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  user_data                   = file("user-data-blue.sh")

  tags = {
    Name = "Blue-EC2"
  }
}

output "red_instance_public_ip" {
  value = aws_instance.Red.public_ip
}

output "blue_intance_public_ip" {
  value = aws_instance.Blue.public_ip
}

# --- Target Groups ---
resource "aws_lb_target_group" "Red_TG" {
  name     = "Red-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/red/index.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "Red-Target-Group"
  }
}

resource "aws_lb_target_group" "Blue_TG" {
  name     = "Blue-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/blue/index.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "Blue-Target-Group"
  }
}

# --- Register Targets ---
resource "aws_lb_target_group_attachment" "Red_Attach" {
  target_group_arn = aws_lb_target_group.Red_TG.arn
  target_id        = aws_instance.Red.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "Blue_Attach" {
  target_group_arn = aws_lb_target_group.Blue_TG.arn
  target_id        = aws_instance.Blue.id
  port             = 80
}

# --- Application Load Balancer ---
resource "aws_lb" "AppLB" {
  name               = "LabLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.WebsiteSG.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "LabLoadBalancer"
  }
}

# --- Listener ---
resource "aws_lb_listener" "HTTP_Listener" {
  load_balancer_arn = aws_lb.AppLB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Blue_TG.arn # default route
  }
}

# --- Listener Rules ---
resource "aws_lb_listener_rule" "Red_Rule" {
  listener_arn = aws_lb_listener.HTTP_Listener.arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/red*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Red_TG.arn
  }
}

resource "aws_lb_listener_rule" "Blue_Rule" {
  listener_arn = aws_lb_listener.HTTP_Listener.arn
  priority     = 2

  condition {
    path_pattern {
      values = ["/blue*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Blue_TG.arn
  }
}

# --- Output the ALB DNS name ---
output "alb_dns_name" {
  value = aws_lb.AppLB.dns_name
}
