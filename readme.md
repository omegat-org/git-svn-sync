# git-svn-sync

Continuously sync a svn to git, in the cloud.

## What is it?

This repo contains the building blocks for an on-demand service to sync a
Subversion repository to a Git repository on a continuous basis.

"On a continuous basis" means that rather than a one-time migration from svn to
git, development will continue in svn and new changes will be mirrored into git.

## Assumptions

Currently, the following things are hard-coded for the OmegaT project:

- Source and target repository URLs
- Trigger authentication (assumed to be Apache Allura, i.e. SourceForge)
- Svn authors update mechanism
- Various names of AWS entities and resources

TODO: Make all of the above configurable

## How it works

First, [per this article](https://gist.github.com/amake/4752f5f5169a1a7fb137)
one must note that the git-svn clone must be kept as an artifact in order to
maintain a consistent git history.

The principal players:

- A tarball of the git-svn clone that is consistent with the existing git mirror
  - Lives in an S3 bucket
  - Not included in this repo
- The Docker image:
  - Runs on Amazon ECS (Fargate)
  - Pulls the above tarball, updates it from svn, and pushes the result to git
  - Tars up the repo again and pushes it to S3
- The Lambda function:
  - Validates incoming webhook requests
  - Triggers the ECS task

Glue:

- Amazon API Gateway provides a URL to give to SourceForge as the webhook target
- The API request invokes the lambda, which in turn issues a custom CloudWatch
  event
- The CloudWatch event triggers the ECS task

Note: The CloudWatch event isn't strictly necessary—the lambda could run the
task directly, but that requires it to know a bunch of incidental things like
the task's security group and subnet(s), which I wanted to keep out of the
lambda.

## Requirements

- macOS (untested but might work on *nix)
- Docker
- awscli
- Admin access to the SourceForge project
- An AWS account

## Setup

1. Run `make build` to build the Docker image
2. Register the generated public key `id_rsa.pub` to the SourceForge CI user
3. Run `make deploy` to push the Docker image to Amazon ECR
4. Create an ECS task definition using the Docker image
    - The task will need a role with read, write, and delete permission on the
      S3 bucket where the repo tarball lives
    - You can actually stop here if you're satisfied with polling the
      repository: just set up a scheduled task. The rest of these steps are all
      just to allow on-demand triggering via webhook.
5. Create a Lambda function `OmegatGitSvnSyncFunction`
    - The lambda will need a role with permission to list ECS tasks and put
      events
6. Set up the Lambda function to be triggered by an API Gateway method
    - The method should have no authorization, as we handle that separately in the lambda
7. Create a new webhook on the svn repo that hits the API created above
8. Put the webhook secret into `./lambda/secret`
9. Run `make deploy-trigger` to push the lambda code
10. Define a CloudWatch event rule with a pattern that matches on the event
    issued by the lambda, e.g.

    ```json
    {
      "source": [
        "omegat-git-svn-sync-lambda"
      ]
    }
    ```

    and triggers the ECS task

TODO: Automate all this setup
