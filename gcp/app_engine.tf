resource "google_project" "my_project" {
  name = "appeng-flex"
  project_id = "appeng-flex"
  org_id = "123456789"
  billing_account = "000000-0000000-0000000-000000"
}

resource "google_app_engine_application" "app" {
  project     = google_project.my_project.project_id
  location_id = "us-central"
}

resource "google_project_service" "service" {
  project = google_project.my_project.project_id
  service = "appengineflex.googleapis.com"

  disable_dependent_services = false
}

resource "google_service_account" "custom_service_account" {
  project      = google_project_service.service.project
  account_id   = "my-account"
  display_name = "Custom Service Account"
}

resource "google_project_iam_member" "gae_api" {
  project = google_project_service.service.project
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.custom_service_account.email}"
}

resource "google_project_iam_member" "logs_writer" {
  project = google_project_service.service.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.custom_service_account.email}"
}

resource "google_project_iam_member" "storage_viewer" {
  project = google_project_service.service.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.custom_service_account.email}"
}

resource "google_app_engine_flexible_app_version" "myapp_v1" {
  version_id = "v1"
  project    = google_project_iam_member.gae_api.project
  service    = "default"
  runtime    = "nodejs"

  entrypoint {
    shell = "node ./app.js"
  }

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/${google_storage_bucket.bucket.name}/${google_storage_bucket_object.object.name}"
    }
  }

  liveness_check {
    path = "/"
  }

  readiness_check {
    path = "/"
  }

  env_variables = {
    port = "8080"
  }

  handlers {
    url_regex        = ".*\\/my-path\\/*"
    security_level   = "SECURE_DEFAULT"
    login            = "LOGIN_REQUIRED"
    auth_fail_action = "AUTH_FAIL_ACTION_REDIRECT"

    static_files {
      path = "my-other-path"
      upload_path_regex = ".*\\/my-path\\/*"
    }
  }

  automatic_scaling {
    cool_down_period = "120s"
    cpu_utilization {
      target_utilization = 0.5
    }
  }

  api_config {
    security_level = "SECURE_DEFAULT"
  }

  noop_on_destroy = true
  service_account = google_service_account.custom_service_account.email
}