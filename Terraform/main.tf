module "vpc" {
  source = "./modules/vpc"
}

module "securitygroups" {
  source = "./modules/securitygroups"
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source             = "./modules/alb"
  alb_name           = "ecs-lb"
  target_group_name  = "ecs-tg"
  security_group_ids = [module.securitygroups.alb_security_group_id]
  subnet_ids         = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  target_group_port  = 80
  certificate_arn    = module.acm.certificate_arn
  depends_on = [module.acm]
}

module "dns" {
  source      = "./modules/dns"
  domain_name = "sc-threat-composer.com"
}

module "acm" {
  source      = "./modules/acm"
  domain_name = "tm.sc-threat-composer.com"
  zone_id     = module.dns.zone_id
}

module "ecs" {
  source = "./modules/ecs"
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.securitygroups.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn
}
