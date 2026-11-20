#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# SonarQube Community Build 26.5.0 + Community Branch Plugin
# Tested on: Ubuntu 24.04 / 26.04 / Debian 12
# ============================================================

SQ_VERSION="26.5.0.122743"
SQ_DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SQ_VERSION}.zip"
PLUGIN_VERSION="26.5.0"
INSTALL_DIR="/opt/sonarqube"
SONAR_USER="sonarqube"
SONAR_DB="sonarqube"
SONAR_DB_USER="sonarqube"
SONAR_DB_PASS="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)"
PG_VERSION="16"

# --- Prerequisites ---
echo "[1/12] Installing prerequisites..."
sudo apt-get update -qq
sudo apt-get install -y -qq unzip wget curl gnupg postgresql-${PG_VERSION}

# --- JDK 21 ---
if ! java -version 2>&1 | grep -q 'version 21'; then
  echo "[2/12] Installing JDK 21..."
  sudo apt-get install -y -qq openjdk-21-jdk-headless
fi

# --- System user ---
echo "[3/12] Creating sonarqube system user..."
sudo id -u ${SONAR_USER} &>/dev/null || sudo useradd -r -d ${INSTALL_DIR} -s /bin/bash ${SONAR_USER}

# --- PostgreSQL ---
echo "[4/12] Configuring PostgreSQL database..."
sudo -u postgres psql -c "CREATE USER ${SONAR_DB_USER} WITH ENCRYPTED PASSWORD '${SONAR_DB_PASS}';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ${SONAR_DB} OWNER ${SONAR_DB_USER};" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${SONAR_DB} TO ${SONAR_DB_USER};" 2>/dev/null || true

# --- Download SonarQube ---
echo "[5/12] Downloading SonarQube ${SQ_VERSION}..."
cd /tmp
wget -q -O sonarqube.zip "${SQ_DOWNLOAD_URL}"

echo "[6/12] Extracting to ${INSTALL_DIR}..."
sudo unzip -q sonarqube.zip -d /tmp/sonarqube-extract
# Remove the home dir that useradd created, replace with SonarQube contents
sudo rm -rf ${INSTALL_DIR}
sudo mv /tmp/sonarqube-extract/sonarqube-${SQ_VERSION} ${INSTALL_DIR}
sudo chown -R ${SONAR_USER}:${SONAR_USER} ${INSTALL_DIR}
rm -rf /tmp/sonarqube-extract

# --- Configure sonar.properties ---
echo "[7/12] Configuring sonar.properties..."
SQ_CONF="${INSTALL_DIR}/conf/sonar.properties"

sudo -u ${SONAR_USER} tee -a ${SQ_CONF} > /dev/null <<EOF

# --- Database Configuration ---
sonar.jdbc.username=${SONAR_DB_USER}
sonar.jdbc.password=${SONAR_DB_PASS}
sonar.jdbc.url=jdbc:postgresql://localhost:5432/${SONAR_DB}

# --- Elasticsearch ---
sonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false

EOF

# --- Kernel params ---
echo "[8/12] Setting kernel parameters..."
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-sonarqube.conf > /dev/null
sudo sysctl -w vm.max_map_count=262144

# --- Limits ---
echo "sonarqube - nofile 65536" | sudo tee /etc/security/limits.d/99-sonarqube.conf > /dev/null
echo "sonarqube - nproc 4096" | sudo tee -a /etc/security/limits.d/99-sonarqube.conf > /dev/null

# --- Download & install plugin ---
echo "[9/12] Installing community branch plugin..."
PLUGIN_JAR="sonarqube-community-branch-plugin-${PLUGIN_VERSION}.jar"
wget -q -O /tmp/${PLUGIN_JAR} \
  "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/${PLUGIN_JAR}"
sudo cp /tmp/${PLUGIN_JAR} ${INSTALL_DIR}/extensions/plugins/

wget -q -O /tmp/sonarqube-webapp.zip \
  "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${PLUGIN_VERSION}/sonarqube-webapp.zip"
sudo unzip -qo /tmp/sonarqube-webapp.zip -d ${INSTALL_DIR}/web/
sudo chown -R ${SONAR_USER}:${SONAR_USER} ${INSTALL_DIR}/web/

# --- Add javaagent opts ---
echo "[10/12] Adding javaagent configuration..."
JAVA_AGENT="-javaagent:./extensions/plugins/${PLUGIN_JAR}"
sudo -u ${SONAR_USER} tee -a ${SQ_CONF} > /dev/null <<EOF

# --- Community Branch Plugin ---
sonar.web.javaAdditionalOpts=${JAVA_AGENT}=web
sonar.ce.javaAdditionalOpts=${JAVA_AGENT}=ce

EOF

# --- systemd service ---
echo "[11/12] Creating systemd service..."
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<'SYSTEMD'
[Unit]
Description=SonarQube service
After=network.target postgresql.service

[Service]
Type=forking
User=sonarqube
Group=sonarqube
WorkingDirectory=/opt/sonarqube
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
PIDFile=/opt/sonarqube/bin/linux-x86-64/SonarQube.pid
LimitNOFILE=65536
LimitNPROC=4096
Restart=on-failure
RestartSec=10
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SYSTEMD

sudo systemctl daemon-reload
sudo systemctl enable sonarqube

# --- Start ---
echo "[12/12] Starting SonarQube..."
sudo systemctl start sonarqube

# --- Summary ---
echo ""
echo "============================================"
echo " SonarQube Community Build + Branch Plugin"
echo "============================================"
echo " URL:        http://$(hostname -I | awk '{print $1}'):9000"
echo " DB Name:    ${SONAR_DB}"
echo " DB User:    ${SONAR_DB_USER}"
echo " DB Pass:    ${SONAR_DB_PASS}"
echo " Plugin:     ${PLUGIN_VERSION}"
echo " Logs:       ${INSTALL_DIR}/logs/"
echo " Status:     sudo systemctl status sonarqube"
echo "============================================"
echo ""
echo "NOTE: Initial startup takes 2-5 minutes."
echo "Default admin login: admin / admin"
