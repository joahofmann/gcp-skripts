#!/bin/bash

# Script: create_gcp_project.sh
# Description: Creates a new Google Cloud Platform project and links it to a billing account.

# --- Configuration Variables ---
# IMPORTANT: Replace these values with your desired settings.
# Ensure your gcloud CLI is authenticated and has permissions to create projects
# and manage IAM policies at the organization/billing account level.

NEW_PROJECT_ID="project-has-id-123" # Choose a unique ID for your new project (must be lowercase, numbers, hyphens)
                                         # Example: "my-awesome-app-123"
NEW_PROJECT_NAME="test project" # A display name for your new project
BILLING_ACCOUNT_ID="012C4F-100447-79C5BA" # IMPORTANT: Replace with your actual GCP Billing Account ID
                                            # You can find this in the GCP Console under 'Billing' -> 'Billing account management'
                                            # Example: "012345-ABCDEF-7890GH"

# --- Pre-requisite Check ---
# Ensure gcloud CLI is installed and authenticated
if ! command -v gcloud &> /dev/null
then
    echo "Error: gcloud CLI is not installed. Please install it from https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Ensure user is authenticated
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" &> /dev/null
then
    echo "Error: You are not authenticated with gcloud. Please run 'gcloud auth login'."
    exit 1
fi

echo "--- Starting GCP Project Creation ---"
echo "New Project ID: ${NEW_PROJECT_ID}"
echo "New Project Name: ${NEW_PROJECT_NAME}"
echo "Billing Account ID: ${BILLING_ACCOUNT_ID}"
echo ""

# --- 1. Create the New GCP Project ---
echo "Creating new GCP project '${NEW_PROJECT_NAME}' (ID: ${NEW_PROJECT_ID})..."
gcloud projects create "${NEW_PROJECT_ID}" --name="${NEW_PROJECT_NAME}" || { echo "Failed to create project. Exiting."; exit 1; }
echo "Project created successfully."
echo ""

# --- 2. Link Project to Billing Account ---
echo "Linking project '${NEW_PROJECT_ID}' to billing account '${BILLING_ACCOUNT_ID}'..."
gcloud billing projects link "${NEW_PROJECT_ID}" --billing-account="${BILLING_ACCOUNT_ID}" || { echo "Failed to link project to billing account. Exiting."; exit 1; }
echo "Project linked to billing account."
echo ""

# --- 3. Set the newly created project as the current project ---
# This ensures all subsequent commands operate within the new project.
echo "Setting current gcloud project to ${NEW_PROJECT_ID}..."
gcloud config set project "${NEW_PROJECT_ID}" || { echo "Failed to set current project. Exiting."; exit 1; }
echo "Current project set to: $(gcloud config get-value project)"
echo ""

echo "--- GCP Project Creation Complete! ---"
echo "Project '${NEW_PROJECT_ID}' is ready for further setup."
