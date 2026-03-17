#!/bin/bash
set -e

# ============================================================================
# Instalador Simplificado (Legacy Mode)
# 
# NOTA: Este script YA NO ES ESTRICTAMENTE NECESARIO si haces uso de los
# Stacks directos en Portainer vinculando tu repositorio de Git.
#
# Úsalo SOLO si prefieres levantar los servicios manualmente por CLI dentro 
# de tu máquina virtual / LXC docker generada por el script de Proxmox.
# ============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Por favor, corre este script como root (sudo)"
  exit
fi

echo "[1/2] Preparando carpeta del proyecto vía CLI..."
if [ ! -d "/opt/DashInco" ]; then
    cd /opt
    git clone https://github.com/sebastianherrara91-bot/Stremlit_Postgre.git DashInco
fi
cd /opt/DashInco

# Hacemos git pull por si ya existía el repositorio clonado
git pull origin main

echo "[2/2] Levantando contenedores Superset (CLI Fallback)..."
docker compose pull
docker compose up -d

echo ""
echo "¡Instalación por CLI Finalizada!"
echo "Validación: docker compose logs -f superset-init"
echo "URL: http://<IP>:8088"
