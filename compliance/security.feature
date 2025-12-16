Feature: Thanos security compliance
  As a security engineer
  I want to ensure Thanos infrastructure follows security best practices
  So that metrics storage is secure

  Scenario: S3 bucket must have encryption enabled
    Given I have aws_s3_bucket_server_side_encryption_configuration defined
    Then it must have rule

  Scenario: S3 bucket must block public access
    Given I have aws_s3_bucket_public_access_block defined
    Then it must have block_public_acls
    And its block_public_acls must be true
    And it must have block_public_policy
    And its block_public_policy must be true
    And it must have ignore_public_acls
    And its ignore_public_acls must be true
    And it must have restrict_public_buckets
    And its restrict_public_buckets must be true

  Scenario: S3 lifecycle must be configured
    Given I have aws_s3_bucket_lifecycle_configuration defined
    Then it must have rule

  Scenario: IAM role must have trust policy
    Given I have aws_iam_role defined
    Then it must have assume_role_policy

  Scenario: IAM policy must restrict to specific bucket
    Given I have aws_iam_policy defined
    Then it must have policy

  Scenario: IAM roles must not allow unrestricted access
    Given I have aws_iam_policy defined
    When it has policy
    Then it must not have Resource containing ["*"]
