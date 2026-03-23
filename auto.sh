#!/bin/bash

# ============================================================
#  CTF 2026 Auto-Run Script
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}${BOLD}=============================================${NC}"
echo -e "${CYAN}${BOLD}        CTF 2026 Cyber - Setup Script        ${NC}"
echo -e "${CYAN}${BOLD}=============================================${NC}"
echo ""

# ============================================================
# STEP 1 - Check Docker is installed
# ============================================================
echo -e "${YELLOW}[*] Checking Docker installation...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}[✗] Docker is not installed. Installing now...${NC}"
    sudo apt install -y docker.io
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}[✗] Docker installation failed. Please try manually: sudo apt install docker.io${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Docker installed successfully.${NC}"
else
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}[✓] Docker found: ${DOCKER_VERSION}${NC}"
fi

# ============================================================
# STEP 2 - Check Docker Compose is installed
# ============================================================
echo -e "${YELLOW}[*] Checking Docker Compose installation...${NC}"

if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    echo -e "${GREEN}[✓] Docker Compose found: ${COMPOSE_VERSION}${NC}"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${GREEN}[✓] Docker Compose (standalone) found: ${COMPOSE_VERSION}${NC}"
else
    echo -e "${RED}[✗] Docker Compose is not installed. Installing now...${NC}"
    sudo apt install -y docker-compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}[✗] Docker Compose installation failed. Please try manually: sudo apt install docker-compose${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Docker Compose installed successfully.${NC}"
fi

# ============================================================
# STEP 3 - Stop and remove any running containers
# ============================================================
echo ""
echo -e "${YELLOW}[*] Stopping and removing all running containers...${NC}"

RUNNING=$(docker ps -q)
if [ -n "$RUNNING" ]; then
    docker stop $RUNNING &> /dev/null
    docker rm $RUNNING &> /dev/null
    echo -e "${GREEN}[✓] All containers stopped and removed.${NC}"
else
    echo -e "${GREEN}[✓] No running containers found.${NC}"
fi

# ============================================================
# STEP 4 - Remove all existing Docker images
# ============================================================
echo -e "${YELLOW}[*] Removing all existing Docker images...${NC}"

IMAGES=$(docker images -q)
if [ -n "$IMAGES" ]; then
    docker rmi -f $IMAGES &> /dev/null
    echo -e "${GREEN}[✓] All images removed.${NC}"
else
    echo -e "${GREEN}[✓] No images found to remove.${NC}"
fi

# ============================================================
# STEP 5 - Pull latest image from Docker Hub
# ============================================================
echo ""
echo -e "${YELLOW}[*] Pulling latest CTF image from Docker Hub...${NC}"

docker pull ffufmaster/evento2026:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}[✗] Failed to pull image. Check your internet connection.${NC}"
    exit 1
fi
echo -e "${GREEN}[✓] Image pulled successfully.${NC}"

# ============================================================
# STEP 6 - Start the CTF container
# ============================================================
echo ""
echo -e "${YELLOW}[*] Starting CTF container...${NC}"

docker run -d \
    --name evento2026 \
    --cap-add SETUID \
    --cap-add SETGID \
    --security-opt no-new-privileges:false \
    -p 80:80 \
    -p 22:22 \
    -p 21:21 \
    ffufmaster/evento2026:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}[✗] Failed to start the container.${NC}"
    exit 1
fi
echo -e "${GREEN}[✓] Container started successfully.${NC}"

# ============================================================
# STEP 7 - Get the IP to scan
# ============================================================
echo ""
echo -e "${YELLOW}[*] Detecting your target IP...${NC}"

# Get the Docker bridge network IP (container gateway)
DOCKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' evento2026)

# Fallback: use localhost
if [ -z "$DOCKER_IP" ]; then
    DOCKER_IP="127.0.0.1"
fi

echo ""
echo -e "${CYAN}${BOLD}=============================================${NC}"
echo -e "${CYAN}${BOLD}         CTF is READY! Happy Hacking!        ${NC}"
echo -e "${CYAN}${BOLD}=============================================${NC}"
echo ""
echo -e "${BOLD}  Target IP   :${NC}  ${GREEN}${BOLD}$DOCKER_IP${NC}"
echo ""
echo -e "${YELLOW}  Tip: Start with nmap and enjoy!"
echo ""
