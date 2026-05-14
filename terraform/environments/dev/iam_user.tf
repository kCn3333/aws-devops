variable "aws_account_name" {
  default = "kCn_user"
}

variable "names" {
  default = ["johny", "michael", "sarah", "emily"]
}

resource "aws_iam_user" "kCn_user" {
  count = length(var.names)
  name  = var.names[count.index]
  #name = "${var.aws_account_name}_${count.index + 1}"
}