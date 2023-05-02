deploy:
	cd terraform && terraform validate && terraform plan && terraform apply