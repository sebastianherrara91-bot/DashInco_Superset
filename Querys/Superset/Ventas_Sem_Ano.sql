-- REPORTE PARA SUPERSET (Dataset Virtual): "Ventas Semanales y Año Anterior"
-- NOTA: Como Superset usa Jinja en vez de parámetros directos, hemos reemplazado
-- los viejos :ini_cliente cortos por etiquetas estandar Jinja {{ filter_values() }}. 
-- Las fechas móviles se calculan automáticamente relativas a "hoy".

{% set cliente_default = 'PE1' %} -- Cambia por el cliente base si se abre en vacío
{% set cliente = filter_values('Ini_Cliente')[0] if filter_values('Ini_Cliente') else cliente_default %}
{% set threshold = 0 %} 
{% set s_stock = 4 %} 
{% set s_ventas = 4 %} 

WITH params AS (
    SELECT 
        (date_trunc('week', current_date) - interval '2 days')::date AS fecha_corte
),
Valid_Marca_Tipo AS (
    SELECT
        COALESCE(MS.marca, MA.new_marca, EC.marca) AS vmt_marca
        ,M.tipo AS vmt_tipo
    FROM dbo.dwh_stock AS ST
    CROSS JOIN params P
    LEFT JOIN dbo.cat_sku AS EC ON ST.ean = EC.ean
    LEFT JOIN dbo.marca_subclase AS MS ON ST.ini_cliente = MS.ini_cliente AND substring(EC.categoria from 1 for 7) = MS.subcategoria
    LEFT JOIN dbo.monitoreo AS M ON EC.ref_modelo = M.modelo AND EC.marca = M.marca
    LEFT JOIN dbo.marca AS MA ON EC.marca = MA.marca_bd
    WHERE ST.ini_cliente = '{{ cliente }}' AND ST.fecha = P.fecha_corte
    GROUP BY 1, 2
    HAVING SUM(ST.cant) >= {{ threshold }}
)

SELECT
    syv.ini_cliente AS "Ini_Cliente"
    ,syv.tipo_programa AS "Tipo_Programa"
    ,syv.c_l AS "C_L"
    ,(substring(syv.ciudad from 6 for 20) || ' - ' || syv.local) AS "Tienda"    
    ,syv.marca AS "Marca"
    ,syv.fecha AS "FECHA"
    ,syv.n_sem AS "N_SEM"
    ,syv.ano AS "ANO"
    ,SUM(syv.cant_v) AS "Cant_Venta"
    ,SUM(syv.cant_s) AS "Cant_Stock"
FROM (
    -- Stock (Semana actual y año anterior)
    SELECT
        ST.ini_cliente
        ,M.tipo AS tipo_programa
        ,ST.num_local AS c_l
        ,T.local
        ,T.ciudad
        ,VMT.vmt_marca AS marca
        ,ST.fecha
        ,SEM.n_sem
        ,SEM.ano
        ,0 AS cant_v
        ,ST.cant AS cant_s
    FROM dbo.dwh_stock AS ST
    CROSS JOIN params P
    LEFT JOIN dbo.cat_sku AS EC ON ST.ean = EC.ean
    INNER JOIN dbo.tiendas AS T ON ST.num_local = T.codigo AND T.ini_cliente = ST.ini_cliente AND T.tipo = 'TIENDA'
    LEFT JOIN dbo.monitoreo AS M ON EC.ref_modelo = M.modelo AND EC.marca = M.marca
    LEFT JOIN dbo.marca_subclase AS MS ON ST.ini_cliente = MS.ini_cliente AND substring(EC.categoria from 1 for 7) = MS.subcategoria
    LEFT JOIN dbo.marca AS MA ON EC.marca = MA.marca_bd
    INNER JOIN Valid_Marca_Tipo AS VMT ON VMT.vmt_tipo = M.tipo 
          AND VMT.vmt_marca = COALESCE(MS.marca, MA.new_marca, EC.marca)
    LEFT JOIN dbo.semanas AS SEM ON (date_trunc('week', ST.fecha))::date = SEM.dia_inicio
    WHERE ST.ini_cliente = '{{ cliente }}'
      AND (
          ST.fecha BETWEEN (P.fecha_corte - ('{{ s_stock }} weeks')::interval)::date AND P.fecha_corte
          OR 
          ST.fecha BETWEEN (P.fecha_corte - interval '1 year' - ('{{ s_stock }} weeks')::interval)::date 
          AND (P.fecha_corte - interval '1 year')::date
          )

    UNION ALL

    -- Ventas (Semana actual y año anterior)
    SELECT
        VT.ini_cliente
        ,M.tipo AS tipo_programa
        ,VT.num_local AS c_l
        ,T.local
        ,T.ciudad
        ,VMT.vmt_marca AS marca
        ,VT.fecha
        ,SEM.n_sem
        ,SEM.ano
        ,VT.cant AS cant_v
        ,0 AS cant_s
    FROM dbo.dwh_ventas AS VT
    CROSS JOIN params P
    LEFT JOIN dbo.cat_sku AS EC ON VT.ean = EC.ean
    INNER JOIN dbo.tiendas AS T ON VT.num_local = T.codigo AND T.ini_cliente = VT.ini_cliente AND T.tipo = 'TIENDA'
    LEFT JOIN dbo.monitoreo AS M ON EC.ref_modelo = M.modelo AND EC.marca = M.marca
    LEFT JOIN dbo.marca_subclase AS MS ON VT.ini_cliente = MS.ini_cliente AND substring(EC.categoria from 1 for 7) = MS.subcategoria
    LEFT JOIN dbo.marca AS MA ON EC.marca = MA.marca_bd
    INNER JOIN Valid_Marca_Tipo AS VMT ON VMT.vmt_tipo = M.tipo 
        AND VMT.vmt_marca = COALESCE(MS.marca, MA.new_marca, EC.marca)
    LEFT JOIN dbo.semanas AS SEM ON (date_trunc('week', VT.fecha))::date = SEM.dia_inicio
    WHERE VT.ini_cliente = '{{ cliente }}'
      AND (
          VT.fecha BETWEEN (P.fecha_corte - ('{{ s_ventas }} weeks')::interval)::date AND P.fecha_corte
          OR 
          VT.fecha BETWEEN (P.fecha_corte - interval '1 year' - ('{{ s_ventas }} weeks')::interval)::date 
                       AND (P.fecha_corte - interval '1 year')::date
      )
) AS syv

GROUP BY 1,2,3,4,5,6,7,8
