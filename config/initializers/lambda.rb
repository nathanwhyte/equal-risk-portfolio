Aws.use_bundled_cert!

AwsLambdaClient = Aws::Lambda::Client.new(
  credentials: Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new,
    role_arn: "arn:aws:iam::956673833192:role/service-role/equal-risk-lambda-role-8vtzb52r",
    role_session_name: "eqrsk-lambda-session",
  ),
)
