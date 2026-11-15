resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "rds-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

resource "aws_db_instance" "postgres_db" {
  identifier                  = "taskflow-postgres-db-instance"
  allocated_storage           = 10
  db_name                     = "taskflow"
  engine                      = "postgres"
  engine_version              = "18.1"
  instance_class              = "db.t3.micro"
  manage_master_user_password = true
  username                    = "taskflowadmin"
  publicly_accessible         = false
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  multi_az                    = false
  storage_encrypted           = true
  deletion_protection         = false
}

resource "aws_secretsmanager_secret_rotation" "taskflowdb-secret-rotation" {
  secret_id        = aws_db_instance.postgres_db.master_user_secret[0].secret_arn
  rotation_enabled = false
}
