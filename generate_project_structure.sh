#!/bin/bash

# --- Configuration ---
PROJECT_ROOT="flask-app-prod"

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Starting Flask Project Structure Generation ---${NC}"

# --- 1. Create Root Directory and Subdirectories ---
echo -e "${YELLOW}Creating project directories...${NC}"
mkdir -p "$PROJECT_ROOT"/{.gcloud,static/{css,js,images},templates}

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Could not create directories. Exiting.${NC}"
    exit 1
fi

cd "$PROJECT_ROOT" || { echo -e "${RED}Error: Could not change to project directory. Exiting.${NC}"; exit 1; }

echo -e "${GREEN}Project root created at: $(pwd)${NC}"

# --- 2. Generate Core Flask Application Files ---
echo -e "${YELLOW}Generating app.py...${NC}"
cat << 'EOF' > app.py
from flask import Flask
import os
import psycopg2
from psycopg2 import OperationalError

app = Flask(__name__)

@app.route('/')
def hello_world():
    return '<h1>Hello, World from Flask!</h1><p>Running with Gunicorn and Nginx on Google Cloud.</p>'

@app.route('/db_test')
def db_test():
    db_host = os.environ.get('DB_HOST')
    db_name = os.environ.get('DB_NAME')
    db_user = os.environ.get('DB_USER')
    db_password = os.environ.get('DB_PASSWORD')

    if not all([db_host, db_name, db_user, db_password]):
        return "<h1>Database Test Failed</h1><p>Database environment variables (DB_HOST, DB_NAME, DB_USER, DB_PASSWORD) are not set.</p>"

    conn = None
    try:
        conn = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password
        )
        cur = conn.cursor()
        cur.execute('SELECT version();')
        db_version = cur.fetchone()[0]
        cur.close()
        return f"<h1>Database Test Succeeded!</h1><p>Connected to PostgreSQL version: {db_version}</p>"
    except OperationalError as e:
        return f"<h1>Database Test Failed</h1><p>Could not connect to database: {e}</p>"
    except Exception as e:
        return f"<h1>An unexpected error occurred:</h1><p>{e}</p>"
    finally:
        if conn:
            conn.close()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(debug=True, host='0.0.0.0', port=port)
EOF

echo -e "${YELLOW}Generating requirements.txt...${NC}"
cat << EOF > requirements.txt
Flask
gunicorn
psycopg2-binary
EOF

echo -e "${YELLOW}Generating gunicorn_config.py...${NC}"
cat << EOF > gunicorn_config.py
workers = 4
bind = "0.0.0.0:8080"
timeout = 120
EOF

# --- 3. Generate Dummy Static and Template Files ---
echo -e "${YELLOW}Generating dummy static files...${NC}"
cat << EOF > static/css/style.css
/* static/css/style.css */
body {
    font-family: 'Inter', sans-serif;
    margin: 20px;
    background-color: #f0f2f5;
    color: #333;
}
h1 {
    color: #0056b3;
}
p {
    line-height: 1.6;
}
EOF

cat << EOF > static/js/script.js
// static/js/script.js
console.log("Hello from your Flask app's static JavaScript!");
document.addEventListener('DOMContentLoaded', () => {
    // Add any interactive JavaScript here
});
EOF

# Create an empty dummy image file
touch static/images/logo.png
echo "Placeholder for logo.png created."


echo -e "${YELLOW}Generating dummy template files...${NC}"
cat << EOF > templates/base.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}My Flask App{% endblock %}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <header>
        <nav>
            <a href="/">Home</a> | <a href="/db_test">DB Test</a>
        </nav>
    </header>
    <main>
        {% block content %}{% endblock %}
    </main>
    <footer>
        <p>&copy; 2024 My Flask App</p>
    </footer>
    <script src="{{ url_for('static', filename='js/script.js') }}"></script>
</body>
</html>
EOF

cat << EOF > templates/index.html
{% extends "base.html" %}
{% block title %}Home - My Flask App{% endblock %}
{% block content %}
    <h1>Welcome!</h1>
    <p>This is the home page of your Flask application.</p>
    <p>Check the database connection: <a href="/db_test">Test DB</a></p>
{% endblock %}
EOF

