#!/bin/bash

#!/bin/bash

# 0. Save the currently active project ID
ORIGINAL_PROJECT=$(gcloud config get-value project)
echo "Saving original project: $ORIGINAL_PROJECT"

# 1. Get Project IDs
PROJECT_IDS=$(gcloud projects list --format='value(PROJECT_ID)')
echo $PROJECT_IDS

# 2. Check if any projects were found
if [ -z "$PROJECT_IDS" ]; then
  echo "Error: No projects found.  Check your gcloud configuration and permissions."
  exit 1
fi

# 3. Select the project (e.g., the second one)
PROJECT_NUMBER=2  # Change this to the project number you want

# 4. Extract the specific project ID.  Use 'sed' to get the PROJECT_NUMBER-th line.
PROJECT_ID=$(echo "$PROJECT_IDS" | sed "${PROJECT_NUMBER}q;d")

# 5. Check if the project ID was successfully extracted
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project number $PROJECT_NUMBER is out of range. Only $(wc -l <<< "$PROJECT_IDS") projects found."
  exit 1
fi

# 6. Set the active project
gcloud config set project "$PROJECT_ID"

# 7. Verify the project change
echo "Switched to project: $(gcloud config get-value project)"

# 8. Set the active project orginal
gcloud config set project "$ORIGINAL_PROJECT"