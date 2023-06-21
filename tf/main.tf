resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ansible_key"
  public_key = tls_private_key.example.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOF
      echo "${tls_private_key.example.private_key_pem}" > ansible_key.pem
      chmod 400 ansible_key.pem
    EOF
  }
}

resource "aws_instance" "ansible_test" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t3.micro"

  key_name = "ansible_key"

  tags = {
    Name = "ansible-test"
  }
  vpc_security_group_ids = [aws_security_group.ansible_test_sg.id]
}

resource "aws_security_group" "ansible_test_sg" {
  name        = "ansible-test-sg"
  description = "ansible-test-sg"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "ansible_test_sg_ingress_ssh" {
  security_group_id = aws_security_group.ansible_test_sg.id
  description       = "ssh"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]

  type = "ingress"
}

resource "aws_security_group_rule" "ansible_test_sg_ingress_http" {
  security_group_id = aws_security_group.ansible_test_sg.id
  description       = "http"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]

  type = "ingress"
}

resource "aws_security_group_rule" "ansible_test_sg_egress" {
  security_group_id = aws_security_group.ansible_test_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]

  type = "egress"
}