# Enhanced Inventory Deploy (Log Ingestion API)

This repository provides a **one-click Azure deployment** that sets up the required Azure resources for **PowerStacks Enhanced Inventory** using the **Azure Monitor Logs Ingestion API**.

The deployment creates (or reuses) a **Log Analytics Workspace**, configures required **custom tables**, and sets up the **Data Collection Endpoint (DCE)** and **Data Collection Rule (DCR)** used by the Enhanced Inventory Windows and macOS inventory scripts.

---

## 🚀 Deploy to Azure

Click the button below to deploy the required Azure resources:

<p>
  <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPowerStacks-BI%2FEnhancedInventoryDeploy%2Fmain%2Finfra%2Fmain.json">
    <img src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure">
  </a>
</p>

> ⚠️ **Important**  
> Before clicking **Deploy to Azure**, review the **Prerequisites** section below.  
> One required value must be obtained from the Azure portal.

---

## What this deployment sets up

- Log Analytics Workspace (new or existing)
- Custom Log Analytics tables:
  - `PowerStacksDeviceInventory_CL`
  - `PowerStacksAppInventory_CL`
  - `PowerStacksDriverInventory_CL`
- Data Collection Endpoint (DCE)
- Data Collection Rule (DCR)
- Outputs required by the inventory scripts:
  - **DCE Logs Ingestion URI**
  - **DCR Immutable ID**

---

## Prerequisites (Required Before Deployment)

### 1. Create an Entra ID application

You must create an **Entra ID App Registration** that will be used by the Enhanced Inventory scripts to authenticate to Azure.

From the app registration, record:
- **Tenant ID**
- **Application (Client) ID**
- **Client Secret**

These values are used **by the inventory scripts**, not by the Azure deployment itself.

---

### 2. Copy the *Enterprise Application Object ID* (Required for RBAC)

The Azure deployment needs the **Object ID of the Enterprise Application (service principal)** so it can automatically assign permissions to the Data Collection Rule.

> ⚠️ This is **NOT** the Application (Client) ID.

#### How to find it in the Azure portal

1. Go to **https://entra.microsoft.com**
2. Navigate to **Applications → Enterprise applications**
3. Locate the application you created for Enhanced Inventory
   - You may search by **name** or filter by **Application ID**
4. Open the application and copy the **Object ID** from the Overview page

This value will be entered in the deployment wizard as:

**Enterprise App Object Id**

---

## Required permissions

### Azure permissions
The user deploying the template must be:
- **Owner**, or
- **Contributor + User Access Administrator**

### Entra ID permissions
The user creating the app registration must be able to:
- Create app registrations
- View Enterprise Applications

---

## Deployment options

### Option 1: Create a new Log Analytics workspace
Choose **Create a new workspace** and provide a workspace name.

### Option 2: Use an existing Log Analytics workspace
Choose **Use an existing workspace** and provide:
- Subscription ID
- Resource group name
- Workspace name

> This is commonly used when deploying alongside **Windows Update for Business Reports** or other shared workspaces.

---

## Deployment wizard input summary

During deployment you will be prompted for:

- Workspace selection (new or existing)
- Workspace details (if using existing)
- **Enterprise App Object Id** (recommended)

> If the **Enterprise App Object Id** is provided:
> - The deployment automatically assigns the required **Monitoring Metrics Publisher** role to the DCR  
> - No manual RBAC steps are required after deployment

If the field is left blank, permissions must be assigned manually.

---

## After deployment

From the **Deployment Outputs**, copy the following values:

- **DceURI**
- **DcrImmutableId**

These values are required by the Windows and macOS inventory scripts.

---

## Configure inventory scripts

### Windows
Configure the following settings in the Windows inventory script:

- `LogAPIMode = LogIngestionAPI`
- `TenantId`
- `ClientId`
- `ClientSecret`
- `DceURI`
- `DcrImmutableId`

### macOS
Configure the same values in the macOS inventory script:

- `LogAPIMode = LogIngestionAPI`
- `TenantId`
- `ClientId`
- `ClientSecret`
- `DceURI`
- `DcrImmutableId`

---

## Verify the deployment (Optional)

Use the validation script:

- `LogIngestionAPI_CheckDCR_v2.0`

This script retrieves and displays the full DCR configuration and is useful for troubleshooting ingestion issues.

---

## Repository contents

- `infra/main.bicep` – Source Bicep template
- `infra/main.json` – Compiled ARM template used by the portal
- `infra/createUiDefinition.json` – Custom UI definition (used for managed app scenarios)

---

## Support

For questions or issues:
- Open an issue in this repository
- Or contact **PowerStacks Support**
