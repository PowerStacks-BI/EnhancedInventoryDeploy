# Intentionally minimal. The default profile tries to run Connect-AzAccount when a
# managed identity is present, which would force the Az modules to load. This Function
# gets its token from the App Service identity REST endpoint instead, so there is
# nothing to do here.
