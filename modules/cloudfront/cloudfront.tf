
# Data sources for AWS managed cache policies
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# Custom cache policy for API endpoints (cache only on key query params)
resource "aws_cloudfront_cache_policy" "api_query_aware" {
  name        = "${var.name_prefix}-api-query-policy"
  comment     = "Cache API responses by key query parameters to maximize hit ratio"
  default_ttl = 60
  max_ttl     = 300
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["station", "period", "window", "component"]
      }
    }
  }
}

# Data source for AWS managed origin request policy
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

# Data source for AWS managed origin request policy for S3 origins
# Using AllViewer policy for S3 static assets (minimal headers needed)
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

# CloudFront Function to strip /api prefix from requests
# Best practice: Use CloudFront Functions for lightweight path rewrites at edge locations
# This is more cost-effective and faster than Lambda@Edge for simple operations
# CloudFront Functions run at edge locations with minimal latency (<1ms typically)
resource "aws_cloudfront_function" "api_path_rewrite" {
  name    = "${var.name_prefix}-api-path-rewrite"
  runtime = "cloudfront-js-1.0"
  comment = "Strip /api prefix from API requests before forwarding to origin"
  publish = true
  code    = <<-EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    var forbiddenHtml = '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8" /><title>Access Forbidden</title><style>body{font-family:Arial,sans-serif;background:#f4f4f4;color:#333;text-align:center;padding-top:80px;} .card{max-width:460px;margin:auto;background:white;padding:40px;border-radius:12px;box-shadow:0 4px 25px rgba(0,0,0,0.1);} h1{color:#b00020;}</style></head><body><div class="card"><h1>403 - Access Forbidden</h1><p>This resource is restricted to internal systems. Please contact the GeoMag team if you believe this is an error.</p></div></body></html>';

    // API structure:
    // - Health endpoint: /health (no /api prefix)
    // - Documentation: /docs, /redoc, /openapi.json (no /api prefix)
    // - All other endpoints: /api/v1/... (keep /api prefix)
    //
    // Note: CloudFront path pattern /api/* is case-sensitive, so only requests
    // matching /api/* (lowercase) will reach this function

    if (uri === '/api/health') {
        return {
            statusCode: 403,
            statusDescription: 'Forbidden',
            headers: {
                'content-type': { value: 'text/html; charset=UTF-8' }
            },
            body: forbiddenHtml
        };
    } else if (uri.startsWith('/api/v1/')) {
        // Keep /api/v1/... as-is - API expects these paths
        // No change needed
    } else if (uri.startsWith('/api/')) {
        // For /api/health, /api/docs, /api/redoc, /api/openapi.json, etc.
        // Strip /api prefix to forward to API root endpoints
        request.uri = uri.substring(4); // Remove '/api' (4 characters)
    }
    // Note: /api (exact) is handled by separate cache behavior with api_landing_rewrite function
    // Note: Query strings are automatically preserved in request.querystring

    return request;
}
EOF
}

