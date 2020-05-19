# greenpeace

automate everything

## deploying from zero

### requirements

```sh
$ gcloud version
Google Cloud SDK 291.0.0
bq 2.0.57
core 2020.05.01
gsutil 4.50

$ terraform version
Terraform v0.12.24

$ jq --version
jq-1.6
```

...but you can probably get away with slightly different versions

### bootstrapping

First, authenticate your account with `gcloud auth`:

```sh
gcloud auth application-default login
```

This will save your GKE credentials in a JSON file under `~/.config/gcloud`,
which the `terraform` CLI will automatically use.

Next, run:

```sh
./bootstrap/setup
```

This will create the following:

1. The `concourse-greenpeace` bucket, which will store the Terraform state
   for all of our deployments.

1. A `greenpeace-terraform` service account, which has permissions to write
   to the bucket and perform various operations within the GCP project.

After these have been created, it will revoke any existing keys for the
service account and generate a new one, placing it under `sensitive/`.

The script will then fetch the `concourse_bot_private_key` secret from GCP
Secret Manager. This secret is necessary for pulling the Greenpeace repo in
the bootstrapping pipeline, since this repo is private.

It will also prompt you to ensure that the required secrets have been added
to GCP Secret Manager. The following secrets must be created:

* `production-ci-github_client_id` - the client ID of the Github application
  for authenticating with the CI concourse deployment
* `production-ci-github_client_secret` - the client ID of the Github
  application for authenticating with the CI concourse deployment
* `dispatcher-concourse-github_client_id` - the client ID of the Github
  application for authenticating with the concourse deployment in the
  dispatcher cluster
* `dispatcher-concourse-github_client_secret` - the client secret of the Github
  application for authenticating with the concourse deployment in the
  dispatcher cluster

Note: after all this is done, the `bootstrap/terraform.tfstate` file needs to
be checked in. (Be careful not to have any credentials as outputs.)

### deploy the dispatcher

The next step is to deploy the `dispatcher` cluster. This cluster is solely
responsible for continuously deploying the `production` cluster.

`dispatcher` is deployed through a Concourse pipeline. If this is the first
deploy, you should run this pipeline on a local Concourse:

```sh
fly -t dev set-pipeline \
   -p dispatcher_greenpeace \
   -c pipelines/greenpeace.yml \
   -l sensitive/vars.yml \
   -v cluster=dispatcher
```

After the `production` cluster is up, the pipeline can be run from CI to update
Concourse on the `dispatcher`.

`dispatcher`'s Concourse can be accessed at `dispatcher.concourse-ci.org`.
