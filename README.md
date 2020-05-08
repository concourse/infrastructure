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

Note: after all this is done, the `bootstrap/terraform.tfstate` file needs to
be checked in. (Be careful not to have any credentials as outputs.)

### configuring the pipeline

From here on, all setup is done through the pipelines under the `pipelines/`
directory. These pipelines can be configured like so:

```sh
fly -t ci set-pipeline \
   -p greenpeace \
   -c pipelines/cluster.yml \
   -l sensitive/vars.yml
```