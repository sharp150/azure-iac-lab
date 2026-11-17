# Azure IaC Lab

1. `az group create -n rg-wr-lab-uks -l uksouth --tags owner=wayne env=lab`
2. Preview: `az deployment group what-if -g rg-wr-lab-uks -f infra/main.bicep`
3. Deploy:  `az deployment group create -g rg-wr-lab-uks -f infra/main.bicep`
4. Clean up when done: `az group delete -n rg-wr-lab-uks` (run yourself; Claude is blocked from deleting)

In Claude Code try: "Read CLAUDE.md, then add a Key Vault with RBAC auth and private access to infra/main.bicep and run what-if."

## Pipeline (phase 0)
- `.github/workflows/infra.yml`: validate (Bicep lint + PSRule) -> what-if (`lab-plan` env) -> deploy (`lab` env, needs Wayne's approval).
- Azure sign-in uses OIDC workload identity federation (app `gh-azure-iac-lab-oidc`), Contributor on `rg-wr-lab-uks` only. No secrets stored.
- Budget alert: `lab-monthly-150` on Silveroak-dev (80% actual, 100% forecast).
- Rule: never commit client data, real names, IPs or credentials. This repo is public.

## PSRule exceptions
PSRule for Azure is a blocking check in the `validate` job. The module version and baseline are pinned in `ps-rule.yaml` and bumped once a quarter in their own PR.

If a rule genuinely can't be met, the fix is an exception, not a skipped check:
1. Open a PR that adds a `SuppressionGroup` to `.ps-rule/suppressions.Rule.yaml` (copy the commented template there). Scope it to the specific rule and resource, and give the reason.
2. Wayne approves the PR. CODEOWNERS makes him a required reviewer for `.ps-rule/`, `ps-rule.yaml` and `.github/`.
3. The exception must expire: set `expiresOn` no more than 90 days ahead. An expired exception fails the build (`execution.suppressionGroupExpired: Error`), so it has to be fixed or re-approved.

Run locally: `Assert-PSRule -Format File -InputPath infra/ -Option ps-rule.yaml -Baseline '@pinned'` (with PSRule 2.9.0 and PSRule.Rules.Azure 1.47.0 installed).
