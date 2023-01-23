terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "cley-tfstate-bucket"
    key    = "cley-instances-tfstate"
    region = "eu-west-3"
  }
}

provider "aws" {
  region = "eu-west-3"
}


data "aws_subnet" "kube_subnet_id" {
  
  filter {
    name   = "tag:Name"
    values = ["kube_subnet"]
  }

#   most_recent = true
}

data "aws_security_group" "kube_sg_id" {
  
  filter {
    name   = "tag:Name"
    values = ["kube_sg"]
  }

#   most_recent = true
}

resource "aws_key_pair" "kube_cp_key" {
  key_name   = "cleyaws_rsa_kube_cp-instance-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYp0vTiR2QjsgU4hKhtv2XxHwWqi5Cl/gFzHHcqZ6lp4ZuCzhGa5TGfmJ6Gevw99Yo8RkbC3K2XlJOHTC6nKZ7tc68Tm2C232iZKAAVDVChPYEOHIt0giEiYZ1KlVNtEsMM9cycpoYZrNKw1RYS8LUIqojHh46YPm63WAqAPvHhZ5xN2PYmHZeYkloMx1nP1TMZC4eOaTJL1zdIaYgWPUgS1eUFaW8752KKaha4td43F22HXxlf6zT3TJNzE8w+Fd8Te1V/8Nm1uj5llLRoyE8T8ABMJwdYm5KLPKBFtOCeSm9GXX0LwqjMRI4pqHVzR6fZ/AzIobT+HR2YzLEQZQ48axCpFOVv3IpAnGvo8xYctmPt33DNCxl1SYr97z+9VmRLAs1EU4U9wv9MSFY+ipwHdrwKGnZYDEO/jflrtFZvo5N4mqUhOuUEVYsN66G8J4dDMYFHFUXquc/88R74Wm44OoPosWncGw11b+gzIX4WWEQpLtBGFJD8DTMNY4iTGPo/MnJngdtcQOPof84DvUUrHD45SEQtkmg9ZJ5nusIi7fzxyUi+/axZzRytnTbNhFlkuqvqf88YXA0Gy4jnB1VEJ/04OFgR/0GCa4IaRP43KuM9DA0ITA1GKm/OAw7dXbVRYWHW4T6wKvhoCAssEyTggb4IJNa6vZwiTQWU4TvXw== cleyaws"
}


resource "aws_network_interface" "kube_instance_eni" {
  subnet_id       = data.aws_subnet.kube_subnet_id.id
  security_groups = [data.aws_security_group.kube_sg_id.id]

  
}

resource "aws_instance" "kube_dash_instance" {
  ami           = "ami-06ad2ef8cd7012912" # eu-west-3
  instance_type = "t3.medium"

  network_interface {
    network_interface_id = resource.aws_network_interface.kube_instance_eni.id
    device_index         = 0
  }
  availability_zone = "eu-west-3a"
  key_name = resource.aws_key_pair.kube_cp_key.key_name

  tags= {
    Name = "KubeCtrlPlane"
  }

}