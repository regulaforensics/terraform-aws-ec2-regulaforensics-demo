variable "region" {
  type = string
}

variable "ami_name" {
  type = string
}

variable "env" {
  type = string
}

variable "spot_instance_type" {
  type = string
}

variable "docreader_tag" {
  type = string
}


locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

locals {
  standard_tags = {
    Name = "${var.ami_name}-${var.env}-${local.timestamp}"
  }
}

data "amazon-ami" "ubuntu_ami" {
  filters = {
    architecture        = "x86_64"
    name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }

  most_recent = true
  owners      = ["099720109477"]
  region = "${var.region}"
}

source "amazon-ebs" "docreader_service_ami" {
  ami_name                    = "${var.ami_name}-${var.env}-${local.timestamp}"
  region                      = "${var.region}"
  source_ami                  = data.amazon-ami.ubuntu_ami.id
  ssh_username                = "ubuntu"
  spot_instance_types         = ["${var.spot_instance_type}"]
  spot_price                  = "auto"
  associate_public_ip_address = true
  ssh_interface               = "public_ip"
  shutdown_behavior           = "terminate"
  encrypt_boot                = false
  force_deregister            = true
  force_delete_snapshot       = true

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 15
    delete_on_termination = true
  }

  dynamic "tag" {
    for_each = local.standard_tags

    content {
      key   = tag.key
      value = tag.value
    }
  }

  dynamic "fleet_tag" {
    for_each = local.standard_tags

    content {
      key   = fleet_tag.key
      value = fleet_tag.value
    }
  }
}

build {
  sources = ["source.amazon-ebs.docreader_service_ami"]

  provisioner "shell" {
    inline = ["sleep 10", "sudo apt-get update", "sudo apt-get install ansible -y"]
  }

  provisioner "file" {
    source      = "artifacts/nginx"
    destination = "/tmp"
  }

  provisioner "file" {
    source      = "artifacts/license/regula.license"
    destination = "/tmp/regula.license"
  }

  provisioner "file" {
    source      = "artifacts/config.yaml"
    destination = "/tmp/config.yaml"
  }

  provisioner "file" {
    source      = "artifacts/docker-compose.yml"
    destination = "/tmp/docker-compose.yml"
  }

  provisioner "ansible-local" {
    extra_arguments   = ["--extra-vars \"target=127.0.0.1 docreader_tag=${var.docreader_tag}\""]
    playbook_dir      = "../ansible"
    playbook_file     = "../ansible/docreader.yml"
    staging_directory = "/home/ubuntu/ansible"
  }
}
