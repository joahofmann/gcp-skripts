#!/bin/bash

# --- Configuration for Verbose Output ---
# Set to 'true' for verbose output (default), 'false' to suppress most echo messages.
export VERBOSE=true 

# Function to echo messages only if VERBOSE is true
log_echo() {
  if [ "$VERBOSE" = "true" ]; then
    echo "$@"
  fi
}

# 0. Save the currently active project ID
ORIGINAL_PROJECT=$(gcloud config get-value project)
log_echo "Saving original project: $ORIGINAL_PROJECT"

# 1. Get Project IDs and store them in a bash array
# We use 'readarray -t' to read each line into an array element
log_echo "Fetching project IDs..."
readarray -t PROJECT_IDS_ARRAY <<< "$(gcloud projects list --format='value(PROJECT_ID)')" # Corrected closing parenthesis

# 2. Check if any projects were found
if [ ${#PROJECT_IDS_ARRAY[@]} -eq 0 ]; then
  echo "Error: No projects found. Check your gcloud configuration and permissions." # Error messages should always print
  exit 1
fi

# 3. Display available projects for selection
log_echo "Available Projects:"
for i in "${!PROJECT_IDS_ARRAY[@]}"; do
  log_echo "  [$i] ${PROJECT_IDS_ARRAY[$i]}"
done

# 4. Prompt the user to select a project by number
# User prompts should generally not be suppressed by a verbose flag, as they require interaction.
read -p "Enter the number of the project you want to select (e.g., 0 for the first project): " PROJECT_NUMBER_INDEX

# 5. Validate the input and extract the specific project ID
if ! [[ "$PROJECT_NUMBER_INDEX" =~ ^[0-9]+$ ]] || [ "$PROJECT_NUMBER_INDEX" -ge "${#PROJECT_IDS_ARRAY[@]}" ]; then
  echo "Error: Invalid project number. Please enter a number between 0 and $(( ${#PROJECT_IDS_ARRAY[@]} - 1 ))." # Error messages should always print
  exit 1
fi

PROJECT_ID_TO_SET="${PROJECT_IDS_ARRAY[$PROJECT_NUMBER_INDEX]}"

# 6. Set the active project
log_echo "Attempting to switch to project: $PROJECT_ID_TO_SET"
gcloud config set project "$PROJECT_ID_TO_SET"

# 7. Verify the project change
CURRENT_PROJECT=$(gcloud config get-value project)
log_echo "Switched to project: $CURRENT_PROJECT"

# --- NEW ADDITION: List all Cloud SQL databases in the selected project ---
log_echo "" # This can be controlled
log_echo "Listing all Cloud SQL instances and their databases in project: $CURRENT_PROJECT"

# Get a list of all Cloud SQL instances in the current project
SQL_INSTANCES=$(gcloud sql instances list --project="$CURRENT_PROJECT" --format="value(NAME)")

if [ -z "$SQL_INSTANCES" ]; then
    log_echo "No Cloud SQL instances found in this project."
else
    for INSTANCE_NAME in $SQL_INSTANCES; do
        log_echo "  Instance: $INSTANCE_NAME"
        # List databases for each instance
        # gcloud output itself is not controlled by our script's verbose flag,
        # but the echo preceding it is.
        gcloud sql databases list --instance="$INSTANCE_NAME" --project="$CURRENT_PROJECT" --format="table(NAME,CHARSET,COLLATION)"
    done
fi
log_echo "Finished listing databases."
log_echo "" # This can be controlled
# --- END NEW ADDITION ---

# 8. Set the active project back to the original one
log_echo "Switching back to original project: $ORIGINAL_PROJECT"
gcloud config set project "$ORIGINAL_PROJECT"

# 9. Verify the project change back
log_echo "Reverted to project: $(gcloud config get-value project)"