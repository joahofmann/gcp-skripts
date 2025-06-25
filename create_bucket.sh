#!/bin/bash

# Script: create_gcs_bucket.sh
# Description: Creates a Google Cloud Storage bucket in the currently active GCP project.

# --- Configuration Variables ---
# Ensure the gcloud CLI is authenticated and a project is set.

BUCKET_NAME="project-has-id-123-bucket" # Name for your new Cloud Storage bucket (must be globally unique)
                                             # It's recommended to use your project ID in the bucket name for uniqueness.
BUCKET_LOCATION="US-CENTRAL1"                # Location for your storage bucket (e.g., US-CENTRAL1, EUROPE-WEST1)

# --- Pre-requisite Check ---
# Ensure gcloud CLI is installed and authenticated
if ! command -v gcloud &> /dev/null
then
    echo "Error: gcloud CLI is not installed. Please install it from https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Ensure a project is currently set in gcloud config
CURRENT_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "${CURRENT_PROJECT_ID}" ]; then
    echo "Error: No GCP project is currently set. Please run 'gcloud config set project [PROJECT_ID]' or run 'create_gcp_project.sh' first."
    exit 1
fi

echo "--- Starting GCS Bucket Creation ---"
echo "Current Project ID: ${CURRENT_PROJECT_ID}"
echo "Storage Bucket Name: ${BUCKET_NAME}"
echo "Storage Bucket Location: ${BUCKET_LOCATION}"
echo ""

# --- 1. Enable Required APIs for Cloud Storage ---
echo "Enabling Cloud Storage API (storage.googleapis.com)..."
gcloud services enable storage.googleapis.com || { echo "Failed to enable Storage API. Exiting."; exit 1; }
echo "Cloud Storage API enabled."
echo ""

# --- 2. Create a Cloud Storage Bucket ---
echo "Creating Cloud Storage bucket '${BUCKET_NAME}' in location '${BUCKET_LOCATION}' for project '${CURRENT_PROJECT_ID}'..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${CURRENT_PROJECT_ID}" --location="${BUCKET_LOCATION}" || { echo "Failed to create storage bucket. Exiting."; exit 1; }
echo "Storage bucket created: gs://${BUCKET_NAME}"
echo ""

echo "--- GCS Bucket Creation Complete! ---"
echo "Bucket 'gs://${BUCKET_NAME}' is now available in project '${CURRENT_PROJECT_ID}'."