cat << EOF > templates/db_test.html
{% extends "base.html" %}
{% block title %}DB Test - My Flask App{% endblock %}
{% block content %}
    <h1>Database Connection Test</h1>
    <p>This page will attempt to connect to the PostgreSQL database.</p>
    {# The actual DB test will happen in the /db_test route's Python code #}
{% endblock %}
EOF

# --- 4. Generate .gcloud Deployment Scripts ---
echo -e "${YELLOW}Generating .gcloud deployment scripts...${NC}"

# deploy_vm.sh
cat << 'EOF' > .gcloud/deploy_vm.sh
#!/bin/bash

# --- IMPORTANT: REPLACE PLACEHOLDERS BELOW ---
# Replace with your actual Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT="[YOUR_PROJECT_ID]"
# Choose a zone for your VM (e.g., europe-west6-b, us-central1-a)
export GOOGLE_CLOUD_ZONE="[YOUR_ZONE]"
# Choose a region for your Cloud SQL instance (e.g., europe-west6, us-central1)
export GOOGLE_CLOUD_REGION="[YOUR_REGION]"
# Choose strong passwords for your databases
export DB_ROOT_PASSWORD="[YOUR_DB_ROOT_PASSWORD]" # Cloud SQL root password
export FLASK_DB_PASSWORD="[YOUR_FLASK_DB_PASSWORD]" # Password for the Flask app's database user
# --- END IMPORTANT ---

gcloud config set project $GOOGLE_CLOUD_PROJECT
gcloud config set compute/zone $GOOGLE_CLOUD_ZONE
gcloud config set sql/region $GOOGLE_CLOUD_REGION

echo "Configured project: $GOOGLE_CLOUD_PROJECT, zone: $GOOGLE_CLOUD_ZONE, region: $GOOGLE_CLOUD_REGION"

echo "Creating Compute Engine VM instance..."
gcloud compute instances create my-flask-vm \
    --project=$GOOGLE_CLOUD_PROJECT \
    --zone=$GOOGLE_CLOUD_ZONE \
    --machine-type=e2-micro \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server,https-server \
    --boot-disk-size=20GB \
    --metadata=startup-script="#! /bin/bash
    echo 'VM initial setup script running...'
    sudo apt update
    sudo apt install -y python3 python3-pip nginx postgresql-client
    echo 'Initial packages installed.'
    "
echo "VM 'my-flask-vm' creation initiated. External IP will be available shortly."

echo "Creating Cloud SQL for PostgreSQL instance..."
gcloud sql instances create my-flask-db \
    --database-version=POSTGRES_14 \
    --region=$GOOGLE_CLOUD_REGION \
    --cpu=1 \
    --memory=3840MiB \
    --storage-size=20GB \
    --project=$GOOGLE_CLOUD_PROJECT \
    --root-password=$DB_ROOT_PASSWORD
echo "Cloud SQL instance 'my-flask-db' creation initiated."

echo "Creating database user and database..."
gcloud sql users create flask_user \
    --instance=my-flask-db \
    --password=$FLASK_DB_PASSWORD \
    --host=% \
    --project=$GOOGLE_CLOUD_PROJECT

gcloud sql databases create my_flask_db \
    --instance=my-flask-db \
    --project=$GOOGLE_CLOUD_PROJECT
echo "Database user 'flask_user' and database 'my_flask_db' creation initiated."

echo "Waiting for Cloud SQL instance to be ready for IP authorization..."
gcloud sql instances describe my-flask-db --project=$GOOGLE_CLOUD_PROJECT --format="value(state)" | grep -q "RUNNABLE" || sleep 30

echo "Fetching VM external IP to authorize Cloud SQL connection..."
VM_EXTERNAL_IP=$(gcloud compute instances list --filter="name=(my-flask-vm)" --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
echo "VM External IP: $VM_EXTERNAL_IP"

# Authorize your VM's external IP to connect to the Cloud SQL instance
gcloud sql instances patch my-flask-db \
    --authorized-networks=$VM_EXTERNAL_IP/32 \
    --project=$GOOGLE_CLOUD_PROJECT
echo "Cloud SQL instance authorized for connections from your VM."

echo "Fetching Cloud SQL instance details (Public IP)..."
CLOUD_SQL_PUBLIC_IP=$(gcloud sql instances describe my-flask-db --project=$GOOGLE_CLOUD_PROJECT --format="value(ipAddresses[0].ipAddress)")
echo "Cloud SQL Public IP (for app config): $CLOUD_



_PUBLIC_IP"
echo ""
echo "--- NEXT STEP: ---"
echo "1. Wait for VM and Cloud SQL to be fully provisioned (may take several minutes)."
echo "2. SSH into your VM:"
echo "   gcloud compute ssh my-flask-vm --zone=$GOOGLE_CLOUD_ZONE"
echo "3. Once on the VM, run the 'setup_nginx_gunicorn.sh' script located in your local .gcloud folder."
echo "   You will need to manually copy it or its contents to the VM. A simple way:"
echo "   gcloud compute scp .gcloud/setup_nginx_gunicorn.sh my-flask-vm:~ --zone=$GOOGLE_CLOUD_ZONE"
echo "   Then, on the VM: bash setup_nginx_gunicorn.sh"
EOF
chmod +x .gcloud/deploy_vm.sh

# setup_nginx_gunicorn.sh
cat << 'EOF' > .gcloud/setup_nginx_gunicorn.sh
#!/bin/bash

# --- IMPORTANT: REPLACE PLACEHOLDERS BELOW ---
# Get this from the output of the deploy_vm.sh script or `gcloud sql instances describe my-flask-db`
DB_HOST="[YOUR_CLOUD_SQL_PUBLIC_IP]"
DB_NAME="my_flask_db"
DB_USER="flask_user"
DB_PASSWORD="[YOUR_FLASK_DB_PASSWORD]" # Must match the password used in deploy_vm.sh
# --- END IMPORTANT ---

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Starting VM Application Setup ---${NC}"

# Ensure we are in the home directory
cd ~

# --- 1. General System Updates and Software Installation (if not done by startup script) ---
echo -e "${YELLOW}Ensuring necessary packages are installed...${NC}"
sudo apt update
sudo apt install -y python3 python3-pip nginx postgresql-client
echo "Packages checked/installed."

# --- 2. Create Application Directory and Files ---
echo -e "${YELLOW}Creating application directory and files...${NC}"
APP_DIR="/home/$(whoami)/my_flask_app"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { echo -e "${RED}Error: Could not change to application directory. Exiting.${NC}"; exit 1; }

# Create app.py
cat << 'APP_EOF' > app.py
from flask import Flask
import os
import psycopg2
from psycopg2 import OperationalError

app = Flask(__name__)

@app.route('/')
def hello_world():
    return '<h1>Hello, World from Flask!</h1><p>Running with Gunicorn and Nginx on Google Cloud.</p>'

@app.route('/db_test')
def db_test():
    db_host = os.environ.get('DB_HOST')
    db_name = os.environ.get('DB_NAME')
    db_user = os.environ.get('DB_USER')
    db_password = os.environ.get('DB_PASSWORD')

    if not all([db_host, db_name, db_user, db_password]):
        return "<h1>Database Test Failed</h1><p>Database environment variables (DB_HOST, DB_NAME, DB_USER, DB_PASSWORD) are not set.</p>"

    conn = None
    try:
        conn = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password
        )
        cur = conn.cursor()
        cur.execute('SELECT version();')
        db_version = cur.fetchone()[0]
        cur.close()
        return f"<h1>Database Test Succeeded!</h1><p>Connected to PostgreSQL version: {db_version}</p>"
    except OperationalError as e:
        return f"<h1>Database Test Failed</h1><p>Could not connect to database: {e}</p>"
    except Exception as e:
        return f"<h1>An unexpected error occurred:</h1><p>{e}</p>"
    finally:
        if conn:
            conn.close()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(debug=True, host='0.0.0.0', port=port)
APP_EOF

# Create requirements.txt
cat << 'REQ_EOF' > requirements.txt
Flask
gunicorn
psycopg2-binary
REQ_EOF

# Create gunicorn_config.py
cat << 'GUNI_EOF' > gunicorn_config.py
workers = 4
bind = "0.0.0.0:8080"
timeout = 120
GUNI_EOF

# Create static directories and dummy files
mkdir -p static/{css,js,images}
cat << 'CSS_EOF' > static/css/style.css
/* static/css/style.css */
body {
    font-family: 'Inter', sans-serif;
    margin: 20px;
    background-color: #f0f2f5;
    color: #333;
}
h1 {
    color: #0056b3;
}
p {
    line-height: 1.6;
}
CSS_EOF

cat << 'JS_EOF' > static/js/script.js
// static/js/script.js
console.log("Hello from your Flask app's static JavaScript!");
document.addEventListener('DOMContentLoaded', () => {
    // Add any interactive JavaScript here
});
JS_EOF
touch static/images/logo.png # Dummy image file

# Create templates directories and dummy files
mkdir -p templates
cat << 'BASE_HTML_EOF' > templates/base.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}My Flask App{% endblock %}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <header>
        <nav>
            <a href="/">Home</a> | <a href="/db_test">DB Test</a>
        </nav>
    </header>
    <main>
        {% block content %}{% endblock %}
    </main>
    <footer>
        <p>&copy; 2024 My Flask App</p>
    </footer>
    <script src="{{ url_for('static', filename='js/script.js') }}"></script>
