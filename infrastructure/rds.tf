module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "prod-db"

  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = "db.t4g.large"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = local.db_name
  username = local.db_name
  port     = 5432

  multi_az                            = true
  iam_database_authentication_enabled = true
  db_subnet_group_name                = module.vpc.database_subnet_group
  vpc_security_group_ids              = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  tags = local.tags

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "rds-db-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "RDS DB monitoring role"
}

resource "random_password" "validator-app-password" {
  length      = 24
  min_lower   = 2
  min_upper   = 2
  min_numeric = 2
  min_special = 2
  special     = true
}

resource "aws_ssm_parameter" "validator-app-password" {
  name  = "validator-backend-db-password"
  type  = "SecureString"
  value = random_password.validator-app-password.result
}