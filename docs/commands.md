# Project commands

Run from the repository root in Bash unless stated otherwise. Requires Python
3.12+, uv, Docker (for local containers), Terraform, and the Google Cloud CLI.
Read-only inspection does not require deployment approval. Commands labeled
**Changes local files**, **Publishes**, **Deploys**, or **Changes infrastructure**
must be used intentionally; live changes require explicit approval.

## Common variables

Values match `iac/`; update these when the Terraform configuration changes.

```bash
export PROJECT_ID=poc-microservices-dev
export REGION=us-central1
export REPOSITORY=microservices
export BUILD_SA="cloud-build-sa@${PROJECT_ID}.iam.gserviceaccount.com"
export SOURCE_BUCKET="${PROJECT_ID}_cloudbuild"
export IMAGE_ROOT="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}"
export COMMIT_SHA="$(git rev-parse HEAD)"
```

## Authentication and project checks

```bash
gcloud auth list
gcloud config list
gcloud services list --enabled --project="$PROJECT_ID"
```

**Changes local credentials:** use interactive user login, without service account keys.

```bash
gcloud auth login
# Terraform uses Application Default Credentials, separately from CLI login.
gcloud auth application-default login
```

## Run services locally

**Changes local files:** installs locked dependencies in each service's environment.
Run each server in a separate terminal; stop with Ctrl+C.

```bash
uv sync --project services/service-a --locked
uv run --project services/service-a --no-sync uvicorn app.main:app --app-dir services/service-a --port 8081
```

```bash
uv sync --project services/service-b --locked
uv run --project services/service-b --no-sync uvicorn app.main:app --app-dir services/service-b --port 8082
```

```bash
curl --fail-with-body http://localhost:8081/health
curl --fail-with-body http://localhost:8082/health
```

Expect the corresponding service name and `"status":"active"`.

## Build and run Docker images

**Changes local Docker state:** builds both images using separate build contexts.

```bash
for service in service-a service-b; do
  docker build --tag "${IMAGE_ROOT}/${service}:${COMMIT_SHA}" "services/${service}"
done
```

Run one container in a terminal, then check it from another terminal. Stop with Ctrl+C.

```bash
docker run --rm --publish 8081:8080 --env PORT=8080 "${IMAGE_ROOT}/service-a:${COMMIT_SHA}"
```

```bash
curl --fail-with-body http://localhost:8081/health
```

For service B, use `service-b` and host port `8082`.

## Push and inspect images

**Changes local Docker authentication:** configure the registry credential helper.

```bash
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
```

**Publishes:** pushes both local images using your active user credentials.
This does not test the Cloud Build service account's permissions.

```bash
for service in service-a service-b; do
  docker push "${IMAGE_ROOT}/${service}:${COMMIT_SHA}"
done
```

Read-only registry inspection:

```bash
gcloud artifacts docker images list "$IMAGE_ROOT" --include-tags --project="$PROJECT_ID"
gcloud artifacts docker tags list "${IMAGE_ROOT}/service-a" --project="$PROJECT_ID"
gcloud artifacts docker images describe "${IMAGE_ROOT}/service-a:${COMMIT_SHA}" --project="$PROJECT_ID"
```

After a local push, inspect the immutable reference recorded by Docker:

```bash
docker image inspect "${IMAGE_ROOT}/service-a:${COMMIT_SHA}" --format '{{index .RepoDigests 0}}'
```

## Terraform

**Changes local files:** initializes providers; formats configuration.

```bash
terraform -chdir=iac init
terraform -chdir=iac fmt -recursive
```

Read-only formatting, validation, and state inspection:

```bash
terraform -chdir=iac fmt -check -recursive
terraform -chdir=iac validate
terraform -chdir=iac state list
terraform -chdir=iac output
```

**Creates a local plan:** reads live GCP configuration but does not apply changes.
Review every proposed change. State and plan files can contain sensitive data.
Keep them out of Git and source uploads.

```bash
terraform -chdir=iac plan -out=reviewed.tfplan
terraform -chdir=iac show -no-color reviewed.tfplan
```

**Changes infrastructure — explicit approval required:** apply only after review.

```bash
terraform -chdir=iac apply reviewed.tfplan
```

After application deployment, run `terraform -chdir=iac plan` to inspect drift.
Terraform ignores container image changes; other unexpected changes need review.

## Import the GitHub connection

