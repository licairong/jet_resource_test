output "instance_addr" {
  value = alicloud_instance.instance.*.private_ip
}
