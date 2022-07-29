terraform {
  required_providers {
    ansible = {
      source = "registry.cloudiac.org/idcos/ansible"
      version = "1.0.4"
    }
    alicloud = {
      source = "registry.cloudiac.org/aliyun/alicloud"
      version = "1.162.0"
   }
  }
}
