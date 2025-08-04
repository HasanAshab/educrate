provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "static_site_rg" {
  name     = "static-website-rg"
  location = "East US"
}

resource "azurerm_storage_account" "static_site_sa" {
  name                     = "educrate"
  resource_group_name      = azurerm_resource_group.static_site_rg.name
  location                 = azurerm_resource_group.static_site_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.static_site_sa.id

  index_document     = "index.html"
  error_404_document = "404.html"
}

resource "azurerm_storage_blob" "static_site_files" {
  for_each = fileset("${path.module}/site", "**/*")

  name                   = each.value
  storage_account_name   = azurerm_storage_account.static_site_sa.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/site/${each.value}"
  content_type           = lookup({
    html = "text/html"
    mp4  = "video/mp4"
  }, lower(regex(".*\\.([^.]+)$", each.value)[0]), "application/octet-stream")
  depends_on = [
    azurerm_storage_account_static_website.static_site
  ]
}


output "storage_static_url" {
  value = azurerm_storage_account.static_site_sa.primary_web_endpoint
}
