# vpc 1개, private subnet 2개, public subnet 1개, igw 1개, nat gw 1개, eip 1개, 각각 route table 1개, route 1개 생성

resource "aws_vpc" "ecs_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = var.vpc_name
    }
}
data "aws_availability_zones" "az" {
  
}
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.ecs_vpc.id
    count = 2
    cidr_block = cidrsubnet(aws_vpc.ecs_vpc.cidr_block, 8, count.index)
    availability_zone = data.aws_availability_zones.az.names[count.index]
    tags = {
        Name = "ecs-vpc-private-${count.index}"
    }
}
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.ecs_vpc.id
    cidr_block = cidrsubnet(aws_vpc.ecs_vpc.cidr_block, 8, 3)
    availability_zone = data.aws_availability_zones.az.names[3]
    tags = {
        Name = "ecs-vpc-public"
    }
  
}
resource "aws_internet_gateway" "ecs_vpc_igw" {
    vpc_id = aws_vpc.ecs_vpc.id
    tags = {
        Name = "ecs-vpc-igw"
    }
}

resource "aws_nat_gateway" "ecs_vpc_nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet.id
    tags = {
        Name = "ecs-vpc-nat-gw"
    }
}
resource "aws_eip" "nat_eip" {
    domain = "vpc"
    depends_on = [ aws_internet_gateway.ecs_vpc_igw ]
}

# route configuration
resource "aws_route" "ecs_vpc_public_route" {
    route_table_id = aws_vpc.ecs_vpc.default_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_vpc_igw.id
}
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.ecs_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ecs_vpc_nat_gw.id
    }
    tags = {
        Name = "ecs-vpc-private_route_table"
    }
}
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.ecs_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ecs_vpc_igw.id
    }
    tags = {
        Name = "ecs-vpc-public_route_table"
    }
}

resource "aws_route_table_association" "public_route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "private_route_table_association" {
    count = length(aws_subnet.private_subnet)
    subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
    route_table_id = aws_route_table.private_route_table.id
}