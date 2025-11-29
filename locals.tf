# locals {
#   s3_bucket_names = {
#     "web-assets" = "${var.name_prefix}-web-assets-${random_id.s3_bucket_suffix.hex}"
#     "web-logs"   = "${var.name_prefix}-web-logs-${random_id.s3_bucket_suffix.hex}"
#   }
#
#   # web_domain_name = "web.${var.domain_name}"
# }
