resource "google_os_config_patch_deployment" "default" {
  patch_deployment_id = "weekly-default"
  description         = "Default OS Patch Policy"

  instance_filter {
    group_labels {
      labels = {
        "os_patch" = "yes"
      }
    }
  }

  patch_config {
    reboot_config = "ALWAYS"
    apt {
      type = "DIST"
    }
    yum {
      minimal = true
    }
  }

  recurring_schedule {
    time_zone {
      id = "America/Toronto"
    }

    weekly {
      day_of_week = "FRIDAY"
    }

    time_of_day {
      hours   = 17
      minutes = 00
    }
  }

  rollout {
    mode = "ZONE_BY_ZONE"
    disruption_budget {
      fixed = 1
    }
  }
}
