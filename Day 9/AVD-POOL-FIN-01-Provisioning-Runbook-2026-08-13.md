# AVD Provisioning Runbook — POOL-FIN-01 / FinBridge-Workspace
**Date:** 2026-08-13  
**Engineer:** traininguser17@zippyops.in  
**Project:** Windows 11 Desktop Workplace Migration — Finance Pool  

---

## Environment

| Parameter | Value |
|---|---|
| Subscription ID | b2f12c89-b8dc-496c-bd77-6c41d7fc0340 |
| Resource Group | dwp-lab-rg |
| Region | Central US |
| M365 Tenant | zippyops.in |
| End-User Account | p15@zippyops.in |
| VNet | dwp-p15-winVNET (10.0.0.0/16) |
| Subnet | dwp-p15-winSubnet (10.0.0.0/24) |

---

## Pre-Flight: Confirm Identity & Permissions

Verify the signed-in CLI identity and confirm it holds a role that permits resource and role-assignment creation.

```powershell
az account show --query "{subscriptionId:id, name:name, tenantId:tenantId, user:user.name}" -o table

az role assignment list `
  --assignee traininguser17@zippyops.in `
  --subscription b2f12c89-b8dc-496c-bd77-6c41d7fc0340 `
  --query "[].{Role:roleDefinitionName, Scope:scope}" -o table
```

**Result:** `traininguser17@zippyops.in` — **Owner** on subscription scope. Full permissions including role assignments confirmed.

---

## Step 1 — Install desktopvirtualization CLI Extension

The `az desktopvirtualization` commands require an Azure CLI extension that is not installed by default. Accept the prompt on first use.

```powershell
# Extension installs automatically on first desktopvirtualization command.
# To pre-install and suppress future prompts:
az config set extension.use_dynamic_install=yes_without_prompt
```

---

## Step 2 — Create Host Pool: POOL-FIN-01

```powershell
az desktopvirtualization hostpool create `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01 `
  --location centralus `
  --host-pool-type Pooled `
  --load-balancer-type BreadthFirst `
  --max-session-limit 5 `
  --personal-desktop-assignment-type Automatic `
  --preferred-app-group-type Desktop `
  --validation-environment false `
  --query "{name:name, hostPoolType:hostPoolType, loadBalancerType:loadBalancerType, maxSessionLimit:maxSessionLimit}" `
  -o table
```

**Result:**

| Name | HostPoolType | LoadBalancerType | MaxSessionLimit |
|---|---|---|---|
| POOL-FIN-01 | Pooled | BreadthFirst | 5 |

---

## Step 3 — Create Desktop Application Group

```powershell
az desktopvirtualization applicationgroup create `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01-DAG `
  --location centralus `
  --application-group-type Desktop `
  --host-pool-arm-path "/subscriptions/b2f12c89-b8dc-496c-bd77-6c41d7fc0340/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01" `
  --query "{name:name, applicationGroupType:applicationGroupType}" -o table
```

**Result:** `POOL-FIN-01-DAG` — Type: Desktop

---

## Step 4 — Create Workspace and Register App Group

```powershell
az desktopvirtualization workspace create `
  --resource-group dwp-lab-rg `
  --name FinBridge-Workspace `
  --location centralus `
  --application-group-references "/subscriptions/b2f12c89-b8dc-496c-bd77-6c41d7fc0340/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/POOL-FIN-01-DAG" `
  --query "{name:name}" -o table
```

**Result:** `FinBridge-Workspace` created with `POOL-FIN-01-DAG` registered.

---

## Step 5 — Generate Host Pool Registration Token

The token is valid for 2 hours. Re-run this command if it expires before the VM extension installation completes.

```powershell
$expiry = (Get-Date).AddHours(2).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$token = az desktopvirtualization hostpool update `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01 `
  --registration-info "expiration-time=$expiry" "registration-token-operation=Update" `
  --query "registrationInfo.token" -o tsv
Write-Host "Token length: $($token.Length)"
```

> **Note:** `$token` must remain in scope for Step 8. If the terminal session is recycled, re-run this block before proceeding.

---

## Step 6 — Create Session Host VM

**Image:** Windows 11 multi-session 24H2 AVD-optimised (`win11-24h2-avd`)  
**Size:** Standard_B2ms  
**Security:** Trusted Launch — Secure Boot ✓, vTPM ✓  
**Network:** No public IP, no new NSG (uses existing VNet/subnet)  

```powershell
# Discover the latest image version first
az vm image list `
  --publisher MicrosoftWindowsDesktop `
  --offer windows-11 `
  --sku win11-24h2-avd `
  --all `
  --query "[-1].{urn:urn, version:version}" -o table
