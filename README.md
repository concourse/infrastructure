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
Terraform v0.14.7

$ jq --version
jq-1.6

$ ytt --version
ytt version 0.31.0
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

#### bootstrap credentials

In order for the deployments to operate, they require their vault instance to
be populated with credentials. Each environment has its own set of credentials
that can diverge, but `production`'s is the source of truth for new clusters.

Each environment stores its vault data in the [greenpeace bucket] -
specifically, at the path `vault/ENVIRONMENT/data.tar`.

For the production cluster, this can be first created by exporting from an
existing vault instance by running `./scripts/export-secrets` (see [managing
secrets]).

For other environments, this can be created by syncing with the production
cluster by triggering the job `sync-secrets-with-production` in the pipeline.

### deploy the dispatcher

The next step is to deploy the `dispatcher` cluster. This cluster is solely
responsible for continuously deploying the `production` cluster.

`dispatcher` is deployed through a Concourse pipeline. If this is the first
deploy, you should run this pipeline on a local Concourse:

```sh
ytt -v cluster=dispatcher -f pipelines/greenpeace.yml -f pipelines/data.yml | \
  fly -t dev set-pipeline \
    -l sensitive/vars.yml \
    -p dispatcher-greenpeace \
    -c -
```

After the `production` cluster is up, the pipeline can be run from CI to update
Concourse on the `dispatcher`.

`dispatcher`'s Concourse can be accessed at [`dispatcher.concourse-ci.org`](https://dispatcher.concourse-ci.org/).

After deploying the `dispatcher`, you should set the reconfigure pipeline:

```sh
fly -t dispatcher sp -p reconfigure -c pipelines/reconfigure.yml
```

This will configure the `production` pipeline, which will trigger automatically
and create the production cluster. Once the `terraform` job completes, you should set the reconfigure pipeline on CI:

```sh
fly -t ci sp -p reconfigure-pipelines -c ~/workspace/ci/pipelines/reconfigure.yml
```

This will bootstrap the initial pipelines and teams. Note that there may be a
race condition between creating the initial pipelines and teams - if the
reconfigure jobs error, they should pass on a rerun.

### restoring the CI db

A script can be manually run to restore the old CI DB from a backup. The DB instance ID and backup
ID can be found by running:

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

Note that the disk capacity of the new DB must be as large as the disk capacity of the old DB.
https://cloud.google.com/sql/docs/postgres/backup-recovery/restore#tips-restore-different-instance

### managing secrets

The source-of-truth of secrets for new clusters is stored in
`gs://concourse-greenpeace/vault/production/data.tar`. When an environment is
deployed, this data (containing all of the secrets in vault) is imported into
the new vault.

There are some helper scripts for managing secrets:

* `scripts/connect-to-vault` gives you a shell on the vault pod for an
  environment
  * Once you have a shell, you can run `vault read ...` and `vault write ...`
  * You must provide the environment name you want to connect to, e.g.
    `./scripts/connect-to-vault production`
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

#### encryption

There are two encryption keys used to encrypt the vault data:

1. A randomly generated 32 byte sequence for encrypting the data, and
2. A Google KMS crypto key for encrypting aforementioned key

This is because KMS crypto keys can only encode small payloads.

#### Connecting to Vault

```sh
gsutil cat "gs://concourse-greenpeace/vault/production/root-token.enc" | \
  base64 --decode | \
    gcloud kms decrypt \
      --key "projects/cf-concourse-production/locations/global/keyRings/greenpeace-kr/cryptoKeys/greenpeace-key" \
      --ciphertext-file - \
      --plaintext-file -
```

Will print the Vault root token. Then exec onto the vault container:

```sh
gcloud container clusters get-credentials production --zone us-central1-a --project cf-concourse-production
kubectl exec -it -n vault vault-0 -- sh
```

Then set these env vars:

```sh
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN='TOKEN-FROM-FIRST-COMMAND'
```

Vault commands should work now.

#### vault ca cert expires

