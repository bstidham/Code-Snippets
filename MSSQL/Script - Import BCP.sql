--======================================================================================================================
--    Preload
--======================================================================================================================
SELECT @stmt = REPLACE(REPLACE('
IF OBJECT_ID(`\${PreloadTable}`, `U`) IS NOT NULL
    DROP TABLE \${PreloadTable}
;
CREATE TABLE \${PreloadTable} (
      PreloadID INT NOT NULL IDENTITY(1,1)
    -- LoanList values
    , loan_number VARCHAR(50) NOT NULL
    -- LoanList controls
    , ActivityStatusCode CHAR(1) NOT NULL DEFAULT `A`
    , Created_Date DATETIME NOT NULL DEFAULT (GETDATE())
    , Created_By VARCHAR(50) NOT NULL DEFAULT (LEFT(ORIGINAL_LOGIN(), 50))
    , Modified_Date DATETIME NULL
    , Modified_By VARCHAR(50) NULL

    , PRIMARY KEY (PreloadID)
    , UNIQUE (loan_number)
);', '\${PreloadTable}', ap.PreloadTable)
   , '`', '''')
FROM #ADHOC_parm ap
;
PRINT @stmt;
EXEC (@stmt);

RAISERROR('INFO: %s: Loading SCRATCH.M00<Mantis,INT,>_<System Prefix,VARCHAR,ADHOC>_Preload', 0, 1, @procName) WITH NOWAIT;
SET @start = GETDATE();

SELECT @cmd 
    = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            'BCP \${DB_NAME}.\${PreloadTable} \
             IN "\${InputFile}" \
             -S "\${SERVER_NAME}" \
             -f "\${InputFormatFile}" \
             -T \
             -b5000 \
             -F2 \
             -q'
          , '\${DB_NAME}', DB_NAME())
          , '\${SERVER_NAME}', @@SERVERNAME)
          , '\${InputFile}', ap.InputFile)
          , '\${InputFormatFile}', ap.InputFormatFile)
          , '\${PreloadTable}', ap.PreloadTable)
FROM #ADHOC_parm ap
;
PRINT @cmd;
IF @pDebug = 1 EXEC sys.xp_cmdshell @cmd;
IF @pDebug = 0 EXEC sys.xp_cmdshell @cmd, no_output;
SELECT @stmt = REPLACE('SELECT @cnt = count(*) FROM \${PreloadTable};', '\${PreloadTable}', ap.PreloadTable) FROM #ADHOC_parm ap;
PRINT @stmt;
EXEC sp_executesql @stmt, N'@cnt INT OUT', @cnt = @cnt OUT;
SET @span = DATEDIFF(MILLISECOND, @start, GETDATE());
RAISERROR('INFO: %s: %d rows loaded into SCRATCH.M00<Mantis,INT,>_<System Prefix,VARCHAR,ADHOC>_Preload in %dms', 0, 1, @procName, @cnt, @span) WITH NOWAIT;

/* LoanList.fmt
9.0
1
1       SQLCHAR       0       200     "\r\n"     2     loan_number                          SQL_Latin1_General_CP1_CI_AS

*/

--======================================================================================================================
--    
--======================================================================================================================
IF @pMessageLevel >= 1 RAISERROR('INFO: %s: ', 0, 1, @procName) WITH NOWAIT;
SET @start = GETDATE();
SELECT @stmt = REPLACE('SELECT * FROM \${PreloadTable};', '\${PreloadTable}', ap.PreloadTable) FROM #ADHOC_parm ap;
PRINT @stmt;
EXEC (@stmt);
SET @cnt = @@ROWCOUNT;
SET @span = DATEDIFF(MILLISECOND, @start, GETDATE());
IF @pMessageLevel >= 1 RAISERROR('INFO: %s: %d  in %dms', 0, 1, @procName, @cnt, @span) WITH NOWAIT;
