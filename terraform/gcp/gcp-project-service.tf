/*

Enable project services

*/
resource "google_project_service" "service" {
  count              = length(local.project_services)
  service            = local.project_services[count.index]
  project            = var.project_id
  disable_on_destroy = false
}
