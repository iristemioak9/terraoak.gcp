resource "google_pubsub_topic" "pub-sub" {
  name = "example-topic"
  # oak9: google_pubsub_topic.kms_key_name is not configured

  labels = {
    foo = "bar"
  }

  message_retention_duration = "86600s"
}

resource "google_pubsub_subscription" "pub-sub" {
  name  = "example-subscription"
  topic = google_pubsub_topic.pub-sub.name

  ack_deadline_seconds = 20

  push_config {
    push_endpoint = "https://example.com/push"

    attributes = {
      x-goog-version = "v1"
    }
  }
}