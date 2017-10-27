USE CTWP_<DBEnvironment,SYSNAME,DEVL>;

BEGIN TRAN;
--commit
--rollback
UPDATE tgt 
SET password = src.password
-- USE CTWP_<DBEnvironment,SYSNAME,DEVL>; SELECT src.password, tgt.password
FROM (
    SELECT SourceUsername = 'bstidham'
         , TargetUsername = '<TargetUsername,VARCHAR,>'
) p
JOIN dbo.mantis_user_table src 
    ON  src.username = p.SourceUsername
JOIN dbo.mantis_user_table tgt
    ON  tgt.username = p.TargetUsername
;