```

```powershell
az vm create `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01-SH0 `
  --location centralus `
  --image "MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:26100.9168.260809" `
  --size Standard_B2ms `
  --vnet-name dwp-p15-winVNET `
  --subnet dwp-p15-winSubnet `
  --security-type TrustedLaunch `
  --enable-secure-boot true `
  --enable-vtpm true `
  --admin-username avdadmin `
  --admin-password "<REDACTED>" `
  --public-ip-address '""' `
  --nsg '""' `
  --query "{name:name, provisioningState:provisioningState}" -o table
```

> **PowerShell quoting note:** `--public-ip-address` and `--nsg` must be passed as `'""'` in PowerShell to produce an empty string that the Azure CLI accepts. Bare `""` is parsed away by the shell before reaching the CLI.

**Result:** `POOL-FIN-01-SH0` — ProvisioningState: Succeeded, TrustedLaunch, Secure Boot: True, vTPM: True

---

## Step 7 — Assign System-Assigned Managed Identity

> **Critical prerequisite** for Step 8. Without a managed identity the `AADLoginForWindows` extension can authenticate to Entra ID to register the device, so the VM will provision but remain `AzureAdJoined: NO`.

```powershell
az vm identity assign `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01-SH0 `
  --identities "[system]" `
  --query "{principalId:systemAssignedIdentity}" -o table
```

**Result:** System-assigned identity `73a10022-3fdd-413f-b366-a2b58962f8ac` assigned.

---

## Step 8 — Install AADLoginForWindows Extension (Entra ID Join)

This extension joins the VM to Entra ID (no on-premises AD required) and enables Entra ID-based RDP authentication.

```powershell
az vm extension set `
  --resource-group dwp-lab-rg `
  --vm-name POOL-FIN-01-SH0 `
  --name AADLoginForWindows `
  --publisher Microsoft.Azure.ActiveDirectory `
  --query "{name:name, provisioningState:provisioningState}" -o table
```

**Verify the join completed:**

```powershell
az vm run-command invoke `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01-SH0 `
  --command-id RunPowerShellScript `
  --scripts "dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|TenantName|DeviceId'" `
  --query "value[0].message" -o tsv
```

Expected output: `AzureAdJoined : YES`

---

## Step 9 — Install AVD DSC Extension (Agent Registration)

The DSC extension downloads the AVD agent, registers the session host against POOL-FIN-01, and sets `AadJoin=true` so the agent operates in Entra-ID-only mode.

**Prepare the settings file** (avoids PowerShell JSON quoting issues with the Azure CLI):

```powershell
$dscUrl = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip"

$json = "{`"modulesUrl`":`"$dscUrl`"," +
        "`"configurationFunction`":`"Configuration.ps1\\AddSessionHost`"," +
        "`"properties`":{" +
          "`"HostPoolName`":`"POOL-FIN-01`"," +
          "`"RegistrationInfoToken`":`"$token`"," +
          "`"AadJoin`":true," +
          "`"UseAgentDownloadEndpoint`":true," +
          "`"aadJoinPreview`":false," +
          "`"mdmId`":`"`"" +
        "}}"

$json | Out-File -FilePath "$env:TEMP\dsc-settings.json" -Encoding utf8 -NoNewline
```

**Install the extension:**

```powershell
az vm extension set `
  --resource-group dwp-lab-rg `
  --vm-name POOL-FIN-01-SH0 `
  --name DSC `
  --publisher Microsoft.Powershell `
  --version 2.73 `
  --settings "$env:TEMP\dsc-settings.json" `
  --query "{name:name, provisioningState:provisioningState}" -o table
```

**Result:** DSC — Succeeded (installs RDAgent 1.0.15008.300, RDAgentBootLoader 1.0.8925.0, SxS Stack 1.0.2605.19600)

> **Token expiry:** If the registration token has expired between steps, re-run Step 5 and regenerate `dsc-settings.json` before running this command.

---

## Step 10 — Restart VM (Post-Extension Boot)

A restart is required after Entra ID join and DSC extension installation to:
- Complete Entra ID device registration in the OS
- Allow the SxS Stack service to register on first boot

```powershell
az vm restart --resource-group dwp-lab-rg --name POOL-FIN-01-SH0

# Confirm VM is running
az vm get-instance-view `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01-SH0 `
  --query "instanceView.statuses[1].displayStatus" -o tsv
```

Expected output: `VM running`

---

## Step 11 — Role Assignments for p15@zippyops.in

Two roles are required:

