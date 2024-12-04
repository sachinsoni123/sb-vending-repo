resource "google_monitoring_notification_channel" "email" {
  for_each = { for idx, email in toset(var.members) : idx => email }
  display_name = "Budget Notification Email - ${each.value}"
  type         = "email"
  labels = {
    email_address = each.value
  }
  project = var.project_name
}

resource "google_billing_budget" "budget" {
  depends_on = [
    google_monitoring_notification_channel.email
   ]
  billing_account = var.billing_id
  display_name    = "Billing budget/${var.project_name}"

  budget_filter {
    projects = ["projects/${var.project_no}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.approved_budget
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.9
  }

  threshold_rules {
    threshold_percent = 1
  }

    all_updates_rule {
    monitoring_notification_channels = [
    for idx, value in google_monitoring_notification_channel.email : value.id
    ]
    disable_default_iam_recipients = true
  }



}
