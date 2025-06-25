#!/bin/bash

# Set the project ID
PROJECT_ID="project-to-test-123"  # Replace with the ID of the project you want to delete

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null
then
    echo "gcloud is not installed. Please install the Google Cloud SDK."
    exit 1
fi

# Verify that the project ID is set
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID is not set.  Please set the PROJECT_ID variable."
  exit 1
fi

# Prompt for confirmation
read -p "Are you sure you want to delete project '$PROJECT_ID'? This action is irreversible! (y/n): " confirm

# Check the response
if [[ "$confirm" != "y" ]]; then
  echo "Deletion cancelled."
  exit 0
fi

# Delete the project
echo "Deleting project $PROJECT_ID..."
gcloud projects delete "$PROJECT_ID"

if [ $? -ne 0 ]; then
  echo "Error deleting project."
  exit 1
fi

echo "Project $PROJECT_ID has been marked for deletion. It will be fully deleted after 30 days."
echo "Billing has been stopped and resources will be inaccessible immediately."
