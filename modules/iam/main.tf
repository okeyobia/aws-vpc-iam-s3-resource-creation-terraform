locals {
  common_tags = merge(var.tags, { Environment = var.environment })
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [var.bucket_arn]
  }

  statement {
    sid       = "ReadWriteObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_policy" "s3_access" {
  name        = "${var.role_name}-s3-access"
  description = "Read/write access scoped to ${var.bucket_arn}"
  policy      = data.aws_iam_policy_document.s3_access.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_instance_profile" "this" {
  name = var.role_name
  role = aws_iam_role.this.name

  tags = local.common_tags
}
