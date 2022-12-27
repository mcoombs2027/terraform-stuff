terraform {
  required_version = ">= 1.0.2"

  // Administrative S3 bucket to serve as centralized store for infra and configs
  backend "s3" {
    key = "terraform/us-infra-testing.state"
    bucket = "tf-testing-mc"

    // Assume administrative s3 backend defined in infra.auto.tfvars
    // region = administrative s3 region
    // bucket = administrative s3 bucket name
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "s3key" {
  description = "key to encrypt shit"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "data-transfers-mc" {
  bucket = "data-transfers-mc"
}

resource "aws_s3_bucket_acl" "data-transfers-mc-acl" {
  bucket = aws_s3_bucket.data-transfers-mc.id
  acl = "private"
}

resource "aws_s3_bucket_public_access_block" "data-transfers-mc-block" {
  bucket = aws_s3_bucket.data-transfers-mc.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3encrypt" {
  bucket = aws_s3_bucket.data-transfers-mc.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3key.arn
      sse_algorithm = "aws:kms"
    }
  }
  
}

resource "aws_iam_role" "tf-testing-bucket-readonly" {
  name        = "${var.name}"
  description = "${var.name} instance role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "tf-testing-bucket-readonly" {
  name = "${var.name}-bucket-readonly"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Action": [
                "s3:List*",
                "s3:Get*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket}",
                "arn:aws:s3:::${var.bucket}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "tf-testing-bucket-readonly" {
  role       = "${aws_iam_role.tf-testing-bucket-readonly.name}"
  policy_arn = "${aws_iam_policy.tf-testing-bucket-readonly.arn}"
}

resource "aws_instance" "test-instance" {
  count = 1
  ami = lookup(var.ec2_ami,var.region)
  instance_type = var.instance_type
  security_groups = [aws_security_group.default.name]
  availability_zone = var.azs
  key_name = var.ec2_keypair
  tags = {
    "Name" = "test-instance-${count.index}"
  }
  
}

resource "aws_security_group" "default" {
  name = "${var.name}-sg"
  description = "Allow ssh"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.home
  }

  ingress {
    from_port = -1
    protocol = "ICMP"
    to_port = -1
    cidr_blocks = local.home
  }
   egress {
     from_port = 0
     protocol = "-1"
     to_port = 0
     cidr_blocks = ["0.0.0.0/0"]
   }

  tags = {
    Name      = "${var.name}-sg"
  }

}