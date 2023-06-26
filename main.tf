provider "aws" {
  region = "ap-northeast-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "handson"
  }
}

# Public Subnets
resource "aws_subnet" "public_1a" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = "${aws_vpc.main.id}"

  # Subnetを作成するAZ
  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "handson-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1c"

  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "handson-public-1c"
  }
}

resource "aws_subnet" "public_1d" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1d"

  cidr_block        = "10.0.3.0/24"

  tags = {
    Name = "handson-public-1d"
  }
}

# Private Subnets
resource "aws_subnet" "private_1a" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.10.0/24"

  tags = {
    Name = "handson-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.20.0/24"

  tags = {
    Name = "handson-private-1c"
  }
}

resource "aws_subnet" "private_1d" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1d"
  cidr_block        = "10.0.30.0/24"

  tags = {
    Name = "handson-private-1d"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  # コンソール上から作成するとInternet Gateway とVPCは自動で紐付きませんが、Terraformの場合プロパティでVPCを指定することで自動的に紐づけてくれる
  vpc_id = "${aws_vpc.main.id}"
  
  tags = {
    Name = "handson"
  }
}

# Elastic IP
resource "aws_eip" "nat_1a" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1a"
  }
}

resource "aws_eip" "nat_1c" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1c"
  }
}

resource "aws_eip" "nat_1d" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1d"
  }
}

# Nat Gateway
resource "aws_nat_gateway" "nat_1a" {
  subnet_id = "${aws_subnet.public_1a.id}" # NAT Gatewayを配置するSubnetを指定
  allocation_id = "${aws_eip.nat_1a.id}" # 紐付けるElastic IP

  tags = {
    Name = "handson-1a"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  subnet_id     = "${aws_subnet.public_1c.id}"
  allocation_id = "${aws_eip.nat_1c.id}"

  tags = {
    Name = "handson-1c"
  }
}

resource "aws_nat_gateway" "nat_1d" {
  subnet_id     = "${aws_subnet.public_1d.id}"
  allocation_id = "${aws_eip.nat_1d.id}"

  tags = {
    Name = "handson-1d"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  
  tags = {
    Name = "handson-public"
  }
}

# Route
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0" # Internet
  route_table_id = "${aws_route_table.public.id}"
  gateway_id = "${aws_internet_gateway.main.id}"
}

# Association
resource "aws_route_table_association" "public_1a" {
  subnet_id = "${aws_subnet.public_1a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_1c" {
  subnet_id = "${aws_subnet.public_1c.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_1d" {
  subnet_id = "${aws_subnet.public_1d.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# Route Table (Private)
resource "aws_route_table" "private_1a" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "handson-private-1a"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "handson-private-1c"
  }
}

resource "aws_route_table" "private_1d" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "handson-private-1d"
  }
}

# Route (Private)
resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0" # Internet
  route_table_id = "${aws_route_table.private_1a.id}"
  nat_gateway_id = "${aws_nat_gateway.nat_1a.id}"
}

resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.private_1c.id}"
  nat_gateway_id         = "${aws_nat_gateway.nat_1c.id}"
}

resource "aws_route" "private_1d" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.private_1d.id}"
  nat_gateway_id         = "${aws_nat_gateway.nat_1d.id}"
}

# Association (Private)
resource "aws_route_table_association" "private_1a" {
  subnet_id = "${aws_subnet.private_1a.id}"
  route_table_id = "${aws_route_table.private_1a.id}"
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = "${aws_subnet.private_1c.id}"
  route_table_id = "${aws_route_table.private_1c.id}"
}

resource "aws_route_table_association" "private_1d" {
  subnet_id      = "${aws_subnet.private_1d.id}"
  route_table_id = "${aws_route_table.private_1d.id}"
}