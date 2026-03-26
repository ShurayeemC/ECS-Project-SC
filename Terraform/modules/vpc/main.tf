resource "aws_vpc" "SC-ECS-Project-VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
  Name = "SC-ECS-Project-VPC"

  }
}

resource "aws_subnet" "public-1" {
  vpc_id     = aws_vpc.SC-ECS-Project-VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-1"
  }
} 

resource "aws_subnet" "public-2" {
  vpc_id     = aws_vpc.SC-ECS-Project-VPC.id
  cidr_block = "10.0.2.0/24"

tags = {
    Name = "public-2"
  }
  
}

resource "aws_subnet" "private-1" {
  vpc_id     = aws_vpc.SC-ECS-Project-VPC.id
  cidr_block = "10.0.3.0/24"
  tags = {
    Name = "private-1"
  }
  
}

resource "aws_subnet" "private-2" {
  vpc_id     = aws_vpc.SC-ECS-Project-VPC.id
  cidr_block = "10.0.4.0/24"
   tags = {
    Name = "private-2"
  }
  }

resource "aws_internet_gateway" "igw1-public-1" {
  vpc_id = aws_vpc.SC-ECS-Project-VPC.id
   tags = {
    Name = "igw1-public-1"
  }
}


resource "aws_nat_gateway" "ngw-private-1" {
  vpc_id            = aws_vpc.SC-ECS-Project-VPC.id
  availability_mode = "regional"
   tags = {
    Name = "ngw-private-1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.SC-ECS-Project-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1-public-1.id
  }
  
   tags = {
    Name = "public"
  }

}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.SC-ECS-Project-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw-private-1.id
  }

   tags = {
    Name = "private"
  }
}


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public.id


}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.private.id
}