| Role | Scope | Purpose |
|---|---|---|
| Virtual Machine User Login | Resource Group | Direct RDP into the VM using Entra ID credentials |
| Desktop Virtualization User | Application Group (POOL-FIN-01-DAG) | Connect to the published desktop via the AVD client |

```powershell
# Role 1: Direct VM RDP login
az role assignment create `
  --assignee "p15@zippyops.in" `
  --role "Virtual Machine User Login" `
  --scope "/subscriptions/b2f12c89-b8dc-496c-bd77-6c41d7fc0340/resourceGroups/dwp-lab-rg"

# Role 2: AVD published desktop access
az role assignment create `
  --assignee "p15@zippyops.in" `
  --role "Desktop Virtualization User" `
  --scope "/subscriptions/b2f12c89-b8dc-496c-bd77-6c41d7fc0340/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/POOL-FIN-01-DAG"
```

---

## Step 12 — Verify Session Host Status

Session host status is checked via the ARM REST API (the installed CLI extension version does not include a `session-host` subcommand).

```powershell
az rest `
  --method GET `
  --url "https://management.azure.com/subscriptions/b2f12c89-b8dc-496c-bd77-6c41d7fc0340/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" `
  --query "value[].{host:name, status:properties.status, lastHeartbeat:properties.lastHeartBeat, agentVersion:properties.agentVersion}" `
  -o table
```

**Target state:** `status = Available`

---

## Troubleshooting Notes Encountered During Build

### Issue 1 — Session host showed `Unavailable` after DSC extension

**Symptoms:** Agent connected to broker, heartbeat updating, but status remained Unavailable.

**Diagnosis commands run inside the VM:**

```powershell
# Check AVD agent services
az vm run-command invoke -g dwp-lab-rg -n POOL-FIN-01-SH0 `
  --command-id RunPowerShellScript `
  --scripts "Get-Service RDAgent,RDAgentBootLoader -EA SilentlyContinue | Select-Object Name,Status,StartType | Format-Table" `
  --query "value[0].message" -o tsv

# Check SxS Stack installation
az vm run-command invoke -g dwp-lab-rg -n POOL-FIN-01-SH0 `
  --command-id RunPowerShellScript `
  --scripts "Get-ChildItem 'C:\Program Files\Microsoft RDInfra\' | Select-Object Name" `
  --query "value[0].message" -o tsv

# Check Entra ID join state
az vm run-command invoke -g dwp-lab-rg -n POOL-FIN-01-SH0 `
  --command-id RunPowerShellScript `
  --scripts "dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|TenantName|DeviceId'" `
  --query "value[0].message" -o tsv
```

**Root cause:** `AzureAdJoined: NO` — the `AADLoginForWindows` extension ran before a system-assigned managed identity existed on the VM, so the Entra ID device registration could not authenticate.

**Fix:**
1. `az vm identity assign` — add system-assigned managed identity
2. Delete and reinstall `AADLoginForWindows` extension
3. Restart VM

### Issue 2 — `--public-ip-address ""` syntax error in PowerShell

**Symptom:** `argument --public-ip-address: expected one argument`

**Cause:** PowerShell strips bare `""` before passing to the Azure CLI.

**Fix:** Use single quotes wrapping double quotes: `'""'`

### Issue 3 — DSC settings JSON quoting failure when passed inline

**Symptom:** `Failed to parse string as JSON` when passing a PowerShell hashtable converted to JSON as a CLI argument.

**Fix:** Write the JSON to a temp file (`$env:TEMP\dsc-settings.json`) and pass the file path to `--settings`.

### Issue 4 — `az desktopvirtualization session-host list` not available

**Cause:** The installed CLI extension version does not include a `session-host` subcommand.

**Workaround:** Use `az rest` with the ARM REST API directly (see Step 12).

---

## Final Architecture Summary

```
FinBridge-Workspace
  └── POOL-FIN-01-DAG  (Desktop application group)
        └── POOL-FIN-01  (Pooled host pool — BreadthFirst — max 5 sessions)
              └── POOL-FIN-01-SH0  (Session host VM)
                    ├── OS:       Windows 11 24H2 multi-session (AVD-optimised)
                    ├── Size:     Standard_B2ms
                    ├── Security: Trusted Launch (Secure Boot + vTPM)
                    ├── Join:     Entra ID only (no on-premises AD)
                    ├── Identity: System-assigned managed identity
                    ├── Agent:    RDAgent 1.0.15008.300
                    └── SxS:      1.0.2605.19600
```

**p15@zippyops.in role assignments:**
- `Virtual Machine User Login` — resource group scope (direct RDP)
- `Desktop Virtualization User` — POOL-FIN-01-DAG scope (AVD client)
