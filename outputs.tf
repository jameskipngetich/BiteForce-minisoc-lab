output "wazuh-server-pub-ip" {
  value = aws_instance.wazuh_server_main.public_ip
}

output "wazuh-server-priv-dns" {
  value = aws_instance.wazuh_server_main.private_dns
}

output "wazuh-server-instance-id" {
  value = aws_instance.wazuh_server_main.id
}

output "linux-victim-public-ip" {
  value = aws_instance.victim_server.public_ip
}
