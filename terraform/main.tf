provider "aws" {
  region  = "ap-southeast-1"
  profile = "<AWS Profile>" // add the profile here from ~/.aws/credentials
}

data "aws_ami" "latest-debian" {
  most_recent = true

  owners = ["379101102735"]

  filter {
    name = "name"

    values = [
      "debian-stretch-hvm-x86_64-gp2*",
    ]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbBI+TOunJmFq7EX1JNcM4dpXyhCOvLxmlEuLGICzHRXG/GWlAmyoWQQShKMjWK25DsR/Z3UvK1sxGtJjZybNnNrZW07yzCbeKBng+COlHsnrI4TNckiug3umSKkv0Q+V1hw+tKG+zOY/JhlB2zAfP2sokpBw+kn8BXXvF5ijNA/Vmo5vV4xuhP11wTCoua3oUgHxfHLOKt5VW2eekuNN3BdWcJ39SHqrZzLUiY6zGbm/s9bwsVrtr4GUO2B7aX2X7PdH3B9HC69RvZBy2XNo1N4JNgiEiBIFQ0f9jfHs+C/RQWBfA8e9W90hHQ20uyCWEiWuJS+SEm+i2CWhww7FyglgODHsKLg/ii8DrTeVvzEb1zg8PUIxVfhbBmJAaG7ybaKDfxnhLsGTKaSWt+WNjOl/77qbYk5WnHTbxU239FtJV1RcF74t7agu5nJVKrQ7Ws0HHF23kvUwLfzxQsD/+K051RatL0k8fQE9Eg754Wzcs/B7A9vvuvfJ1p5acrLpSwgytgqCweVpiwo4kwL40TFRPnRz+aVVbHDrJ9aXGSFnl8zOYy2sHwhPL84TemKHvhKir6Zp85PfDt4/ulRjT2+EXRhGmRPN5JcDBt8XNNs2vw+LwJiq2GpNO//k9cqyQiIiEk5eNWMDtNcCsLPiqftuyvYC0ztrmmZ5ZXnkDNw=="
}

module "ec2_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = var.name
  instance_count = var.instances_number

  ami                    = data.aws_ami.latest-debian.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.id
  monitoring             = false
  vpc_security_group_ids = ["${aws_security_group.statsd-graphite-sg.id}"]
  subnet_id              = aws_default_subnet.default_az1.id

  root_block_device = [
    {
      device_name = "xvda"
      volume_type = "${var.volume_type}"
      volume_size = "${var.root_volume_size}"
      encrypted   = true
    },
  ]

  user_data = file("deploy.sh")

  tags = {
    Terraform   = "true"
    Environment = "test"
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "statsd-graphite-sg" {
  name        = "statsd-graphite-sg"
  description = "Allow access to statd-graphite"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["124.122.5.2/32"] // my home ip, replace yours here then you can access Graphite web at <EC2 Public IP>:8000
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "${var.region}a"

  tags = {
    Name = "Default subnet ${var.region}a"
  }
}