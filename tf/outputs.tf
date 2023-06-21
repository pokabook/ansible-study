output "aws_instance_public_ip4" {
  value = aws_instance.ansible_test.public_ip
}