# Enhanced Inventory: secretless option + migration campaign

Goal: move all customers off the legacy Azure Monitor Data Collector API (shared
key) to the Logs Ingestion API (DCE + DCR). The client secret stays the DEFAULT
ingestion method; the Function + managed identity forwarder is the OPT-IN
alternate (decision with Julien, 2026-06-11: secret stays default, MI is listed
as an alternative, not the default).

## Done

- Published the secretless MI path: EnhancedInventoryDeploy (Deploy-IngestionFunction.ps1,
  ingestion-function/, docs/secretless-ingestion-option.md). Internal
  SECRETLESS-VALIDATION.md kept OUT of the repo.
- Windows collector (Windows-Custom-Inventory/Intune_Windows_Inventory.ps1): added
  the $FunctionUrl opt-in branch + Invoke-LogSubmission helper. Default unchanged.

## Remaining

1. Prod validation (John): validate the secretless Function scenario end to end,
   then release any held commits.
2. MI section is Windows-only. The Mac collector (Mac-Custom-Inventory) has no
   FunctionUrl branch. Either note this clearly in the docs or add Mac support.
3. custom-inventory.md (powerstacks-docs): fix the deploy-button org from
   PowerStacks-BI to powerstacks-corp.
4. custom-inventory.md: rewrite for the secretless flow (currently documents the
   secret flow only).
5. Second-DCR scale-out helper template (for spreading load across multiple DCRs).
6. Cleanup pass for the campaign: remove em-dashes and emoji from the inventory
   docs and the EnhancedInventoryDeploy README (public-facing, avoid AI signals).

## Related (do not lose)

- Restore the MSEndpointMgr MIT attribution on the Windows/Mac Enhanced Inventory
  collectors. They are an MIT derivative of MSEndpointMgr/IntuneEnhancedInventory
  (Skanke/Zeng/Daly); the current script dropped the required notice. MIT allows
  our proprietary relicensing of the derivative as long as the notice stays.