When the vault ca cert expires, it is automatically re-created through the terraform job for that environment. For example, if the dispatcher vault ca cert expires, it would be through [terraform job in the dispatcher pipeline](https://ci.concourse-ci.org/teams/main/pipelines/dispatcher-greenpeace/jobs/terraform). Once this terraform job has deleted the old ca cert, created a new one and run successfully, you might have to restart the vault pod manually using `kubectl delete pod -n <namespace> vault-0`.

In strange cases, the terraform job won't actually recreate the expired vault CA certs though.  i, that is, clarp tincan, haven't figured out what causes it, but was able to develop a procedure to fix it at the very least.  You might not ever need these steps, but hopefully they'll save you a LOT of time and turmoil if you ever do.  The basic goal is to use [the new `-replace` flag in Terraform 1.5](https://developer.hashicorp.com/terraform/cli/commands/plan#replace-address), though it takes a bit of work to get there:
* Install terraform 1.5+ on your local machine.  i did this on v1.5.4.
* `cd` to whichever `terraform/environments/[deployment]` directory has the expired vault CA cert.
* Delete the `.terraform.lock.hcl` file and `.terraform/` folder, if present.
* Run the following to end up with a 1.5.x-syntaxed version of the above files/folders:
    * `terraform init`
    * `gcloud container clusters get-credentials [deployment]`
    * `terraform workspace select [deployment]`
* Rename the `variables.yml` file to `variables.tfvars`, and make the following syntax changes to make it 1.5 compatible:
    * Change all the ":" separators to "=".
    * Put double quotes around all the argument values.
* Go to the CF-Concourse-Production GCP project, and make an IAM user with the following roles: Editor, Secret Manager Secret Accessor.  Save its json secrets locally, because we'll need it in a second.
* Run this command to (hopefully) force terraform to rotate the cert and all the certs that derive from it.  You'll know if it worked because it'll say something like "9 replaced" and show the changes to the CA cert and its derivatives.  
    * `terraform apply -var 'concourse_chart_version=17.1.1' -var 'vault_root_ca_validity_period=87600' -var credentials="$(cat [path_to_iam_user_json_secrets_file])" -var-file='variables.tfvars' -replace='module.vault.tls_self_signed_cert.ca'`
* To get the vault container to pick up the new cert, you'll next have to delete the vault pods currently running in Kubernetes as outlined at the beginning of this section.  When they get remade, they should be healthy.
* If both production and dispatcher had expired CA certs, you've been in a deadlock situation this whole time where neither CI system can access either Vault.  This makes it impossible to use CI to replace the old certs.  If you're in this state, you'll have to break the deadlock yourself by manually replacing each cert.  Do this procedure twice, once for dispatcher and once for production:
    * Get the deployment's Vault root key from the CF-Concourse-Production GCP project:
        ```bash
        gsutil cat "gs://concourse-greenpeace/vault/[DEPLOYMENT]/root-token.enc" | \
          base64 --decode | \
            gcloud kms decrypt \
              --key "projects/cf-concourse-production/locations/global/keyRings/greenpeace-kr/cryptoKeys/greenpeace-key" \
              --ciphertext-file - \
              --plaintext-file -
        ```
    * SSH into the Vault K8s container: `scripts/connect-to-vault [deployment]`
    * Log into the Vault using the decrypted Vault root token: `vault login token=[root_token]`
    * Get the expired root CA definition: `vault read auth/cert/certs/concourse`
    * As a safety-check, manually copy-paste that root CA into a text file and open it up.  Use the issue and expiration fields to confirm this is indeed the failing cert.
        * `openssl x509 -noout -text -in '[cert_file_path]'`
        * Keep this file until you've successfully rotated certs, just to be on the safe side.
    * Because you recreated the Vault K8s container earlier, it contains a local copy of the new cert.  Use the environment variable `VAULT_CACERT` to find its location.  Open it up using the same openssl command and validate that the issue / expiry dates look correct.
        * Just in case the environment isn't working, as of time of writing (10/17/24): `VAULT_CACERT=/vault/userconfig/vault-server-tls/vault.ca`
    * Now that you've validated the new cert, write it to Vault with this command: `vault write auth/cert/certs/concourse "policies=concourse" "certificate=$(cat $VAULT_CACERT)"`
    * Wait a couple of minutes for the changes to propagate. Resource checks in CI should now succeed.
    * Make sure to repeat these steps with the other deployment.
* Then finally, run the `initialize-vault` job from the opposite-deployment you updated.  So if you're fixing production, you'd run the job from dispatcher and vice versa.

If this didn't work, consider crying.

If crying didn't work, consider weeping profusely.

If the problem still persists, welp.

Also worth noting, here are some things that didn't work for me:
* Just deleting the old, expired cert from GCP and running the terraform-dispatcher job from the opposite deployment's ci. i forget what happened, but i think the job just complains that the file doesn't exist and fails.
* Downloading the deployment's tfstate (gcp://CF-Concourse-Production/concourse-greenpeace/terraform/[deployment].tfstate), deleting the CA cert by hand, and reuploading it. Terraform just somehow restores the old cert and keeps using it - it doesn't trigger it to get recreated. i tried like every combination of deleting entire fields or just deleting values in the entire file, and nothing worked.
* Simply deleting and recreating K8s containers isn't enough to get the new certs into Vault itself.  Your only options are to access Vault directly and manually replace the certs, or delete the entire Vault instance, recreate it from scratch, restore its contents using backups from GCP, and hope you haven't lost anything important.




[greenpeace bucket]: https://console.cloud.google.com/storage/browser/concourse-greenpeace
[managing secrets]: #managing-secrets
