resource "aws_security_group" "ecs-sg" {
  name        = "ecs-sg"
  description = "Allow inbound traffic from ALB on port 3000"
  vpc_id      = var.vpc_id

  tags = {
    Name = "ecs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_alb" {
  security_group_id            = aws_security_group.ecs-sg.id
  referenced_security_group_id = aws_security_group.alb-sg.id
  from_port                    = 3000
  ip_protocol                  = "tcp"
  to_port                      = 3000
}



resource "aws_vpc_security_group_egress_rule" "ecs_allow_all_outbound" {
  security_group_id = aws_security_group.ecs-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Allow inbound HTTP and HTTPS traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_http" {
  security_group_id = aws_security_group.alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https" {
  security_group_id = aws_security_group.alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_allow_all_outbound" {
  security_group_id = aws_security_group.alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}
