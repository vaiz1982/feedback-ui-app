resource "aws_api_gateway_rest_api" "feedback_api" {
  name = "${var.project_name}-api"
}

resource "aws_api_gateway_resource" "submit" {
  rest_api_id = aws_api_gateway_rest_api.feedback_api.id
  parent_id   = aws_api_gateway_rest_api.feedback_api.root_resource_id
  path_part   = "submit"
}

########################################
# POST /submit — Lambda proxy integration
# NOTE: Lambda function is manually managed (not Terraform-tracked), so
# the invoke ARN below is hardcoded rather than referencing a resource.
########################################

resource "aws_api_gateway_method" "post_submit" {
  rest_api_id   = aws_api_gateway_rest_api.feedback_api.id
  resource_id   = aws_api_gateway_resource.submit.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_submit" {
  rest_api_id             = aws_api_gateway_rest_api.feedback_api.id
  resource_id             = aws_api_gateway_resource.submit.id
  http_method             = aws_api_gateway_method.post_submit.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:602555456359:function:SubmitFeetbackFunction/invocations"
}

########################################
# OPTIONS /submit — Lambda proxy integration
# (CORS preflight is handled inline in the Lambda code, matching the
#  manually-configured setup — not via a Mock integration)
########################################

resource "aws_api_gateway_method" "options_submit" {
  rest_api_id   = aws_api_gateway_rest_api.feedback_api.id
  resource_id   = aws_api_gateway_resource.submit.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_submit" {
  rest_api_id             = aws_api_gateway_rest_api.feedback_api.id
  resource_id             = aws_api_gateway_resource.submit.id
  http_method             = aws_api_gateway_method.options_submit.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:602555456359:function:SubmitFeetbackFunction/invocations"
}

########################################
# Deployment + prod stage
########################################

resource "aws_api_gateway_deployment" "feedback_api" {
  rest_api_id = aws_api_gateway_rest_api.feedback_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.submit.id,
      aws_api_gateway_method.post_submit.id,
      aws_api_gateway_integration.post_submit.id,
      aws_api_gateway_method.options_submit.id,
      aws_api_gateway_integration.options_submit.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.feedback_api.id
  rest_api_id   = aws_api_gateway_rest_api.feedback_api.id
  stage_name    = "prod"
}
