provider "google" {
  credentials  = ""
  project      = "$GCP_PROJECT_NAME"
  region       = "europe-west2"
}

resource "google_container_cluster" "cluster" {
  name = "frontend-cluster"
  zone = "europe-west2-a"
  additional_zones = ["europe-west2-b", "europe-west2-c"]
  monitoring_service = "monitoring.googleapis.com"

  master_auth {
    username = "admin"
    password = "N33GhAc82PPdbdtJ"
  }

  # NB: This is nodes per zone above
  initial_node_count = 1
  node_version = "1.7.5"
  node_config {
	  machine_type = "n1-standard-2"
	  disk_size_gb = "40"

    # NOTE: devstorage.read_write gives more permissions than this really needs
    oauth_scopes = [
  	  "https://www.googleapis.com/auth/compute",
  	  "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}
