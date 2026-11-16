# Azure IaC Lab

1. `az group create -n rg-wr-lab-uks -l uksouth --tags owner=wayne env=lab`
2. Preview: `az deployment group what-if -g rg-wr-lab-uks -f infra/main.bicep`
3. Deploy:  `az deployment group create -g rg-wr-lab-uks -f infra/main.bicep`
4. Clean up when done: `az group delete -n rg-wr-lab-uks` (run yourself; Claude is blocked from deleting)

In Claude Code try: "Read CLAUDE.md, then add a Key Vault with RBAC auth and private access to infra/main.bicep and run what-if."
