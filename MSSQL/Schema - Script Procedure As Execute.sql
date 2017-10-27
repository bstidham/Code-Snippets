USE <Database,SYSNAME,CLIENT>;
; WITH D1 AS (
SELECT ProcedureSchema = OBJECT_SCHEMA_NAME(so.object_id) 
     , ProcedureName = OBJECT_NAME(so.object_id)
     , ParameterID = sp.parameter_id
     , ParameterName = sp.name
     , ParameterMaxLength = sp.max_length
     , ParameterPrecision = sp.precision
     , ParameterIsOut = sp.is_output
     , TypeName = st.name
FROM (SELECT SearchSchema = '<procedure schema, SYSNAME,dbo>'
           , SearchProcedure = '<procedure name,SYSNAME,>') p 
JOIN SYS.objects so
    ON  OBJECT_SCHEMA_NAME(so.object_id) = p.SearchSchema
    AND OBJECT_NAME(so.object_id) = p.SearchProcedure
    AND so.type_desc = 'SQL_STORED_PROCEDURE'
JOIN sys.parameters sp
    ON sp.object_id = so.object_id
JOIN sys.types st
    ON  st.system_type_id = sp.system_type_id
)
, D2 AS (
    SELECT DISTINCT d.ProcedureSchema, d.ProcedureName
    FROM D1 d
)
SELECT 'DECLARE '
     + STUFF((
        SELECT CHAR(10) + '      ' + CASE WHEN sp.ParameterID = 1 THEN ' ' ELSE  ',' END --    [, ]
             + ' ' + sp.ParameterName + ' ' + UPPER(sp.TypeName)  -- @parameter TYPE
             + CASE WHEN sp.ParameterPrecision = 0 AND sp.ParameterMaxLength > 0 THEN REPLACE(' (max_length)', 'max_length', sp.ParameterMaxLength) ELSE '' END --(max_length)
             + ' = ' AS [text()]
        FROM D1 sp
        ORDER BY sp.ParameterID
        FOR XML PATH('')), 1, 9, '')
     + CHAR(10) + ';' + CHAR(10) + CHAR(10)
     + 'EXEC ' + so.ProcedureSchema + '.' + so.ProcedureName --EXEC Schema.Procedure
     + (SELECT CHAR(10) + '    ' + CASE WHEN sp.ParameterID = 1 THEN ' ' ELSE  ',' END --    [, ]
             + ' ' + sp.ParameterName + ' = ' + sp.ParameterName -- @parameter = @parameter
             + CASE WHEN sp.ParameterIsOut = 1 THEN ' OUT' ELSE '' END -- OUT
              AS [text()]
        FROM D1 sp
        ORDER BY sp.ParameterID
        FOR XML PATH(''))
     + CHAR(10) + ';'
FROM D2 so;
