Guía Base: Evolución a DashInco 2.0 (BI Empresarial)
Este documento detalla la hoja de ruta para transformar el prototipo inicial en una plataforma de inteligencia de negocios escalable, optimizada para dispositivos móviles y con alta capacidad de procesamiento.

1. Visión y Objetivos del Negocio 🎯
El panel debe permitir diagnosticar el estado del negocio de forma inmediata.

Filosofía Mobile-First: La interfaz debe ser fluida en celulares y tablets para consultas en tiempo real desde cualquier lugar.

Regla de Oro: Menos clics para ver más valor, manteniendo una jerarquía visual clara.

Estética Profesional: Dashboards responsivos con modo oscuro/claro armonizado que inviten al uso diario.

2. Arquitectura de Datos: El Motor Híbrido 🐘⚡
Se mantiene PostgreSQL como núcleo, pero se evoluciona la capa de procesamiento en Python.

Optimización SQL (PostgreSQL)
CTEs Perfiladores (Valid_Marca_Tipo): Filtrado previo por umbrales de cantidad para acelerar cruces masivos.

Lógica de Negocio con COALESCE: Manejo de excepciones y correcciones sin queries anidados pesados.

Robustez en Nulos: Uso de IS NOT DISTINCT FROM para no perder inventario en los cruces.

Procesamiento de Alto Rendimiento (Polars)
Sustituir Pandas por Polars en scripts de backend para manejar millones de registros con procesamiento multihilo, reduciendo drásticamente el uso de memoria y tiempo de ejecución.

Mantener el uso de concurrent.futures.ThreadPoolExecutor para disparar queries en paralelo.

3. Visualización: Apache Superset 📊
En lugar de programar cada gráfico manualmente, se adopta Apache Superset para una gestión profesional del BI.

Gráfica de Participación Venta vs Stock: Replicar el análisis de exceso/desabastecimiento usando barras dobles, vinculando directamente las variables hexagonales (Color_Hexa) para la identidad visual del inventario.

Exploración Dinámica: Permitir que el usuario filtre por local, marca o categoría sin recargar la página completa.

Caching: Implementación de Redis para que las consultas recurrentes carguen en milisegundos.

4. Infraestructura y Despliegue 🐋
Para garantizar que el sistema funcione igual en desarrollo (Windows) y producción (Linux).

Contenedores (Docker): Todo el stack (Superset, Redis, Postgres) debe vivir en contenedores para facilitar la portabilidad y escalabilidad.

Automatización (PowerShell): Mantener y expandir los scripts de PowerShell para tareas de mantenimiento de la base de datos PostgreSQL, generación de logs y backups del sistema.

5. Pruebas de Rendimiento y Calidad 🛡️
Diagnóstico SQL: Es obligatorio usar EXPLAIN (ANALYZE, BUFFERS) antes de pasar cualquier query a producción para evitar escaneos secuenciales innecesarios.

Control de Calidad en Datos:

Validar nulos en Python antes de interactuar con textos para evitar errores de tipo NoneType.

Asegurar consistencia en los nombres de columnas (Case Sensitive) para evitar KeyErrors en la capa de visualización.

6. Flujo de Trabajo para Nuevos Módulos
Al crear un nuevo análisis (Ej: Rentabilidad):

Diseñar el .sql optimizado con CTEs en PostgreSQL.

Validar tiempos con test_rendimiento.py (< 5 segundos).

Configurar el Dataset en Apache Superset.

Diseñar la visualización (Chart) y añadirla al Dashboard principal.

Verificar la correcta visualización en dispositivos móviles (Tablet/Celular).