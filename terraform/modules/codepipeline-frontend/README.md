# Notes on CodePipeline

Outcome: CodePipeline does not have a facility to pick a branch or guide the pipeline based on rules.
The following was hopeful but unfortunately CodePipeline is not robust enough to perform this use case.
Only way to perform this type of enhancement would require:

## Flow summary

GitHub Push → Webhook → API Gateway → Lambda → CodePipeline → Build/Deploy

## Approach/Breakdown

Typically when you design an outcome you can thread it for its exact purpose, or you can take a Service Catalog approach.
You tend to blend this with business/developer needs, cybersecurity(DevSecOps) and GitOps.

Issues with current design (Cloudformation) which was the initial migration to using AWS CodePipeline:

* **Primer**: CodePipeline changed to v2 during this initial design which offered newer features but was not clear if any of them would assist our use case.
* **Branches**: Had to make a pipeline per branch/env = up to 7 codepipelines from nonprod to production
* **Tuning**: Had top level build image/compute, but not fine grain (per stage)  This means if the test suddenly runs out of memory, we upgraded all of them to MEDIUM.
* **Automatic/Manual**: We created auto builds for develop, but all others manually triggered thru "Release Change" in AWS Console.
* **Duplication**: 'release' branch built to `stage`, then using some determination another pipeline was ran to build to `perf`.  This is a duplication of lint, test, build/deploy.  i.e. this could just be promotion/manual approval.
  * Further duplication with artifacts buckets.
* **Integrations**: Pipeline notifications back to Github triggered thru SNS/Lambda to 'talk' back to Github for success/failure.
* **buildspecs**: Typically we keep buildspecs in the repo so devs can adjust (versions, commands etc).  This is true of most ci/cd systems but in some cases we inlined the buildspecs in CodeBuild to remove having to update these files in 8 repos x 3+ branches.
* **Github Actions**: Github Actions running also in tandem on PRs which CodePipeline does not manage so we are maintaining another .github/workflow (lint, test, build) which actually monitors issues (codeql or later sonarqube etc).

### This design attempts to solve:

* Codestar possibly supports a multi-branch pipeline.  Reduce the number of pipelines to 2 from (up to) 7
* Will enable stage-by-stage compute/image settings.  When you encounter a memory/heap issue, just increase the stage this occurs on.
* Remove duplication of stage/perf building off 'release' and going to 2 different env's.  Solve this with manual approval.
* Point to buildspecs in `cicd/buildspecs/` to reduce a bit of the complexity at the infra level.

**Per outcome above** there is no support for this multi-branch capability by CodePipeline.  And would require the aforementioned API Gateway/Lambda approach which is high level.  Much more goes in to getting this to work (roles, policies, tokens/api etc).
