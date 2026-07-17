# ============================================================
# VPC for MLOps Environment (us-east-1)
# ============================================================

resource "aws_vpc" "mlops" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "petclinic-mlops-vpc"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.mlops.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name                                         = "petclinic-mlops-public-1"
    Environment                                  = var.environment
    "kubernetes.io/cluster/petclinic-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.mlops.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name                                         = "petclinic-mlops-public-2"
    Environment                                  = var.environment
    "kubernetes.io/cluster/petclinic-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }
}

# Private Subnets (for EKS worker nodes)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.mlops.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name                                         = "petclinic-mlops-private-1"
    Environment                                  = var.environment
    "kubernetes.io/cluster/petclinic-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.mlops.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name                                         = "petclinic-mlops-private-2"
    Environment                                  = var.environment
    "kubernetes.io/cluster/petclinic-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "mlops" {
  vpc_id = aws_vpc.mlops.id

  tags = {
    Name        = "petclinic-mlops-igw"
    Environment = var.environment
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "petclinic-mlops-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "mlops" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name        = "petclinic-mlops-nat-gw"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.mlops]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mlops.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mlops.id
  }

  tags = {
    Name        = "petclinic-mlops-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.mlops.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mlops.id
  }

  tags = {
    Name        = "petclinic-mlops-private-rt"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
