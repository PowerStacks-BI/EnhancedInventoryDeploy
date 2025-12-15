# Enhanced Inventory Deploy (Log Ingestion API)

This repository provides a one-click deployment template to set up the Azure resources required for **Enhanced Inventory** ingestion using the **Azure Monitor Logs Ingestion API**.

The deployment creates (or reuses) a **Log Analytics Workspace**, creates required **custom tables**, and configures the **Data Collection Endpoint (DCE)** and **Data Collection Rule (DCR)** used by the Enhanced Inventory Windows/macOS collection scripts.

---

## Deploy to Azure

Click the button below to deploy the required Azure resources:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPowerStacks-BI%2FEnhancedInventoryDeploy%2Fmain%2Finfra%2Fmain.json
/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FPowerStacks-BI%2FEnhancedInventoryDeploy%2Fmain%2Finfra%2FcreateUiDefinition.json
)

---

## What this deployment sets up

- Log Analytics Workspace (new or existing)
- Custom Tables:
  - PowerStacksDeviceInventory_CL
  - PowerStacksAppInventory_CL
  - PowerStacksDriverInventory_CL
- Data Collection Endpoint (DCE)
- Data Collection Rule (DCR)
- Outputs required by inventory scripts:
  - DCE Logs Ingestion URL
  - DCR Immutable ID

---

## Prerequisites

### Create an Entra App Registration

You must create an Entra App Registration that will be used by the inventory scripts.

You will need:
- Tenant ID
- Client ID
- Client Secret

---

## Required permissions

### Azure RBAC
The user deploying must be:
- Owner, or
- Contributor + User Access Administrator

### Entra ID
Directory read permissions are recommended for automated role assignment scenarios.

---

## Deployment scenarios

### Scenario 1: Create a new workspace
Choose **Create a new workspace** and provide a workspace name.

### Scenario 2: Use an existing workspace
Choose **Use an existing workspace** and provide the subscription ID, resource group, and workspace name.

---

## After deployment

From the deployment outputs, copy:
- DceURI
- DcrImmutableId

These values are required by the Windows and macOS inventory scripts.

---

## Configure inventory scripts

### Windows
Set:
- LogAPIMode = LogIngestionAPI
- TenantId
- ClientId
- ClientSecret
- DceURI
- DcrImmutableId

### macOS
Set:
- LogAPIMode = LogIngestionAPI
- TenantId
- ClientId
- ClientSecret
- DceURI
- DcrImmutableId

---

## Assign DCR permissions

Ensure the ingestion app has **Monitoring Metrics Publisher** on the DCR.

---

## Verify configuration

Use:
- LogIngestionAPI_CheckDCR_v2.0

---

## Repository contents

- infra/main.bicep
- infra/main.json
- infra/createUiDefinition.json

---

## Support

For support, open an issue in this repository or contact PowerStacks.