After browser authorization creates the connection, define its matching resource
in `iac/cloud_build.tf`. Import it once per Terraform state, then check the plan.
Import updates Terraform state without modifying the existing GCP connection.

```bash
terraform -chdir=iac import google_cloudbuildv2_connection.github \
  "projects/${PROJECT_ID}/locations/${REGION}/connections/github-connection"
terraform -chdir=iac plan
```

## Inspect IAM bindings

These commands inspect policies, not effective access. Conditions, inherited
policies, and deny policies can affect access. A successful build is the execution test.

```bash
# Logging Writer at project level
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten='bindings[].members' \
  --filter="bindings.members=serviceAccount:${BUILD_SA}" \
  --format='table(bindings.role,bindings.members)'

# Artifact Registry Writer on the repository
gcloud artifacts repositories get-iam-policy "$REPOSITORY" \
  --location="$REGION" --project="$PROJECT_ID"

# Cloud Run Developer on each service
for service in service-a service-b; do
  gcloud run services get-iam-policy "$service" --region="$REGION" --project="$PROJECT_ID"
done

# Service Account User on each runtime identity
for service in service-a service-b; do
  gcloud iam service-accounts get-iam-policy "${service}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project="$PROJECT_ID"
done

# Read access to manually uploaded build source
gcloud storage buckets get-iam-policy "gs://${SOURCE_BUCKET}"
```

The submitting user needs permission to create builds, upload source, and act as
the build identity. The execution identity needs the runtime permissions above
and read access to the source archive. Manage permission changes through Terraform.

## Submit and inspect Cloud Build

Preview uploads first. Expect only `cloudbuild.yaml` and required service build
inputs; `.gcloudignore` excludes infrastructure, local environments, and other files.
The preview checks file selection, not file contents for secrets.

```bash
git status --short
gcloud meta list-files-for-upload
```

**Publishes and deploys — explicit approval required:** uploads local source to
Cloud Storage, builds and pushes both images, then updates both Cloud Run services.
Use a clean committed tree so the commit tag identifies the uploaded code.
Local Docker is not required for this command. `--async` returns without waiting.

```bash
gcloud builds submit . \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --config=cloudbuild.yaml \
  --substitutions="COMMIT_SHA=${COMMIT_SHA}" \
  --async
```

Set `BUILD_ID` to the ID printed by a successful submission. If submission is
rejected before build creation, no new build ID may be returned.

```bash
export BUILD_ID=REPLACE_WITH_BUILD_ID
gcloud builds list --project="$PROJECT_ID" --region="$REGION" --limit=5
gcloud builds describe "$BUILD_ID" --project="$PROJECT_ID" --region="$REGION"
gcloud logging read "resource.type=\"build\" AND resource.labels.build_id=\"${BUILD_ID}\"" \
  --project="$PROJECT_ID" --freshness=1d --order=asc --limit=200
```

Builds use `CLOUD_LOGGING_ONLY`; inspect logs through Cloud Logging. Build success
requires all four steps to finish. Service deployments are sequential, not atomic.

## Verify deployed Cloud Run services

```bash
for service in service-a service-b; do
  gcloud run services describe "$service" --project="$PROJECT_ID" --region="$REGION" \
    --format='yaml(status.url,status.latestReadyRevisionName,status.conditions,status.traffic,spec.template.spec.containers)'
  revision="$(gcloud run services describe "$service" --project="$PROJECT_ID" --region="$REGION" \
    --format='value(status.latestReadyRevisionName)')"
  gcloud run revisions describe "$revision" --project="$PROJECT_ID" --region="$REGION" \
    --format='yaml(metadata.name,status.imageDigest,status.conditions)'
  url="$(gcloud run services describe "$service" --project="$PROJECT_ID" --region="$REGION" \
    --format='value(status.url)')"
  curl --fail-with-body "${url}/health"
done
```

Compare revision digests with the pushed images. Check traffic actually targets
the expected revision; a healthy URL alone does not prove it serves the new image.

## References

- [Source upload exclusions](https://docs.cloud.google.com/sdk/gcloud/reference/topic/gcloudignore)
- [Submit a build](https://docs.cloud.google.com/sdk/gcloud/reference/builds/submit)
- [User-managed build identities](https://docs.cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts)
- [Cloud Storage IAM](https://docs.cloud.google.com/storage/docs/access-control/iam)
- [Artifact Registry inspection](https://docs.cloud.google.com/sdk/gcloud/reference/artifacts/docker/images/list)
