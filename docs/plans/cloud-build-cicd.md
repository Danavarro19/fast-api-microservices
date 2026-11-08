# Cloud Build CI/CD Implementation Plan

## Objective

Implement automated CI/CD for three FastAPI microservices using Google Cloud Build.

Pushes to `main`, including PR merges, trigger independent builds and deployments for services with matching file changes, using the shared `cloudbuild.yaml`.

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

- [x] Evaluate Cloud Build 2nd-generation GitHub repository connections.
- [x] Identify required APIs, IAM, and setup prerequisites.
- [x] Configure GitHub authorization.
- [x] Import the existing GitHub connection into Terraform.
- [x] Provision the repository connection and push-to-main trigger using Terraform where practical.
- [x] Configure the push trigger to match only `main` (`^main$`), including PR merges, and use the existing `cloudbuild.yaml`.
- [x] Configure the dedicated Cloud Build execution service account.

### Phase 4 — End-to-End Validation

- [ ] Create a PR with a test change targeting `main` and verify that opening or updating the PR does not trigger deployment.
- [ ] Merge the approved PR into `main` and verify that the resulting push triggers the deployment pipeline.
- [ ] Verify Cloud Build executes the existing `cloudbuild.yaml` for the pushed `main` commit.
- [ ] Verify both images exist in Artifact Registry.
- [ ] Verify deployed Cloud Run image digests and revisions.
- [ ] Test both `/health` endpoints.
- [ ] Run `terraform plan` and check for unintended infrastructure drift.

### Phase 5 — Service C

- [x] Create service-c with a health endpoint, dependency lockfile, Dockerfile, and Docker build exclusions.
- [x] Add service-c's runtime service account and Terraform service-map entry.
- [x] Use a shared service list in all pipeline steps and include service-c.

### Phase 6 — Selective Service Builds

- [x] Define one push-to-main trigger per service with service-directory and shared-pipeline file filters.
- [x] Set each trigger's `_SERVICES` substitution to its service name.
- [x] Validate independent service pipeline execution locally and review the Terraform plan.
- [ ] Replace the combined trigger with the per-service triggers in GCP.
- [ ] Verify single-service and multiple-service changes trigger only the affected service builds.
- [ ] Verify shared-pipeline changes trigger all service builds and documentation-only changes trigger none.

### Phase 7 — Service Tests

- [x] Add pytest as a development dependency and health-endpoint tests for all services.
- [x] Run tests for each selected service in one pipeline loop before image building.
- [x] Include all service tests in manual source uploads and document local test commands.
- [x] Validate all health tests, service selection, and test failure propagation locally.
- [ ] Verify each service's tests run successfully in Cloud Build before deployment.

## Constraints

- Build and deploy each service independently on matching file changes pushed to `main`, including PR merges.
- Use one shared `cloudbuild.yaml` with a per-trigger service substitution.
- Opening or updating a PR must not trigger deployment.
- Use native Cloud Build file filters for selective builds; no Nx or custom Git comparison scripts.
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
