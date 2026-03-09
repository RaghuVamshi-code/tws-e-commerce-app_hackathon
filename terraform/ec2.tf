data "aws_ami" "os_image" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/*24.04-amd64*"]
  }
}

resource "tls_private_key" "new_keypair" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "new_keypair" {
  key_name   = "new-keypair"
  public_key = tls_private_key.new_keypair.public_key_openssh
}

resource "local_file" "new_keypair_pem" {
  filename        = "${path.module}/keys/new-keypair.pem"
  content         = tls_private_key.new_keypair.private_key_openssh
  file_permission = "0600"
}



resource "aws_security_group" "allow_user_to_connect" {
  name        = "allow TLS"
  description = "Allow user to connect"
  vpc_id      = module.vpc.vpc_id
  dynamic "ingress" {
    for_each = [
      { description = "port 22 allow", from = 22, to = 22, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "port 80 allow", from = 80, to = 80, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "port 443 allow", from = 443, to = 443, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "port 8080 allow", from = 8080, to = 8080, protocol = "tcp", cidr = ["0.0.0.0/0"] }
    ]
    content {
      description = ingress.value.description
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr
    }
  }

  egress {
    description = " allow all outgoing traffic "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "mysecurity"
  }
}

resource "aws_instance" "testinstance" {
  ami                    = data.aws_ami.os_image.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.new_keypair.key_name
  vpc_security_group_ids = [aws_security_group.allow_user_to_connect.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data              = file("${path.module}/install_tools.sh")
  tags = {
    Name = "Jenkins-Automate"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

}

resource "aws_eip" "jenkins_server_ip" {
  instance = aws_instance.testinstance.id
  domain   = "vpc"
}