resource "aws_s3_bucket" "kCn_bucket" {
  bucket = "kcn-s3-bucket-0001"
  #aws_s3_bucket_acl = "private"

  tags = {
    Name        = "MyBucket"
    Environment = "Dev"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.kCn_bucket
}