resource "aws_ecr_repository" "sc-ecr-ecs" {
  name                 = "sc-ecr-ecs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
