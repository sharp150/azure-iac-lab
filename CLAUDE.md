# Azure IaC Lab - rules for Claude

Purpose: learning lab for deploying Azure services as code. Subscription: Silveroak-dev only.

## Always
- Use Bicep for all infrastructure (files in `infra/`). No portal or ad-hoc `az ... create` commands.
- Region: `uksouth` (fallback `ukwest`).
- Tag every resource: `owner=wayne`, `env=lab`, `managedBy=bicep`.
- Secure by default: no public network access unless asked, HTTPS/TLS 1.2+, disable shared key / local auth where supported, managed identity over keys, diagnostic settings where practical.
- Run `az bicep build` and `az deployment group what-if` BEFORE any deployment, and show the what-if summary.
- Before deploying, confirm `az account show` is Silveroak-dev. Stop if it isn't.
- Keep resources cheap (lowest SKU that works) and explain cost impact.

## Never
- Never hard-code secrets, keys or passwords. Use Key Vault references or parameters marked @secure().
- Never delete resource groups or resources unless Wayne explicitly asks in that message.
- Never change RBAC role assignments or policies without asking.
