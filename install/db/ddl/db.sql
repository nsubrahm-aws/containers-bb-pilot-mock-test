-- Create schema
CREATE SCHEMA demo;

-- Create database user mapped to IAM role
CREATE USER 'pod_user'@'%' IDENTIFIED WITH AWSAuthenticationPlugin as 'RDS';
GRANT SELECT, INSERT, UPDATE, DELETE ON demo.* TO 'pod_user'@'%' ;
