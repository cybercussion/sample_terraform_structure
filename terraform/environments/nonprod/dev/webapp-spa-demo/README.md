# Web App Serverless

## Cloudfront as content distribution

Cloudfront is created as a CDN in this situation and uses a OAI to S3.
Invalidations need to be managed by CI/CD to clear cache after deployment.
Remember the cert used must be in us-east-1 (limitation of aws).

## S3

Non Public bucket created where your webapp build is placed.
CI/CD should manage mime-type and other cache control options.

## Route53

DNS Record added to point domain to cloudfront distribution.
