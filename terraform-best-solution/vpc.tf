resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Public Route Table con ruta al IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_suffixes)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_suffixes)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, var.public_subnet_suffixes[count.index])
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-${count.index}"
  }
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnet_suffixes)
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_suffixes)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-gw-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_suffixes)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, var.private_subnet_suffixes[count.index])
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "${var.cluster_name}-private-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_suffixes)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_suffixes)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
