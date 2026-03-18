SELECT 
    Ano, 
    Periodo, 
    Fecha,
    Nit_Proveedor,
    Nombre_Proveedor,
    Cuenta,
    cu.nombre AS Nombre_Cuenta,
    SUBSTRING(Documento_Afecta FROM 1 FOR 4) AS Tipo_de_Documento,
    dx.nombre AS Nombre_Tipo_de_Documento,
    SUBSTRING(Documento_Afecta FROM 5 FOR 20) AS Documento,
    Concepto, 
    Centro_de_Costo,
    ce.nombre AS Nombre_Centro_de_Costo,
    Valor_Factura,
    Saldo_Factura,
    CAST(HEDATETOSTR(fecha_vence,'yyyy/mm/dd') AS DATE) AS Fecha_Vencimiento,
    mora AS Dias_Mora,
    iif(mora <= 0, Saldo_Factura, 0) AS Saldo_Por_Vencer,
    iif(mora > 0 AND mora <= 30, Saldo_Factura, 0) AS C_X_Pagar_de_1_a_30_dias,
    iif(mora > 30 AND mora <= 60, Saldo_Factura, 0) AS C_X_Pagar_de_31_a_60_dias,
    iif(mora > 60 AND mora <= 90, Saldo_Factura, 0) AS C_X_Pagar_de_61_a_90_dias,
    iif(mora > 90 AND mora <= 120, Saldo_Factura, 0) AS C_X_Pagar_de_91_a_120_dias,
    iif(mora > 120 AND mora <= 150, Saldo_Factura, 0) AS C_X_Pagar_de_121_a_150_dias,
    iif(mora > 90, Saldo_Factura, 0) AS C_X_Pagar_Mayor_a_90_dias,
    iif(mora > 120, Saldo_Factura, 0) AS C_X_Pagar_Mayor_a_120_dias,
    iif(mora > 150, Saldo_Factura, 0) AS C_X_Pagar_Mayor_a_150_dias,
    iif(mora > 180, Saldo_Factura, 0) AS C_X_Pagar_Mayor_a_180_dias
FROM (
    SELECT
        HEDATETOSTR(estado.Fecha_Afecta,'yyyy') AS Ano,
        HEDATETOSTR(estado.Fecha_Afecta,'yyyymm') AS Periodo,
        HEDATETOSTR(estado.Fecha_Afecta,'mm/dd/yyyy') AS Fecha,
        pr.identidad AS Nit_Proveedor,
        pr.nombre AS Nombre_Proveedor,
        estado.cuenta AS Cuenta,
        estado.Documento_Afecta AS Documento_Afecta,
        co.concepto AS Concepto,
        iif(co.centro_activo = 'S', co.centro, '') AS Centro_de_Costo,
        estado.saldo AS Saldo_Factura, 
        co.valor AS Valor_Factura,
        (SELECT MIN(a.fecha_vence) 
         FROM cptrxxxx a 
         WHERE a.documento = estado.documento_afecta
           AND a.fecha = estado.fecha_afecta
           AND a.cuota_afecta = estado.cuota_afecta
           AND a.ind_contabilidad = estado.indice_afecta) AS fecha_vence, 
        CAST(EXTRACT(year FROM CAST('now' AS DATE)) || '/' || EXTRACT(month FROM CAST('now' AS DATE)) || '/' || lpad(EXTRACT(day FROM CAST('now' AS DATE)), 2, '0') AS DATE) - hefechatofecha(
            (SELECT MIN(a.fecha_vence) 
             FROM cptrxxxx a 
             WHERE a.documento = estado.documento_afecta
               AND a.fecha = estado.fecha_afecta
               AND a.cuota_afecta = estado.cuota_afecta
               AND a.ind_contabilidad = estado.indice_afecta)
        ) AS mora
    FROM (  
        SELECT tr.Documento_Afecta, tr.Indice_Afecta, tr.Fecha_Afecta, tr.cuota_afecta,
               tr.codigo_proveedor, tr.cuenta, ROUND(SUM(tr.valor * claseasiento(tr.asiento))) AS saldo
        FROM cptrxxxx tr
        INNER JOIN cotrxxxx c ON c.indice_primario = tr.ind_contabilidad AND c.fecha = tr.fecha
        WHERE (hefechatofecha(tr.fecha) <= EXTRACT(year FROM CAST('now' AS DATE)) || EXTRACT(month FROM CAST('now' AS DATE)) || lpad(EXTRACT(day FROM CAST('now' AS DATE)), 2, '0'))
        GROUP BY tr.Documento_Afecta, tr.Indice_Afecta, tr.Fecha_Afecta, tr.cuota_afecta, tr.codigo_proveedor, tr.cuenta
        HAVING ROUND(SUM(tr.valor * claseasiento(tr.asiento))) > 0
    ) estado
    LEFT JOIN cpma2026 pr ON pr.codigo = estado.codigo_proveedor
    LEFT JOIN cotrxxxx co ON co.fecha = estado.fecha_afecta AND co.ind_contabilidad = estado.indice_afecta
) BaseDatos
LEFT JOIN coma2026 cu ON cu.cuenta = BaseDatos.Cuenta
LEFT JOIN DOCUXXXX dx ON SUBSTRING(BaseDatos.Documento_Afecta FROM 1 FOR 4) = dx.TIPO
LEFT JOIN CEMA2026 ce ON BaseDatos.Centro_de_Costo = ce.CODIGO;
