#!/bin/bash

# Script: create_sa_and_key.sh
# Description: Creates a service account, grants it the Storage Admin role on the current project,
#              and downloads its JSON key file.

# --- Configuration Variables ---
# Ensure the gcloud CLI is authenticated and a project is set.

SERVICE_ACCOUNT_NAME="storage-admin-sa"    # Name for the new service account
SERVICE_ACCOUNT_DISPLAY_NAME="Storage Admin Service Account" # Display name for the service account
KEY_FILE_NAME="${SERVICE_ACCOUNT_NAME}-key.json" # Name for the downloaded JSON key file

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

echo "--- Starting Service Account and Key Creation ---"
echo "Current Project ID: ${CURRENT_PROJECT_ID}"
echo "Service Account Name: ${SERVICE_ACCOUNT_NAME}"
echo "JSON Key File: ${KEY_FILE_NAME}"
echo ""

# --- 1. Enable Cloud Resource Manager API (if not already enabled) ---
# This API is needed for managing IAM policies.
echo "Enabling Cloud Resource Manager API (cloudresourcemanager.googleapis.com)..."
gcloud services enable cloudresourcemanager.googleapis.com || { echo "Failed to enable Resource Manager API. Exiting."; exit 1; }
echo "Cloud Resource Manager API enabled."
echo ""

# --- 2. Create a Service Account ---
echo "Creating service account '${SERVICE_ACCOUNT_NAME}' in project '${CURRENT_PROJECT_ID}'..."
gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
  --display-name="${SERVICE_ACCOUNT_DISPLAY_NAME}" \
  --project="${CURRENT_PROJECT_ID}" || { echo "Failed to create service account. Exiting."; exit 1; }
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${CURRENT_PROJECT_ID}.iam.gserviceaccount.com"
echo "Service account created: ${SERVICE_ACCOUNT_EMAIL}"
echo ""

# --- 3. Grant Storage Admin Role to the Service Account on the Project ---
echo "Granting 'Storage Admin' role to service account '${SERVICE_ACCOUNT_EMAIL}' on project '${CURRENT_PROJECT_ID}'..."
gcloud projects add-iam-policy-binding "${CURRENT_PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.admin" || { echo "Failed to grant Storage Admin role. Exiting."; exit 1; }
echo "Storage Admin role granted to service account."
echo ""

# --- 4. Create and Download JSON Key File for the Service Account ---
echo "Creating and downloading JSON key file for service account '${SERVICE_ACCOUNT_EMAIL}' to '${KEY_FILE_NAME}'..."
gcloud iam service-accounts keys create "${KEY_FILE_NAME}" \
  --iam-account="${SERVICE_ACCOUNT_EMAIL}" \
  --project="${CURRENT_PROJECT_ID}" || { echo "Failed to create and download key file. Exiting."; exit 1; }
echo "JSON key file downloaded: ${KEY_FILE_NAME}"
echo ""

echo "--- Service Account and Key Creation Complete! ---"
echo "Service account '${SERVICE_ACCOUNT_EMAIL}' is ready."
echo "The JSON key file is saved as '${KEY_FILE_NAME}' in your current directory."
echo ""
echo "IMPORTANT: Keep your service account key file secure! Treat it like a password."
echo "Do not commit it to version control."
