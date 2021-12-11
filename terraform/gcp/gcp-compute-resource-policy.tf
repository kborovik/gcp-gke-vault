resource "google_compute_resource_policy" "snapshot_daily" {
  name        = "snapshot-daily"
  region      = var.region
  description = "Daily keep 7 days"

  snapshot_schedule_policy {
    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "APPLY_RETENTION_POLICY"
    }

    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }

    snapshot_properties {
      storage_locations = [var.region]
      guest_flush       = false
    }
  }
}


resource "google_compute_resource_policy" "instance_start_stop" {
  name        = "instance-start-stop"
  region      = var.region
  description = "Daily instance stop"

  instance_schedule_policy {
    time_zone = "America/New_York"
    vm_stop_schedule {
      schedule = "0 18 * * *"
    }
    vm_start_schedule {
      schedule = "30 16 * * fri"
    }
  }
}
