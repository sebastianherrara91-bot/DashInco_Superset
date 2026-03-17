-- REPORTE PARA SUPERSET (Dataset Virtual): "Ventas y Stock Últimas Semanas"
-- Modificado para usar Jinja Templating y automatizar el cálculo de fechas
-- basándose en la fecha actual (current_date).

{% set cliente_default = 'PE1' %}
{% set cliente = filter_values('ini_cliente')[0] if filter_values('ini_cliente') else cliente_default %}
{% set threshold = 0 %} 
{% set s_stock = 4 %} 
{% set s_ventas = 4 %} 

WITH params AS (
    SELECT 
        (date_trunc('week', current_date) - interval '2 days')::date AS fecha_fin,
        ((date_trunc('week', current_date) - interval '2 days') - interval '{{ s_stock }} weeks')::date AS fecha_inicio_stock,
        ((date_trunc('week', current_date) - interval '2 days') - interval '{{ s_ventas }} weeks')::date AS fecha_inicio_venta
),
Valid_Marca_Tipo AS (
    -- Pre-calculamos las marcas que cumplen el umbral de stock para reducir el universo de datos
    SELECT
        COALESCE(MS.marca, MA.new_marca, EC.marca) AS vmt_marca,
        M.tipo AS vmt_tipo
    FROM dbo.dwh_stock AS ST
    CROSS JOIN params P
    LEFT JOIN dbo.cat_sku AS EC ON ST.ean = EC.ean
    LEFT JOIN dbo.marca_subclase AS MS 
        ON ST.ini_cliente = MS.ini_cliente 
        AND substring(EC.categoria from 1 for 7) = MS.subcategoria
    LEFT JOIN dbo.monitoreo AS M ON EC.ref_modelo = M.modelo AND EC.marca = M.marca
    LEFT JOIN dbo.marca AS MA ON EC.marca = MA.marca_bd
    WHERE ST.ini_cliente = '{{ cliente }}'
      AND ST.fecha = P.fecha_fin -- Salta directo a la partición final
    GROUP BY 1, 2
    HAVING SUM(ST.cant) >= {{ threshold }}
)

SELECT
    syv.ini_cliente AS "Ini_Cliente"
    ,syv.c_l AS "C_L"
    ,syv.local AS "Local"
    ,syv.ciudad AS "Ciudad"
    ,syv.ean AS "EAN"
    ,syv.sku AS "SKU"
    ,syv.modelo AS "Modelo"
    ,syv.marca AS "Marca"
    ,syv.subclase AS "Subclase"
    ,syv.tipo_programa AS "Tipo_Programa"
    ,syv.fit_estilo AS "Fit_Estilo"
    ,syv.fecha AS "FECHA"
    ,to_char(syv.fecha, 'YY') || '/' || to_char(syv.n_sem, 'FM00') || ' - ' || to_char(syv.fecha, 'MM/DD') AS "Semanas_Format"
    ,SUM(syv.v_cant) AS "Cant_Venta"
    ,SUM(syv.s_cant) AS "Cant_Stock"
    ,NULLIF(ROUND(SUM(syv.v_cant * syv.v_pvp) / NULLIF(SUM(syv.v_cant), 0), 0), 0) AS "PVP_Prom"
FROM (
    -- BLOQUE STOCK
    SELECT
        ST.ini_cliente
        ,ST.num_local AS c_l
        ,T.local
        ,T.ciudad
        ,ST.ean
        ,EC.sku
        ,EC.ref_modelo AS modelo
        ,VMT.vmt_marca AS marca
        ,substring(EC.categoria from 1 for 7) AS subclase
        ,M.tipo AS tipo_programa
        ,M.fit AS fit_estilo
        ,(date_trunc('week', ST.fecha))::date AS fecha
        ,SEM.n_sem
        ,SEM.ano
        ,0 AS v_cant
        ,ST.cant AS s_cant
        ,0 AS v_pvp
    FROM dbo.dwh_stock AS ST
    CROSS JOIN params P
    LEFT JOIN dbo.cat_sku AS EC ON ST.ean = EC.ean
    LEFT JOIN dbo.tiendas AS T ON ST.num_local = T.codigo AND T.ini_cliente = ST.ini_cliente
    LEFT JOIN dbo.monitoreo AS M ON EC.ref_modelo = M.modelo AND EC.marca = M.marca
    LEFT JOIN dbo.marca_subclase AS MS ON ST.ini_cliente = MS.ini_cliente AND substring(EC.categoria from 1 for 7) = MS.subcategoria
    LEFT JOIN dbo.marca AS MA ON EC.marca = MA.marca_bd
    INNER JOIN Valid_Marca_Tipo AS VMT ON VMT.vmt_tipo = M.tipo 
        AND VMT.vmt_marca = COALESCE(MS.marca, MA.new_marca, EC.marca)
    LEFT JOIN dbo.semanas AS SEM ON (date_trunc('week', ST.fecha))::date = SEM.dia_inicio
    WHERE ST.ini_cliente = '{{ cliente }}'
      AND ST.fecha BETWEEN P.fecha_inicio_stock AND P.fecha_fin

    UNION ALL

    -- BLOQUE VENTAS
    SELECT
        VT.ini_cliente
        ,VT.num_local AS c_l
        ,T.local
        ,T.ciudad
        ,VT.ean
        ,EC.sku
        ,EC.ref_modelo AS modelo
        ,VMT.vmt_marca AS marca
        ,substring(EC.categoria from 1 for 7) AS subclase
        ,M.tipo AS tipo_programa
        ,M.fit AS fit_estilo
        ,(date_trunc('week', VT.fecha))::date AS fecha
        ,SEM.n_sem
        ,SEM.ano
        ,VT.cant AS v_cant
        ,0 AS s_cant
        ,VT.pvp_unit AS v_pvp
    FROM dbo.dwh_ventas AS VT
    CROSS JOIN params P
    LEFT JOIN dbo.cat_sku AS EC ON VT.ean = EC.ean
    LEFT JOIN dbo.tiendas AS T ON VT.num_local = T.codigo AND T.ini_cliente = VT.ini_cliente
    LEFT JOIN dbo.monitoreo AS M ON EC.ref_modelo = M.modelo AND EC.marca = M.marca
    LEFT JOIN dbo.marca_subclase AS MS ON VT.ini_cliente = MS.ini_cliente AND substring(EC.categoria from 1 for 7) = MS.subcategoria
    LEFT JOIN dbo.marca AS MA ON EC.marca = MA.marca_bd
    INNER JOIN Valid_Marca_Tipo AS VMT ON VMT.vmt_tipo = M.tipo 
        AND VMT.vmt_marca = COALESCE(MS.marca, MA.new_marca, EC.marca)
    LEFT JOIN dbo.semanas AS SEM ON (date_trunc('week', VT.fecha))::date = SEM.dia_inicio
    WHERE VT.ini_cliente = '{{ cliente }}'
      AND VT.fecha BETWEEN P.fecha_inicio_venta AND P.fecha_fin
) AS syv
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13;