# CloudFront Function to rewrite /api to api.html for S3 origin
resource "aws_cloudfront_function" "api_landing_rewrite" {
  name    = "${var.name_prefix}-api-landing-rewrite"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite /api to api.html for S3 origin"
  publish = true
  code    = <<-EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // Rewrite /api (exact match) or /api/ (with trailing slash) to /api.html
    if (uri === '/api' || uri === '/api/') {
        request.uri = '/api.html';
    }

    return request;
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront Function to gate /health with shared secret header
resource "aws_cloudfront_function" "health_monitor_gate" {
  name    = "${var.name_prefix}-health-monitor-gate"
  runtime = "cloudfront-js-1.0"
  comment = "Block public access to /health endpoint"
  publish = true
  code    = <<-EOF
function handler(event) {
    return {
        statusCode: 403,
        statusDescription: 'Forbidden',
        headers: {
            'content-type': { value: 'application/json; charset=utf-8' }
        },
    };
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront Function to add CORS headers to API responses
# This ensures CORS works when accessing web app directly from ALB
resource "aws_cloudfront_function" "api_cors_headers" {
  name    = "${var.name_prefix}-api-cors-headers"
  runtime = "cloudfront-js-1.0"
  comment = "Add CORS headers to API responses for cross-origin requests"
  publish = true
  code    = <<-EOF
function handler(event) {
    var response = event.response;
    var request = event.request;

    // Get origin from request, default to * if not present
    var origin = '*';
    if (request.headers.origin && request.headers.origin.value) {
        origin = request.headers.origin.value;
    }

    // Initialize headers if not present
    if (!response.headers) {
        response.headers = {};
    }

    // Add CORS headers to response
    response.headers['access-control-allow-origin'] = { value: origin };
    response.headers['access-control-allow-credentials'] = { value: 'true' };
    response.headers['access-control-allow-methods'] = { value: 'DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT' };
    response.headers['access-control-allow-headers'] = { value: 'Content-Type, Authorization, X-Requested-With' };
    response.headers['access-control-max-age'] = { value: '600' };

    return response;
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront Origin Access Control (OAC) - preferred over OAI
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.name_prefix}-s3-oac"
  description                       = "OAC for S3 bucket ${module.s3-web-assets.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for ${var.name_prefix}"
  # Don't set default_root_object for ALB origins - ALB serves "/" directly
  # default_root_object is only useful for S3 origins
  price_class = var.price_class

  aliases = var.enable_custom_domain ? [var.custom_domain_name] : []

  # Web ALB Origin (default - for dynamic web app content)
  origin {
    domain_name = data.aws_lb.web.dns_name
    origin_id   = "ALB-Web-${var.name_prefix}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB only has HTTP listener
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    custom_header {
      name  = "X-Forwarded-Proto"
      value = "https"
    }
  }

  # API ALB Origin (for /api/* routes)
  origin {
    domain_name = data.aws_lb.api.dns_name
    origin_id   = "ALB-API-${var.name_prefix}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB only has HTTP listener
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Forwarded-Proto"
      value = "https"
    }
  }

  # S3 Origin (for static assets)
  origin {
    domain_name              = module.s3-web-assets.bucket_regional_domain_name
    origin_id                = "S3-${module.s3-web-assets.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # Default cache behavior - forward to Web ALB with minimal caching for dynamic content
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-Web-${var.name_prefix}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use modern cache policy - minimal caching for dynamic content
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id

    # Forward all headers, cookies, and query strings for dynamic content
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  # Cache behavior for api.html - must come before /api
  ordered_cache_behavior {
    path_pattern           = "/api.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # No origin_request_policy_id needed for S3 static asset with OAC
  }

  # API landing page - serves static HTML from S3 with links to docs/redoc
  ordered_cache_behavior {
    path_pattern           = "/api"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # No origin_request_policy_id needed for S3 static asset with OAC

    # Rewrite /api to api.html for S3 origin
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.api_landing_rewrite.arn
    }
  }

  # Health endpoint - always return 403 at the edge; monitoring should hit the ALB directly
  # Origin and cache settings don't matter since the function blocks before reaching origin
  ordered_cache_behavior {
    path_pattern           = "/health"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-Web-${var.name_prefix}" # Not used - function blocks before origin
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # These settings are required but not used since function blocks at edge
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id

    # This function blocks all /health requests at the edge
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.health_monitor_gate.arn
    }
  }

  # Explicit cache behavior for API routes - must be first to match before static assets
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-API-${var.name_prefix}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Cache by whitelisted query parameters to maximize cache hits for station/period data
    cache_policy_id = aws_cloudfront_cache_policy.api_query_aware.id

    # Forward all headers, cookies, and query strings for API requests
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id

    # Strip /api prefix before forwarding to origin
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.api_path_rewrite.arn
    }

    # Add CORS headers to API responses
    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.api_cors_headers.arn
    }
  }

  # OpenAPI schema (referenced by Swagger UI) - needs to hit the API origin
  ordered_cache_behavior {
    path_pattern           = "/openapi.json"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-API-${var.name_prefix}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  # Custom error page asset
  ordered_cache_behavior {
    path_pattern           = "/403.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # No origin_request_policy_id needed for S3 with OAC - matches working test2 config
  }

  ordered_cache_behavior {
    path_pattern           = "/404.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # No origin_request_policy_id needed for S3 with OAC - matches working test2 config
  }

  ordered_cache_behavior {
    path_pattern           = "/405.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # No origin_request_policy_id needed for S3 with OAC - matches working test2 config
  }

  ordered_cache_behavior {
    path_pattern           = "/500.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # No origin_request_policy_id needed for S3 with OAC - matches working test2 config
  }

  ordered_cache_behavior {
    path_pattern           = "/robots.txt"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # Robots is a static S3 asset - no origin request policy needed
  }

  ordered_cache_behavior {
    path_pattern           = "/sitemap.xml"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # Sitemap is a static S3 asset - no origin request policy needed
  }

  ordered_cache_behavior {
    path_pattern           = "/favicon.ico"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.s3-web-assets.bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    # Favicon is a static S3 asset - no origin request policy needed
  }

  # api-config.js is dynamically generated by web container - route to Web ALB
  # Must come before *.js wildcard pattern
  ordered_cache_behavior {
    path_pattern             = "/api-config.js"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "ALB-Web-${var.name_prefix}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  # Cache behavior for static assets - long TTL for cost savings
  # Using CachingOptimized policy which caches based on origin Cache-Control headers
  ordered_cache_behavior {
    path_pattern             = "*.js"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.css"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.jpg"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.png"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.gif"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.svg"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.woff*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.ttf"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  ordered_cache_behavior {
    path_pattern             = "*.ico"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${module.s3-web-assets.bucket_name}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  custom_error_response {
    error_code            = 403
    response_code         = 403
    response_page_path    = "/403.html"
    error_caching_min_ttl = 10 # Short cache to balance recovery time and origin load
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 405
    response_code         = 405
    response_page_path    = "/405.html"
    error_caching_min_ttl = 30
  }

  custom_error_response {
    error_code            = 500
    response_code         = 500
    response_page_path    = "/500.html"
    error_caching_min_ttl = 30
  }

  custom_error_response {
    error_code            = 502
    response_code         = 500
    response_page_path    = "/500.html"
    error_caching_min_ttl = 30
  }

  custom_error_response {
    error_code            = 503
    response_code         = 500
    response_page_path    = "/500.html"
    error_caching_min_ttl = 30
  }

  custom_error_response {
    error_code            = 504
    response_code         = 500
    response_page_path    = "/500.html"
    error_caching_min_ttl = 30
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.enable_custom_domain ? aws_acm_certificate_validation.cloudfront[0].certificate_arn : null
    ssl_support_method             = var.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.enable_custom_domain ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = !var.enable_custom_domain
  }

  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null

  # CloudFront access logging configuration
  dynamic "logging_config" {
    for_each = var.enable_cloudfront_access_logs ? [1] : []
    content {
      bucket          = module.s3-cloudfront-access-logs[0].bucket_domain_name
      include_cookies = false
      prefix          = "cloudfront-access-logs/"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cloudfront"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