</body>
</html>
BASE_HTML_EOF

cat << 'INDEX_HTML_EOF' > templates/index.html
{% extends "base.html" %}
{% block title %}Home - My Flask App{% endblock %}
{% block content %}
    <h1>Welcome!</h1>
    <p>This is the home page of your Flask application.</p>
    <p>Check the database connection: <a href="/db_test">Test DB</a></p>
{% endblock %}
INDEX_HTML_EOF

cat << 'DB_TEST_HTML_EOF' > templates/db_test.html
{% extends "base.html" %}
{% block title %}DB Test - My Flask App{% endblock %}
{% block content %}
    <h1>Database Connection Test</h1>
    <p>This page will attempt to connect to the PostgreSQL database.</p>
    {# The actual DB test will happen in the /db_test route's Python code #}
DB_TEST_HTML_EOF

echo "Application files created."

# Install Python dependencies
echo -e "${YELLOW}Installing Python dependencies...${NC}"
pip3 install -r requirements.txt
echo "Python dependencies installed."

# --- 3. Configure Gunicorn Systemd Service ---
echo -e "${YELLOW}Configuring Gunicorn Systemd service...${NC}"
SERVICE_FILE="/etc/systemd/system/my_flask_app.service"
sudo bash -c "cat <<APP_SERVICE_EOF > \$SERVICE_FILE
[Unit]
Description=Gunicorn instance to serve my_flask_app
After=network.target

[Service]
User=$(whoami)
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=/usr/bin:/bin:/usr/local/bin"
# Set database connection environment variables for the service
Environment="DB_HOST=$DB_HOST"
Environment="DB_NAME=$DB_NAME"
Environment="DB_USER=$DB_USER"
Environment="DB_PASSWORD=$DB_PASSWORD"
ExecStart=/usr/bin/python3 -m gunicorn --config $APP_DIR/gunicorn_config.py app:app
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
Restart=on-failure

[Install]
WantedBy=multi-user.target
APP_SERVICE_EOF"

echo "Reloading systemd, starting and enabling Gunicorn service..."
sudo systemctl daemon-reload
sudo systemctl start my_flask_app
sudo systemctl enable my_flask_app
echo "Gunicorn service status:"
sudo systemctl status my_flask_app --no-pager # Check status (press q to exit)

# --- 4. Configure Nginx as a Reverse Proxy ---
echo -e "${YELLOW}Configuring Nginx reverse proxy...${NC}"
NGINX_CONF_FILE="/etc/nginx/sites-available/my_flask_app"

sudo rm -f /etc/nginx/sites-enabled/default # Remove default Nginx config

sudo bash -c "cat <<NGINX_CONF_EOF > \$NGINX_CONF_FILE
server {
    listen 80;
    server_name _; # Listen on any hostname (can be changed to VM's external IP or domain)

    location / {
        proxy_pass http://127.0.0.1:8080; # Forward requests to Gunicorn
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }

    location /static/ {
        alias $APP_DIR/static/; # Serve static files directly by Nginx
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
NGINX_CONF_EOF"

# Enable the Nginx site
sudo ln -sf "$NGINX_CONF_FILE" /etc/nginx/sites-enabled/my_flask_app

echo "Testing Nginx configuration and restarting Nginx..."
sudo nginx -t && sudo systemctl restart nginx
echo "Nginx service status:"
sudo systemctl status nginx --no-pager # Check status (press q to exit)

echo -e "${GREEN}--- VM Application Setup Complete! ---${NC}"
echo -e "${GREEN}Your Flask app should now be accessible via the VM's external IP.${NC}"
echo -e "${YELLOW}Remember to open http://[YOUR_VM_EXTERNAL_IP] in your browser.${NC}"
echo -e "${YELLOW}Also test the database connection at http://[YOUR_VM_EXTERNAL_IP]/db_test.${NC}"

EOF
chmod +x .gcloud/setup_nginx_gunicorn.sh

echo -e "${GREEN}--- Project Structure Generation Complete! ---${NC}"
echo -e "${GREEN}Your new Flask project is set up at: $(pwd)${NC}"
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "${YELLOW}1. Navigate into the '.gcloud' directory:${NC}"
echo -e "${YELLOW}   cd $PROJECT_ROOT/.gcloud${NC}"
echo -e "${YELLOW}2. Edit 'deploy_vm.sh' and 'setup_nginx_gunicorn.sh' to replace ALL placeholders ([YOUR_...]) with your actual project details and passwords.${NC}"
echo -e "${YELLOW}3. Run the VM deployment script: bash deploy_vm.sh${NC}"
echo -e "${YELLOW}4. Follow the instructions in the 'deploy_vm.sh' output for SSHing into the VM and running 'setup_nginx_gunicorn.sh'.${NC}"