terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}


provider "google" {
  project = "sara-sandbox-interns"
  region  = "europe-west1"
}

resource "google_project_service" "firestore_api" {
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "storage_api" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild_api" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "clouddeploy_api" {
  service            = "clouddeploy.googleapis.com"
  disable_on_destroy = false
}

resource "google_firestore_database" "database" {
  name        = "(default)"
  location_id = "europe-west1"
  project     = "sara-sandbox-interns"
  type        = "FIRESTORE_NATIVE"
}

resource "google_storage_bucket" "covers" {
  project                     = "sara-sandbox-interns"
  name                        = "sara-sandbox-interns-covers"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.covers.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_service_account" "cloudrun_sa" {
  project      = "sara-sandbox-interns"
  account_id   = "bookshelf-run-sa"
  display_name = "Bookshelf Cloud Run Service Account"

}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name     = "bookshelf-app" # Tačno ime servisa koje piše u tvom service.yaml
  location = "europe-west1"
  project  = "sara-sandbox-interns"
  role     = "roles/run.invoker" # Rola koja dozvoljava posetu sajtu preko URL-a
  member   = "allUsers"          # Označava ceo internet
}

resource "google_artifact_registry_repository" "docker_repo" {
  project       = "sara-sandbox-interns"
  location      = "europe-west1"
  repository_id = "bookshelf-repo"
  description   = "Docker repozitorijum za Bookshelf aplikaciju"
  format        = "DOCKER"

}

# Dajemo aplikaciji pristup da čita i piše po bazi
resource "google_project_iam_member" "firestore_access" {
  project = "sara-sandbox-interns"
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Dajemo aplikaciji pristup da snima slike u bucket
resource "google_storage_bucket_iam_member" "storage_writer" {
  bucket = google_storage_bucket.covers.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}


resource "google_cloudbuild_trigger" "github_trigger" {
  name        = "bookshelf-ci-trigger"
  description = "Trigger za automatski build na svaki push u main granu"
  project     = "sara-sandbox-interns"
  location    = "global" # Može biti i "global", zavisi gde želiš da živi trigger

  # Kažemo mu šta aktivira trigger (Event)
  github {
    owner = "aleksandarsrajer-devoteam" # Tvoje GitHub ime / organizacija
    name  = "Developer-Bookshelf-1"      # Tačan naziv repozitorijuma

    # Slušamo push događaje na main grani
    push {
      branch = "^main$"
    }
  }
  # Kažemo mu koji fajl da čita kada se aktivira
  filename = "cloudbuild.yaml"

  depends_on = [google_project_service.cloudbuild_api]
}

resource "google_clouddeploy_target" "prod_target" {
  name     = "bookshelf-prod"
  location = "europe-west1"
  project  = "sara-sandbox-interns"

  # Kažemo mu da je ovo Cloud Run odredište
  run {
    location = "projects/sara-sandbox-interns/locations/europe-west1"
  }

  depends_on = [google_project_service.clouddeploy_api]
}

resource "google_clouddeploy_delivery_pipeline" "pipeline" {
  name     = "bookshelf-pipeline"
  location = "europe-west1"
  project  = "sara-sandbox-interns"

  # Definišemo faze kroz koje prolazi deploy (za sada samo prod)
  serial_pipeline {
    stages {
      target_id = google_clouddeploy_target.prod_target.name
    }
  }

  depends_on = [google_project_service.clouddeploy_api]
}

data "google_project" "project" {
  project_id = "sara-sandbox-interns"
}

resource "google_project_iam_member" "cb_deploy_releaser" {
  project = "sara-sandbox-interns"
  role    = "roles/clouddeploy.releaser"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cb_iam_user" {
  project = "sara-sandbox-interns"
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}