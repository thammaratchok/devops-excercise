# How to provision infrastructure

* Add aws profile in `main.tf`
```
provider "aws" {
  ..
  profile = "<AWS Profile>"
}
```

* To be able to access Graphite web, whitelist your IP in `main.tf`
```
resource "aws_security_group" "statsd-graphite-sg" {
  ...
  ingress {
    ...
    cidr_blocks = ["<IP address>"]
  }
```

* In terminal, run `terraform init`
* Then, run `terraform apply` to provision the infrastructure and deploy containers using Docker Compose

