# Codestar Connection

This will establish the connection, but you must do the rest manually via OAuth.

- Go here: [Developer Tools](https://us-east-1.console.aws.amazon.com/codesuite/settings/connections?region=us-east-1&connections-meta=eyJmIjp7InRleHQiOiIifSwicyI6e30sIm4iOjIwLCJpIjowfQ#)
- Also can use `aws codestar-connections list-connections`
- Should see your github-xxxxx Pending

```bash
{
    "Connections": [
        {
            "ConnectionName": "github-xxxxxx",
            "ConnectionArn": "arn:aws:codestar-connections:us-west-2:1234567890:connection/917a771a-3b46-4437-80cd-23abf97db603",
            "ProviderType": "GitHub",
            "OwnerAccountId": "1234567890",
            "ConnectionStatus": "PENDING"
        }
    ]
}
```

## Manual Part

- Select it, and then click "Update Pending Connection"
- Window will open, I used Install a new app.
- Went down to Repository Access.. you can do all or select.
- You'll see some digits show up in the App Installation field.
- I hit "Connect"
- Should now state status "Available"

You can now run the codebuild-github-runner project.

Note there is a dependency on the ARN/Name coming out of this.
But `terragrunt run-all apply`  in the `codebuild-github-runner` folder may ask if you want
this to run again.  I answer n / no.

Use the output arn/name to use in your subsequent codebuild-github-runner usages.
