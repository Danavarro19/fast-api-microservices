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
- [x] Grant the Cloud Build service account Storage Object Viewer on the source staging bucket for manual builds.
- [x] Validate permissions through a successful Cloud Build execution.

### Phase 2 — Cloud Build Pipeline

- [x] Inspect existing Dockerfiles and build contexts.
- [x] Create `cloudbuild.yaml`.
- [x] Add `.gcloudignore` and verify the source upload excludes infrastructure and local files.
- [x] Build both Docker images.
- [x] Tag images using Git commit SHA.
- [x] Push both images to Artifact Registry.
- [x] Deploy images by immutable digest where practical.
- [x] Configure Cloud Logging.
- [x] Validate pipeline configuration.
- [x] Document local testing, Terraform, IAM, build, and deployment verification commands in `docs/commands.md`.

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
