# Codebuild Github Action Runner

You might want something like this since AWS CodePipeline has so many limitations with multi-branch projects.

Although, I'm finding this isn't just a runner I can use on multiple repos directly.  Its like you'd have to keep figuring out how to setup the webhook in other projects.  Possibly manually.

**Things I ran into implementing this.**

- Codestar Connection is manual.  You can create it, but must follow the directions to authenticate.
- Currently using this to setup CodeBuild/Role does not satisfy parts of CodeBuilds webhook

## Workaround

After this sets up, I go in to "github-runner" in CodeBuild.

- Hit Edit
- Ensure its set to Runner Project
- Ensure "Use override Credentials for this project only" is checked
- Choose your named Codestar Connection
- A arn will appear
- Repository was selected for this use case (github personal)
- Repository: Ensure your URL is there
- Hit update project.
- Webhook should get created, check github repo settings->webhooks

Sample Github Action (.github/workflows/hello.yml):

```yaml
name: Hello World
on: [push]
jobs:
  Hello-World-Job:
    runs-on:
      # Change "github-runner" to the name of your codebuild
      - codebuild-github-runner-${{ github.run_id }}-${{ github.run_attempt }}
      - image:${{ matrix.os }}
      - instance-size:${{ matrix.size }}
    strategy:
      matrix:
        include:
          - os: arm-3.0
            size: small
          - os: linux-5.0
            size: large
    steps:
      - run: echo "Hello World!"
```

After pushing to the repo you should see a job start, webhook should trigger.
Codebuild should provision and process the build.

If this doesn't work, your Codebuild name is either wrong, your webhook is missing or possibly have some other permission issue.

Generally I would say right now manually doing this was easier than using IaC.

AWS Docs are currently thin/weak: https://docs.aws.amazon.com/codebuild/latest/userguide/action-runner.html

[Terraform aws_codebuild_project docs] (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#description-1)

- [Link to issue](https://github.com/hashicorp/terraform/issues/12285)
- [Link to forwarded issue](https://github.com/hashicorp/terraform-provider-aws/issues/7435#issuecomment-534115342)

I took a look at the entire CodeBuild Project Block in Cloudformation:

```yaml
CodeBuildProject:
    Type: AWS::CodeBuild::Project
    Properties:
      Artifacts:
        ArtifactIdentifier: "String"
        EncryptionDisabled: false
        Location: "String"
        Name: "String"
        NamespaceType: "String"
        OverrideArtifactName: false
        Packaging: "String"
        Path: "String"
        Type: "String"
      AutoRetryLimit: "Number"
      BadgeEnabled: false
      BuildBatchConfig:
        BatchReportMode: "String"
        CombineArtifacts: false
        Restrictions:
          ComputeTypesAllowed:
            - "String"
          MaximumBuildsAllowed: "Number"
        ServiceRole: "String"
        TimeoutInMins: "Number"
      Cache:
        Location: "String"
        Modes:
          - "String"
        Type: "String"
      ConcurrentBuildLimit: "Number"
      Description: "String"
      EncryptionKey: "String"
      Environment:
        Certificate: "String"
        ComputeType: "String"
        EnvironmentVariables:
          - Name: "String"
            Type: "String"
            Value: "String"
        Fleet:
          FleetArn: "String"
        Image: "String"
        ImagePullCredentialsType: "String"
        PrivilegedMode: false
        RegistryCredential:
          Credential: "String"
          CredentialProvider: "String"
        Type: "String"
      FileSystemLocations: 
        - Identifier: "String"
          Location: "String"
          MountOptions: "String"
          MountPoint: "String"
          Type: "String"
      LogsConfig:
        CloudWatchLogs:
          GroupName: "String"
          Status: "String"
          StreamName: "String"
        S3Logs:
          EncryptionDisabled: false
          Location: "String"
          Status: "String"
      Name: "String"
      QueuedTimeoutInMinutes: "Number"
      ResourceAccessRole: "String"
      SecondaryArtifacts: 
        - ArtifactIdentifier: "String"
          EncryptionDisabled: false
          Location: "String"
          Name: "String"
          NamespaceType: "String"
          OverrideArtifactName: false
          Packaging: "String"
          Path: "String"
          Type: "String"
      SecondarySourceVersions: 
        - SourceIdentifier: "String"
          SourceVersion: "String"
      SecondarySources: 
        - Auth:
            Resource: "String"
            Type: "String"
          BuildSpec: "String"
          BuildStatusConfig:
            Context: "String"
            TargetUrl: "String"
          GitCloneDepth: "Number"
          GitSubmodulesConfig:
            FetchSubmodules: false
          InsecureSsl: false
          Location: "String"
          ReportBuildStatus: false
          SourceIdentifier: "String"
          Type: "String"
      ServiceRole: "String" # Required
      Source:
        Auth:                           # <-- I'm unable to get the aws provider to recognize this auth {} block
          Resource: "String"            # <-- CODESTAR_CONNECTIONS
          Type: "String"                # <-- '{{resolve:ssm:/github/connection/arn}}'
        BuildSpec: "String"
        BuildStatusConfig:
          Context: "String"
          TargetUrl: "String"
        GitCloneDepth: "Number"
        GitSubmodulesConfig:
          FetchSubmodules: false
        InsecureSsl: false
        Location: "String"
        ReportBuildStatus: false
        SourceIdentifier: "String"
        Type: "String"
      SourceVersion: "String"
      Tags: 
        - Key: "String"
          Value: "String"
      TimeoutInMinutes: "Number"
      Triggers:
        BuildType: "String"
        FilterGroups:
          -
        ScopeConfiguration:
          Name: "String"
        Webhook: false
      Visibility: "String"
      VpcConfig:
        SecurityGroupIds:
          - "String"
        Subnets:
          - "String"
        VpcId: "String"
```

This command can directly add it.

```bash
aws codebuild update-project --name github-runner \
  --source "{\"type\": \"GITHUB\", \"location\": \"https://github.com/<org>>/<repo>.git\", \"auth\": {\"type\": \"CODECONNECTIONS\", \"resource\": \"arn:aws:codestar-connections:<region>:<account_id>:connection/<hash>\"}}"
```

verify:

```bash
aws codebuild batch-get-projects --names github-runner --query "projects[*].source.auth";
```

So trick would be to just use a null_resource and deal with some lifecycle fun and its now working.
