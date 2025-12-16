Feature: Tagging compliance for Thanos
  As a platform engineer
  I want to ensure all resources have proper tags
  So that resources can be tracked and managed

  Scenario: S3 buckets must have tags
    Given I have aws_s3_bucket defined
    Then it must have tags

  Scenario: IAM roles must have tags
    Given I have aws_iam_role defined
    Then it must have tags

  Scenario: IAM policies must have tags
    Given I have aws_iam_policy defined
    Then it must have tags
