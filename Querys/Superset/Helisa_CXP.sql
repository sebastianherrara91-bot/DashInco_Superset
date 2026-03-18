SELECT 
    Ano, Periodo, Fecha,
    (Periodo || SUBSTRING(Fecha FROM 1 FOR 2)) AS Fecha_AMD,
    Nit AS Nit_Proveedor,
    PRO.Nombre AS Nombre_Proveedor,
    Cuenta,
    CTA.NOMBRE AS Nombre_Cuenta,
    TipodeDocumento AS Tipo_de_Documento,
    DOCUXXXX.NOMBRE AS Nombre_Tipo_de_Documento,
    Documento, Concepto, 
    centroc AS Centro_de_Costo,
    CCO.NOMBRE AS Nombre_Centro_de_Costo,
    factura AS Valor_Factura,
    saldodoc AS Saldo_Factura,
    CAST(HEDATETOSTR(fecha_vence,'yyyy/mm/dd') AS DATE) AS Fecha_Vencimiento,
    mora AS Dias_Mora,
    iif(mora <= 0, saldodoc, 0) AS Saldo_Por_Vencer,
    iif(mora > 0 AND mora <= 30, saldodoc, 0) AS C_X_Pagar_de_1_a_30_dias,
    iif(mora > 30 AND mora <= 60, saldodoc, 0) AS C_X_Pagar_de_31_a_60_dias,
    iif(mora > 60 AND mora <= 90, saldodoc, 0) AS C_X_Pagar_de_61_a_90_dias,
    iif(mora > 90 AND mora <= 120, saldodoc, 0) AS C_X_Pagar_de_91_a_120_dias,
    iif(mora > 120 AND mora <= 150, saldodoc, 0) AS C_X_Pagar_de_121_a_150_dias,
    iif(mora > 90, saldodoc, 0) AS C_X_Pagar_Mayor_a_90_dias,
    iif(mora > 120, saldodoc, 0) AS C_X_Pagar_Mayor_a_120_dias,
    iif(mora > 150, saldodoc, 0) AS C_X_Pagar_Mayor_a_150_dias,
    iif(mora > 180, saldodoc, 0) AS C_X_Pagar_Mayor_a_180_dias
FROM (
    SELECT
        HEDATETOSTR(estado.Fecha_Afecta,'yyyy') AS Ano,
        HEDATETOSTR(estado.Fecha_Afecta,'yyyymm') AS Periodo,
        HEDATETOSTR(estado.Fecha_Afecta,'mm/dd/yyyy') AS Fecha,
        pr.identidad AS Nit,
        estado.codigo_proveedor AS Proveedor,
        estado.cuenta AS Cuenta,
        SUBSTRING(estado.Documento_Afecta FROM 1 FOR 4) AS TipodeDocumento,
        SUBSTRING(estado.Documento_Afecta FROM 5 FOR 20) AS Documento,
        co.concepto AS concepto,
        iif(co.centro_activo = 'S', co.centro, '') AS centroc,
        (SELECT MIN(a.fecha_vence) 
         FROM cptrxxxx a 
         WHERE a.documento = estado.documento_afecta
           AND a.fecha = estado.fecha_afecta
           AND a.cuota_afecta = estado.cuota_afecta
           AND a.ind_contabilidad = estado.indice_afecta) AS fecha_vence, 
        estado.saldo AS saldodoc, 
        co.valor AS factura,
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
    LEFT JOIN coma2026 cu ON cu.cuenta = estado.cuenta
    LEFT JOIN cpma2026 pr ON pr.codigo = estado.codigo_proveedor
    LEFT JOIN cotrxxxx co ON co.fecha = estado.fecha_afecta AND co.ind_contabilidad = estado.indice_afecta
) BaseDatos
LEFT JOIN CPMA2026 PRO ON BaseDatos.Proveedor = PRO.Codigo
LEFT JOIN COMA2026 CTA ON BaseDatos.Cuenta = CTA.CUENTA
LEFT JOIN cuentas_niif CTN ON CTA.cuenta_niif = CTN.cuenta 
LEFT JOIN DOCUXXXX ON BaseDatos.TipodeDocumento = DOCUXXXX.TIPO
LEFT JOIN CEMA2026 CCO ON BaseDatos.centroc = CCO.CODIGO;
