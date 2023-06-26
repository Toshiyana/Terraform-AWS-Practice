variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list
}


# Security Group
resource "aws_security_group" "this" {
  name = "${var.name}-alb"
  description = "${var.name} alb"
  vpc_id = "${var.vpc_id}"

  # Security Group内のリソースからInternetへのアクセスを許可
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb"
  }
}

# Security Group Rule
resource "aws_security_group_rule" "http" {
  security_group_id = "${aws_security_group.this.id}"

  # InternetからSecurity Group内のリソースへのアクセスを許可
  type = "ingress"

  from_port = 80
  to_port = 80
  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

# ALB
resource "aws_lb" "this" {
  load_balancer_type = "application"
  name = "${var.name}"

  security_groups = ["${aws_security_group.this.id}"]
  subnets = var.public_subnet_ids
}

# LB Listener
resource "aws_lb_listener" "http" {
  # HTTPでのアクセスを受け付ける
  port              = "80"
  protocol          = "HTTP"

  # ALBのarnを指定
  # (arnはAmazon Resource Names の略で、その名の通りリソースを特定するための一意な名前(id).)
  load_balancer_arn = "${aws_lb.this.arn}"

  # "ok"という固定レスポンスを設定
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code = "200"
      message_body = "ok"
    }
  }
}