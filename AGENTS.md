# Engineering Instructions

## Project

This repository is a GCP learning POC containing two independent FastAPI microservices deployed to Cloud Run.

Infrastructure is managed using Terraform under `iac/`.

## Engineering principles

- Prefer simple solutions over unnecessary abstractions.
- Follow existing repository conventions.
- Inspect relevant files before proposing changes.
- Preserve separation between infrastructure management and application deployment.
- Use least-privilege IAM and avoid long-lived credentials.
- Explain significant architectural decisions and trade-offs.

## Working process

1. Read the relevant implementation plan under `docs/plans/`.
2. Inspect the current repository state.
3. Identify the next incomplete task.
4. Explain the proposed changes before implementing them.
5. Wait for explicit approval.
6. Implement only the approved task.
7. Run appropriate local validation.
8. Summarize changes and validation results.
9. Update the implementation plan's progress checklist.

## Safety

- Never execute `terraform apply` or `terraform destroy` without explicit approval.
- Never modify live GCP resources without explicit approval.
- Never deploy applications without explicit approval.
- Review `terraform plan` before infrastructure changes.
- Do not modify unrelated files.
- Do not commit or push changes without explicit approval.

## Current work

See `docs/plans/cloud-build-cicd.md` for the active CI/CD implementation plan.
