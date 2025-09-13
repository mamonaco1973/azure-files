output "resource_group_name" {
  description = "Name of the mini-ad resource group."
  value       = azurerm_resource_group.mini_ad_rg.name
}

output "resource_group_location" {
  description = "Azure region of the mini-ad resource group."
  value       = azurerm_resource_group.mini_ad_rg.location
}

output "dns_server" {
  description = "DNS server IP address for the mini-ad deployment."
  value       = azurerm_network_interface.mini_ad_vm_nic.ip_configuration[0].private_ip_address
}