# Cloud Build CI/CD Implementation Plan

## Objective

Implement automated CI/CD for two FastAPI microservices using Google Cloud Build.

Every PR to `main` triggers a pipeline that builds, publishes, and deploys both microservices to Cloud Run.

## Architecture

- Terraform infrastructure is defined under `iac/`.
- Application services are defined under `services/`.
- Terraform manages infrastructure, IAM, and Cloud Run configuration.
- Cloud Build manages Docker image builds, publication, and deployment.
- Existing Terraform configuration is the source of truth for GCP project identifiers, regions, service names, and Artifact Registry repositories.

## Implementation Progress

### Phase 1 — Cloud Build Identity and IAM

- [x] Create dedicated Cloud Build execution service account.
- [x] Grant Artifact Registry Writer on the existing repository.
- [x] Grant Cloud Run Developer on both Cloud Run services.
- [x] Grant Service Account User on both runtime service accounts.
- [x] Verify Cloud Logging Writer permission has been applied.
- [ ] Grant the build identity read access to the manual source staging bucket through Terraform, review the plan, and obtain approval before applying.
- [ ] Validate permissions through a successful Cloud Build execution.

### Phase 2 — Cloud Build Pipeline

- [x] Inspect existing Dockerfiles and build contexts.
- [x] Create `cloudbuild.yaml`.
- [x] Add `.gcloudignore` and verify the source upload excludes infrastructure and local files.
- [ ] Build both Docker images.
- [ ] Tag images using Git commit SHA.
- [ ] Push both images to Artifact Registry.
- [ ] Deploy images by immutable digest where practical.
- [x] Configure Cloud Logging.
- [x] Validate pipeline configuration.
- [x] Document local testing, Terraform, IAM, build, and deployment verification commands in `docs/commands.md`.

Pipeline configuration is implemented in the root `cloudbuild.yaml`. Local
upload inspection with `gcloud meta list-files-for-upload` confirmed that only
`cloudbuild.yaml` and the services' Dockerfiles, `.dockerignore` files,
dependency definitions, lockfiles, and application source are included.
Terraform state, variables, providers, and local environments are excluded.
Local
validation passed YAML parsing, Bash syntax checks, build input checks, and a
mocked build/push/digest/deploy flow, including missing-SHA and invalid-digest
rejection. This does not validate Cloud Build's server-side acceptance or live IAM.
Build, tag, push, and deployment checklist items remain pending an approved live
execution; no images have been built or deployed as part of this task.

The configuration uses the existing `cloud-build-sa` identity and
`CLOUD_LOGGING_ONLY`. The future PR trigger must explicitly select that same
identity because trigger settings override the configuration's service account.
Deployment updates only each existing service's image, using its pushed digest.
Updates to the two services are sequential and are not atomic.

### Phase 3 — GitHub Integration

- [ ] Evaluate Cloud Build 2nd-generation GitHub repository connections.
- [ ] Identify required APIs, IAM, and setup prerequisites.
- [ ] Configure GitHub authorization.
- [ ] Provision the repository connection and pull request trigger using Terraform where practical.
- [ ] Configure the trigger for every PR targeting `main`.
- [ ] Configure the dedicated Cloud Build execution service account.

### Phase 4 — End-to-End Validation

- [ ] Create a PR with a test change to `main`.
- [ ] Verify Cloud Build execution.
- [ ] Verify both images exist in Artifact Registry.
- [ ] Verify deployed Cloud Run image digests and revisions.
- [ ] Test both `/health` endpoints.
- [ ] Run `terraform plan` and check for unintended infrastructure drift.

## Constraints

- Build both services on every PR to `main`.
- No Nx or selective build detection.
- No long-lived service account keys.
- Prefer Terraform for infrastructure configuration.
- Preserve existing Cloud Run runtime identities and settings.
- Minimize costs and unnecessary infrastructure.
- Avoid broad project-level IAM roles where resource-level bindings are available.
- Do not automatically apply infrastructure or deploy without approval.

## Execution Rules

Complete one task at a time.

Before each task, explain the proposed implementation and wait for approval.

After implementation, report changed files, validation results, and remaining work.

Update checklist items only after verifying completion.

The repository is the source of truth. Reconcile this plan with the actual code and Terraform state before implementation.
