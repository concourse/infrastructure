# Bosh

Everything in this folder is for setting up and managing our
[bosh](https://bosh.io) environment.

We use [bbl](https://github.com/cloudfoundry/bosh-bootloader/) to create and
manage the environment. Make sure to install the `bbl` cli from the Github
Release page. The Homebrew tap has not been updated for a few years.

With the bosh environment setup, we then deploy a Concourse worker. That worker
is used to reach the director and run our Topgun tests.

We have some customizations for the following:
- Allowing network access between the worker and director
- Disabling the use of DNS addresses

See [this
page](https://github.com/cloudfoundry/bosh-bootloader/blob/main/docs/customization.md)
for the hooks `bbl` gives us to do these customizations.

## Connecting to the Bosh Director and Credhub

First, download the bbl state files by running `download-bbl-state.sh`.

You need a GCP service account key. Create and download one in JSON format
here: https://console.cloud.google.com/apis/credentials/serviceaccountkey

Save and name the account key `topgun-gcp-key.json` in the root of this folder.

Set the following env vars in your terminal:

```sh
export BBL_STATE_DIR=$PWD/bosh-topgun-bbl-state
export BBL_IAAS=gcp
export BBL_GCP_REGION=us-central1
export BBL_GCP_SERVICE_ACCOUNT_KEY=$PWD/topgun-gcp-key.json
export BBL_GCP_SERVICE_ACCOUNT_KEY_PATH=$PWD/topgun-gcp-key.json
export BBL_GCP_PROJECT_ID=cf-concourse-production
export BBL_GCP_ZONE=us-central1-f
```

Then run

```sh
cd bosh-topgun-bbl-state
eval "$(bbl print-env)"
```

You can now run `bosh` or `credhub` commands. Try `bosh deployments` or
`credhub find`.

If you change any of the files under `bosh-topgun-bbl-state` make sure to
upload them back up to GCS by running `upload-local-bbl-state.sh`.

## Updating the Bosh worker for ci.concourse-ci.org

We only have one bosh worker for CI. You can manually deploy it using
the YAML file in `./deployments`. Edit `bosh-worker.yml` with new release from
https://bosh.io/releases/github.com/concourse/concourse-bosh-release or
from one of the releases already uploaded. You can see those by running `bosh
releases`.

```sh
bosh -d bosh-worker deploy ./deployments/bosh-worker.yml
```

## Rotating Director and Jumpbox certs

Every year the certs on the director and jumpbox will expire and need to be
renewed. To do that, follow the steps above for connecting to the director.
When you try running `bosh` commands you should get a "certificate expired"
error.

Before doing this, make sure your `bbl version` matches what's in
`./bosh-topgun-bbl-state/bbl-state.json`. Being a few versions ahead is okay,
but safest is being on the same version as the last deployment.

Go into `./bosh-topgun-bbl-state/vars/` and rename all `*-vars-store.yml` files
so they end with `.bak`. The missing vars-stores will cause `bbl` to generate
new certificates and re-deploy the jumpbox and director with them. To begin
that process run:

```sh
bbl plan
bbl up
```

You can delete the `*.bak` files once everything completes successfully. Make
sure to upload everything to GCS using `upload-local-bbl-state.sh`.

Other tips here: https://github.com/cloudfoundry/bosh-bootloader/issues/424

## Setting up Network Access Between the Worker and Director

Network access is managed via network tags. The bbl env creates a "*-bosh-open"
tag for access between the Jumpbox and Director. We can re-use this tag to
create access between the Worker and Director too.

First we need to update the bosh cloud-config to add a new `vm_extension`. This
is how we apply arbitrary tags to vm's.

```yaml
# File: bosh-open.yml
# Location: ${BBL_STATE_DIR}/cloud-config/
- type: replace
  path: /vm_extensions/-
  value:
    name: bosh-open
    cloud_properties:
      # Replace this with the tag from the Jumpbox VM. Look it up in the GCP console.
      tags: [bbl-env-great-salt-2025-12-05t17-29z-bosh-open]
```

`bbl` will detect the `bosh-open.yml` ops files and use it.
```sh
cd ./bosh-topgun-bbl-state
bbl plan
bbl up
```

Now the worker can be successfully deployed using the `bosh-open` vm extension.
