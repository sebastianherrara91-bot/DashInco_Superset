SELECT 
    SF.ANO AS Ano,
    SF.periodo AS Periodo,
    SF.fecha AS Fecha,
    (SF.periodo || SUBSTRING(SF.fecha FROM 1 FOR 2)) AS Fecha_AMD,
    TRIM(SF.Nit) AS Nit_Proveedor,
    PRO.Nombre AS Nombre_Proveedor,
    SF.cuenta AS Cuenta,
    CTA.NOMBRE AS Nombre_Cuenta,
    SF.TipodeDocumento AS Tipo_de_Documento,
    DOCUXXXX.NOMBRE AS Nombre_Tipo_de_Documento,
    SF.Documento AS Documento,
    SF.concepto AS Concepto,
    SF.centroc AS Centro_de_Costo,
    CCO.NOMBRE AS Nombre_Centro_de_Costo,
    SF.factura AS Valor_Factura,
    SF.saldodoc AS Saldo_Factura,
    CAST(HEDATETOSTR(SF.fecha_vence,'yyyy/mm/dd') AS DATE) AS Fecha_Vencimiento,
    SF.mora AS Dias_Mora,
    SF.por_vencer AS Saldo_Por_Vencer,
    SF.cuentasxp1a30 AS C_X_Pagar_de_1_a_30_dias,
    SF.cuentasxp31a60 AS C_X_Pagar_de_31_a_60_dias,
    SF.cuentasxp61a90 AS C_X_Pagar_de_61_a_90_dias,
    SF.cuentasxp91a120 AS C_X_Pagar_de_91_a_120_dias,
    SF.cuentasxp121a150 AS C_X_Pagar_de_121_a_150_dias,
    SF.cuentasxpmayor90 AS C_X_Pagar_Mayor_a_90_dias,
    SF.cuentasxpmayor120 AS C_X_Pagar_Mayor_a_120_dias,
    SF.cuentasxpmayor150 AS C_X_Pagar_Mayor_a_150_dias,
    SF.cuentasxpmayor180 AS C_X_Pagar_Mayor_a_180_dias

FROM CEMA2019 CCO 
RIGHT OUTER JOIN (
    DOCUXXXX RIGHT OUTER JOIN (
        COMA2019 CTA
        LEFT JOIN cuentas_niif CTN ON CTA.cuenta_niif = CTN.cuenta 
        RIGHT OUTER JOIN (
            CPMA2019 PRO RIGHT OUTER JOIN (
                SELECT DF.*,
                    iif(DF.mora <= 0, DF.saldodoc, 0) AS por_vencer,
                    iif(DF.mora > 0 AND DF.mora <= 30, DF.saldodoc, 0) AS cuentasxp1a30,
                    iif(DF.mora > 30 AND DF.mora <= 60, DF.saldodoc, 0) AS cuentasxp31a60,
                    iif(DF.mora > 60 AND DF.mora <= 90, DF.saldodoc, 0) AS cuentasxp61a90,
                    iif(DF.mora > 90 AND DF.mora <= 120, DF.saldodoc, 0) AS cuentasxp91a120,
                    iif(DF.mora > 120 AND DF.mora <= 150, DF.saldodoc, 0) AS cuentasxp121a150,
                    iif(DF.mora > 90, DF.saldodoc, 0) AS cuentasxpmayor90,
                    iif(DF.mora > 120, DF.saldodoc, 0) AS cuentasxpmayor120,
                    iif(DF.mora > 150, DF.saldodoc, 0) AS cuentasxpmayor150,
                    iif(DF.mora > 180, DF.saldodoc, 0) AS cuentasxpmayor180
                FROM (
                    SELECT cp.*, 
                    CAST(EXTRACT(year FROM CAST('now' AS DATE)) || '/' || EXTRACT(month FROM CAST('now' AS DATE)) || '/' || lpad(EXTRACT(day FROM CAST('now' AS DATE)), 2, '0') AS DATE) - (hefechatofecha(cp.fecha_vence)) AS mora
                    FROM (
                        SELECT
                            HEDATETOSTR(estado.Fecha_Afecta,'yyyy') AS Ano,
                            HEDATETOSTR(estado.Fecha_Afecta,'yyyymm') AS Periodo,
                            HEDATETOSTR(estado.Fecha_Afecta,'mm/dd/yyyy') AS Fecha,
                            TRIM(pr.identidad) AS Nit,
                            estado.codigo_proveedor AS Proveedor,
                            estado.cuenta AS Cuenta,
                            SUBSTRING(estado.Documento_Afecta FROM 1 FOR 4) AS TipodeDocumento,
                            SUBSTRING(estado.Documento_Afecta FROM 5 FOR 20) AS Documento,
                            co.concepto,
                            iif(co.centro_activo = 'S', co.centro, '') AS centroc,
                            (SELECT MIN(a.fecha_vence) fvence
                             FROM cptrxxxx a 
                             WHERE a.documento = estado.documento_afecta
                                   AND a.fecha = estado.fecha_afecta
                                   AND a.cuota_afecta = estado.cuota_afecta
                                   AND a.ind_contabilidad = estado.indice_afecta) AS fecha_vence, 
                            estado.saldo AS saldodoc, 
                            co.valor AS factura
                        FROM (  
                            SELECT tr.Documento_Afecta, tr.Indice_Afecta, tr.Fecha_Afecta, tr.cuota_afecta,
                                   tr.codigo_proveedor, tr.cuenta, ROUND(SUM(tr.valor * claseasiento(tr.asiento))) AS saldo
                            FROM cptrxxxx tr
                            INNER JOIN cotrxxxx c ON c.indice_primario = tr.ind_contabilidad AND c.fecha = tr.fecha
                            WHERE (hefechatofecha(tr.fecha) <= EXTRACT(year FROM CAST('now' AS DATE)) || EXTRACT(month FROM CAST('now' AS DATE)) || lpad(EXTRACT(day FROM CAST('now' AS DATE)), 2, '0'))
                            GROUP BY tr.Documento_Afecta, tr.Indice_Afecta, tr.Fecha_Afecta, tr.cuota_afecta, tr.codigo_proveedor, tr.cuenta
                            HAVING ROUND(SUM(tr.valor * claseasiento(tr.asiento))) > 0
                        ) estado
                        LEFT JOIN coma2019 cu ON cu.cuenta = estado.cuenta
                        LEFT JOIN cpma2019 pr ON pr.codigo = estado.codigo_proveedor
                        LEFT JOIN cotrxxxx co ON co.fecha = estado.fecha_afecta AND co.ind_contabilidad = estado.indice_afecta
                    ) cp
                ) DF
            ) SF ON PRO.Codigo = SF.proveedor 
        ) ON CTA.CUENTA = SF.cuenta 
    ) ON DOCUXXXX.TIPO = SF.TipodeDocumento 
) ON CCO.CODIGO = SF.centroc;
