provider "alicloud" {
  region = "cn-beijing"
}

resource "alicloud_ecs_key_pair" "publickey" {
  key_pair_name = "jet_cmdb_test_key"
  public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpNTabIe5w8CqtvPFrl4NwZojqbMPZb4PKBOMPq243EghRlGt5OWlK/QYxXKyv7M2PvJ4Kl2zkh3yjcFdLLZziYkz+B+1lB8CHzzO90v39z72idp0+uVn/7ux81+jSKlnTZhsCi/NbMnQSe/CYXr/l+I03R8r6Nd/7WqFiT9cXQMn0y77UzzYKCV0d//KEppYAUxkC7ncSpf3fEo5/aalP7RvM3bYwlB4varDoG39IYwN5p/32KxIKn5b6u24Qtqcj9Ku+KE6/zkk7Z0wLwoTCVQn8RL5ROz0E9NY4cUa0H4ClhUKtuK1e1tmpVEQWDfOH0aikXO4wyfuW2RYAxfJdyxLBKMagozIpNW5I7ZfB2zVmgPM9sdmgC/U2WM6fVwVlzdo9A9bsuEzS0D+GW3bfOiFeS255j9a1AYAUCoqG0dXcObyBQV1BqAP+vOC+q7ZakITUaOdzXk20QsEtAAOhcymGOroND3wFI35pE0FzJdhXDPIhpW7KUFpPJUGv3gM= licairong@idcos.com"
}

resource "alicloud_security_group" "group" {
  name        = "jet_tf_test_foo"
  description = "foo"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_vpc" "vpc" {
  vpc_name       = "jet_first_vpc"
  cidr_block = "172.16.0.0/16"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/24"
  zone_id           = "cn-beijing-h"
  vswitch_name      = "first_vswitch"
}

resource "alicloud_ecs_disk" "example" {
  availability_zone     = "cn-beijing-h"
  disk_name   = "tf-test"
  description = "Hello ecs disk."
  category    = "cloud_efficiency"
  size        = "20"
  tags = {
    Name = "TerraformTest"
  }
}

resource "alicloud_slb_load_balancer" "slb" {
  load_balancer_name       = "jet-test-slb-tf"
  vswitch_id = alicloud_vswitch.vswitch.id
}

resource "alicloud_slb_server_group" "default" {
  load_balancer_id = alicloud_slb_load_balancer.slb.id
  name             = "jet_slb_sg"
  servers {
    server_ids = alicloud_instance.instance.*.id
    port       = 80
    weight     = 100
  }
}

resource "alicloud_slb_listener" "default" {
  load_balancer_id          = alicloud_slb_load_balancer.slb.id
  backend_port              = 80
  frontend_port             = 80
  protocol                  = "http"
  acl_status      = "on"
  acl_type        = "white"
  acl_id          = alicloud_slb_acl.default.id
}

resource "alicloud_slb_acl" "default" {
  name       = "jet_test_slb_acl"
  entry_list {
    entry   = "172.16.0.0/16"
    comment = "first"
  }
}

# Create a new ECS instance for VPC
resource "alicloud_instance" "instance" {
  count = var.instance_number

  # cn-beijing
  availability_zone = "cn-beijing-h"
  security_groups   = alicloud_security_group.group.*.id
  key_name          = alicloud_ecs_key_pair.publickey.key_pair_name

  # series III
  instance_type              = "ecs.t5-lc2m1.nano"
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "test_foo_system_disk_name"
  system_disk_description    = "test_foo_system_disk_description"
  image_id                   = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name              = "test_foo"
  vswitch_id                 = alicloud_vswitch.vswitch.id
  internet_max_bandwidth_out = 0
}

resource "alicloud_ecs_disk_attachment" "ecs_disk_att" {
  disk_id     = alicloud_ecs_disk.example.id
  instance_id = alicloud_instance.instance.id
}

resource "ansible_host" "middleware" {
  count                = var.instance_number
  inventory_hostname = alicloud_instance.instance[count.index].private_ip
  groups             = ["cloudcmp"]
  vars = {
      wait_connection_timeout = 600
      public_ip = alicloud_instance.instance[count.index].public_ip
      private_ip = alicloud_instance.instance[count.index].private_ip
      jet_apps_info = jsonencode(
        [
          {"app_name": "mysql", "app_type": "db", "app_version": "v8.0"},
          {"app_name": "redis", "app_type": "middleware", "app_version": "v6.0"},
          {"app_name": "zookeeper", "app_type": "middleware", "app_version": "v3.6.3"},
          {"app_name": "kafka", "app_type": "middleware", "app_version": "v2.8.1"}
        ]
      )
    }
}