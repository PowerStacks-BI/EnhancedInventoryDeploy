# Optional: secretless ingestion with a managed identity

Enhanced Inventory supports two ways for endpoints to authenticate when they upload
data to your Log Analytics workspace. Both are fully supported. You choose the one
that fits your security posture and your Azure footprint.

This page explains the optional secretless path so you can decide whether to use it.
If you do nothing, you stay on the default path.

## The two options

| | Default: client secret | Optional: managed identity |
|---|---|---|
| How the endpoint authenticates | An Entra app registration client secret, configured in the inventory script | A low-privilege key that calls a small Azure Function in your subscription; the Function's managed identity does the write |
| Secret on the endpoint | Yes, the client secret is in the script | No client secret anywhere |
| Extra infrastructure in your tenant | None | One Azure Function App plus a storage account, which you deploy and maintain |
| App registrations | The inventory-upload app registration | None for upload (the managed identity replaces it) |
| Best for | Most customers; simplest to run | Customers whose security review objects to a write-capable secret distributed to every device |

Neither option is more or less scalable. In both cases the inventory data is written
to the same Data Collection Rule, which is where the real ingestion limits live.

## What the optional path actually does

With the managed-identity option, the endpoint no longer holds a client secret. It
posts its inventory to a small Azure Function that runs in your own subscription,
authenticating with a function key. The Function holds a system-assigned managed
identity that has permission to write to your Data Collection Rule, and it forwards
the data on the endpoint's behalf. The managed identity never leaves Azure.

The key that the endpoint does hold is low privilege. It can do exactly one thing:
call that Function. It is not an Entra identity, so it cannot be used against Microsoft
Graph, Azure Resource Manager, or anything else, and you can rotate it at any time
without touching an app registration.

## What it costs

The Function runs on the Azure Consumption plan, which includes 1,000,000 free
executions per month. Each enabled inventory type is its own call, so a daily run that
collects all three types is three executions. That keeps a daily schedule free up to
roughly 11,000 devices, and above that the charge is still only cents per month. There
is also a small storage account, a few cents a month. No new Microsoft license is
required, and managed identities do not need Entra ID P1 or P2.

## Honest tradeoffs

Use this to decide, not to be sold:

- You gain: no client secret on any endpoint, and one fewer app registration. This is
  the cleaner answer when a security team asks how endpoints authenticate.
- You take on: a small Azure Function and storage account in your subscription that you
  deploy and keep current, plus a negligible Azure cost for very large fleets. The
  default path has none of that.
- This does not make ingestion un-spoofable. An attacker who already has SYSTEM on a
  device can still write inventory rows either way. The managed-identity path narrows
  what a stolen credential can do; it does not eliminate the endpoint as a trust
  boundary.

## How to enable it

The standard deployment template does not create the Function. It is an opt-in you
deploy separately, so customers who do not want it are never given it.

1. Deploy the ingestion Function into your subscription using the provided deploy
   script. It creates the Function, its storage account, the managed identity, and the
   role assignment on your existing Data Collection Rule, then prints a Function URL.
2. In the inventory script, set the `FunctionUrl` value to that URL, and leave the
   `ClientId`, `TenantId`, and `ClientSecret` fields as their placeholders. Setting
   `FunctionUrl` switches the script to the secretless path automatically.
3. Run inventory as usual. Each enabled inventory type is sent to the Function as its
   own call, the same as the default path.

To go back to the default path, clear `FunctionUrl` and restore the client secret
fields. Both paths remain available at all times.
