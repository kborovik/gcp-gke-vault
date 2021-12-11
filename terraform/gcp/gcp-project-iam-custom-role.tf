/*

Custom IAM Role to allow scheduled VM start/stop

*/
resource "google_project_iam_custom_role" "instance_schedule" {
  project     = var.project_id
  role_id     = "custom.compute.instancesSchedule"
  title       = "Custom Instances Schedule"
  description = "Custom Instances Schedule"

  permissions = [
    "compute.instances.start",
    "compute.instances.stop",
  ]
}
