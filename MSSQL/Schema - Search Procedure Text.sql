USE <db,SYSNAME,CLIENT>;
SELECT ObjectSchemaName = OBJECT_SCHEMA_NAME(so.object_id)
     , ObjectName = OBJECT_NAME(so.object_id)
     , ObjectType = so.type_desc
FROM (SELECT SearchTermMask = '%<search term,,>%') p 
JOIN SYS.objects so
    ON  OBJECT_DEFINITION(so.object_id) LIKE p.SearchTermMask 
ORDER BY ObjectSchemaName, ObjectName
;
