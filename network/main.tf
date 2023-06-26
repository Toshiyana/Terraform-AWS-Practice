variable "name" {
  type = string
}

variable "azs" {
  type = list
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

# VPC
resource "aws_vpc" "this" {
  cidr_block = "${var.vpc_cidr}"

  tags = {
    Name = "${var.name}"
  }
}

# Public Subnets
resource "aws_subnet" "publics" {
  count = "${length(var.public_subnet_cidrs)}"

  vpc_id = "${aws_vpc.this.id}"

  availability_zone = "${var.azs[count.index]}"

  cidr_block = "${var.public_subnet_cidrs[count.index]}"

  tags = {
    Name = "${var.name}-public-${count.index}"
  }
}

# Private Subnets
resource "aws_subnet" "privates" {
  count = "${length(var.private_subnet_cidrs)}"

  vpc_id = "${aws_vpc.this.id}"

  availability_zone = "${var.azs[count.index]}"

  cidr_block = "${var.private_subnet_cidrs[count.index]}"

  tags = {
    Name = "${var.name}-private-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  # コンソール上から作成するとInternet Gateway とVPCは自動で紐付きませんが、Terraformの場合プロパティでVPCを指定することで自動的に紐づけてくれる
  vpc_id = "${aws_vpc.this.id}"
  
  tags = {
    Name = "${var.name}"
  }
}

# Elastic IP
resource "aws_eip" "nats" {
  count = "${length(var.public_subnet_cidrs)}"

  domain = "vpc"

  tags = {
    Name = "${var.name}-natgw-${count.index}"
  }
}

# Nat Gateway
resource "aws_nat_gateway" "this" {
  count = "${length(var.public_subnet_cidrs)}"

  subnet_id = "${element(aws_subnet.publics.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nats.*.id, count.index)}"

  tags = {
    Name = "${var.name}-${count.index}"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.this.id}"
  
  tags = {
    Name = "${var.name}-public"
  }
}

# Route
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0" # Internet
  route_table_id = "${aws_route_table.public.id}"
  gateway_id = "${aws_internet_gateway.this.id}"
}

# Association
resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnet_cidrs)}"

  subnet_id = "${element(aws_subnet.publics.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# Route Table (Private)
resource "aws_route_table" "privates" {
  count = "${length(var.private_subnet_cidrs)}"

  vpc_id = "${aws_vpc.this.id}"

  tags = {
    Name = "${var.name}-private-${count.index}"
  }
}

# Route (Private)
resource "aws_route" "privates" {
  count = "${length(var.private_subnet_cidrs)}"

  destination_cidr_block = "0.0.0.0/0" # Internet

  route_table_id = "${element(aws_route_table.privates.*.id, count.index)}"
  nat_gateway_id = "${element(aws_nat_gateway.this.*.id, count.index)}"
}

# Association (Private)
resource "aws_route_table_association" "privates" {
  count = "${length(var.private_subnet_cidrs)}"

  subnet_id = "${element(aws_subnet.privates.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.privates.*.id, count.index)}"
}

output "vpc_id" {
  value = "${aws_vpc.this.id}"
}

output "public_subnet_ids" {
  value = aws_subnet.publics[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.privates[*].id
}