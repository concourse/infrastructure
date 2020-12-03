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
Terraform v0.13.5

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
   -p dispatcher-greenpeace \
   -c pipelines/greenpeace.yml \
   -l sensitive/vars.yml \
   -v cluster=dispatcher
```

After the `production` cluster is up, the pipeline can be run from CI to update
Concourse on the `dispatcher`.

`dispatcher`'s Concourse can be accessed at `dispatcher.concourse-ci.org`.

### restoring the CI db

A script can be manually run to restore the old CI DB from a backup. The DB instance ID and backup
ID can be found by running:

Note that the disk capacity of the new DB must be as large as the disk capacity of the old DB.
https://cloud.google.com/sql/docs/postgres/backup-recovery/restore#tips-restore-different-instance

```sh
$ gcloud sql instances list
$ gcloud sql backups list -i [instance_id]
```

The old encryption key can be retrieved by getting the helm values, inspecting the pod and the env
vars, or exec'ing onto the pod and grabbing it from there.

```sh
$ ./scripts/restore-db-backup [src_instance_id] [backup_id] [old_encryption_key]`
```

If DB was restored but the re-encryption part fails, it can be retried by running:

```sh
$ ./scripts/reencrypt-db [old_encryption_key]
```

### managing secrets

The source-of-truth of secrets for new clusters is stored in
`gs://concourse-greenpeace/vault/production/data.tar`. When an environment is
deployed, this data (containing all of the secrets in vault) is imported into
the new vault.

There are some helper scripts for managing secrets:

* `scripts/export-secrets` exports secrets under `concourse/` from the vault
  instance at `$VAULT_ADDR` and generates an encrypted bundle that can be
  uploaded to GCS
  * This can be used to generate the bundle initially
  * You need to set `VAULT_ADDR` and `VAULT_TOKEN`, but will also probably need
    to set `VAULT_SKIP_VERIFY=1`
  * You'll also need to port-forward the vault instance via `kubectl
    port-forward -n vault svc/vault 8200:8200` (if you're exporting from one of
our vaults)
  * The command will generate a `gsutil` command to upload the encrypted bundle
    to `gs://concourse-greenpeace/vault/production/data.tar`
* `scripts/edit-secrets` allows editing the existing bundle in
  `gs://concourse-greenpeace/vault/production/data.tar`
  * It uses `$EDITOR` (using `vi` as a fallback)
  * It re-encrypts the bundle and re-uploads it
