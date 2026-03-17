# Estado del Proyecto: DashInco V2.0 (Migración a Superset)

**Fecha de última actualización:** Marzo de 2026
**Objetivo de la V2.0:** Reemplazar el backend de Streamlit y procesamiento en Python crudo por una plataforma analítica empresarial automatizada, utilizando **Apache Superset** para visualización, **Redis** para caché de alto rendimiento y **PostgreSQL** como origen de datos (`DWH_INCO`).

## 1. Decisiones Arquitectónicas Tomadas
*   **Contenedorizado 100%:** Se abandonó la instalación nativa con entornos virtuales (`venv`), servicios de `systemd` y `Nginx`.
*   **Orquestación con Docker Compose:** Se creó el archivo `docker-compose.yml` que lanza de manera conjunta 6 contenedores indispensables.
*   **Infraestructura Proxmox (Actualizado):** Se reemplazó la creación manual de un LXC Ubuntu 24.04 por el uso del **Proxmox Helper Script** oficial de la comunidad (`docker-vm.sh` o su equivalente LXC) que ya incluye Docker, Portainer y Docker Compose preconfigurados y optimizados.

## 2. Archivos Claves Generados
1.  `docker-compose.yml`: Archivo de orquestación de Docker.
2.  `superset_config.py`: Archivo de configuración en Python inyectado al contenedor, que activa variables vitales como el *Cross Filtering*, los tiempos de espera (Timeouts) amplios de 5 minutos, y la parametrización de Redis/Celery.
3.  `install_docker_lxc.sh`: Script bash simplificado (ahora solo clona el repositorio y levanta docker-compose, ya que Docker fue instalado por el Helper Script).
4.  `Despliegue_Contenedor_Portainer.txt`: Guía actualizada para desplegar la solución en la nueva VM/LXC de Docker generada por el script de Proxmox.

## 3. Próximos Pasos Pendientes (Continuación del Trabajo)
Una vez que se haya desplegado y validado el acceso a Superset (puerto `:8088`, credenciales `admin/admin`), el trabajo de desarrollo debe continuar en:

1.  **Conexión de Base de Datos:** Entrar a Superset y añadir la cadena de conexión de postgresql al origen DWH_INCO basándose en las credenciales del `.env`.
2.  **Migración de Queries (SQL Lab -> Virtual Datasets):**
    *   Los archivos que se ecuentran en la carpeta `/Querys/` deben procesarse e insertarse en "SQL Lab" para crear "Virtual Datasets".
    *   **Refactorización de Variables:** Actualmente los sql usan binding variables como `:fecha_inicio`, `:fecha_fin` o `:ini_cliente`. Estos deberán ser convertidos a la sintaxis de macros **Jinja (`{{ filter }}`)** propia de Superset, O omitidos del script CTE inicial de Superset permitiendole a los **Dashboard Date Filters** (y Cross-filters) inyectar dinámicamente el SQL a la consulta final generada por SQLAlchemy.
3.  **Construcción de Dashboards:** Crear las gráficas visuales orientadas a Mobile-First según se especificaba en el `Inicio.MD`.
