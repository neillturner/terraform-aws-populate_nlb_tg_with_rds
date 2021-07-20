output "lambda_80_arn" {
  value = aws_lambda_function.static_lb_updater_80.arn
}

output "lambda_80_function_name" {
  value = aws_lambda_function.static_lb_updater_80.function_name
}

output "lambda_443_arn" {
  value = aws_lambda_function.static_lb_updater_443.arn
}

output "lambda_443_function_name" {
  value = aws_lambda_function.static_lb_updater_443.function_name
}
