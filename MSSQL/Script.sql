USE <Database,SYSNAME,>;

DECLARE @server SYSNAME
      , @db SYSNAME
      , @user VARCHAR(50)
      , @time VARCHAR(50)
;
SELECT @server = UPPER(@@SERVERNAME)
     , @db = UPPER(DB_NAME())
     , @user = UPPER(LEFT(ORIGINAL_LOGIN(), 50))
     , @time = UPPER(GETDATE())
;
RAISERROR('
/***********************************************************************************************************************
Purpose:
-------
Update the Payee information on the target payee row
Used in the payee restatement process

Usage:
-----
F5
 
Notes:
-----
Ran from server [%s], db [%s], by [%s], at [%s]


Revision History:
----------------
Rev 00 - DD MMM YYYY - bill stidham - bstidham@pfic.com
       - M(<Mantis,INT,00000>)
       - https://hq-fsapp01.pfi.com/!/#DataStatus/view/head/MaintenanceScripts/M00<Mantis,INT,00000>
       - description
***********************************************************************************************************************/
', 0, 1, @server, @db, @user, @time) WITH NOWAIT;

--======================================================================================================================
--    presets
--======================================================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--======================================================================================================================
--    variables
--======================================================================================================================
DECLARE @cnt INT
      , @start DATETIME
      , @span INT
      , @stmt NVARCHAR(MAX)
      , @cmd VARCHAR(8000)
      , @procName SYSNAME
      , @expected INT
      , @resultsPrefix VARCHAR(16)
      , @systemPrefix VARCHAR(16)
      , @pPFI_Client_ID INT
      , @pBatchID INT 
      , @pDebug BIT
      , @pGenerateReports BIT
      , @pDoApply BIT
      , @pMessageLevel INT
;

SELECT @procName = '[script]'
     , @expected = -1
     , @pDebug = 0
     , @pGenerateReports = 1
     , @pDoApply = 0
     , @resultsPrefix = ''
     , @systemPrefix = 'ADHOC'
     , @pMessageLevel = 1
;

--======================================================================================================================
--    #parm
--======================================================================================================================
IF OBJECT_ID('tempdb..#ADHOC_parm', 'u') IS NOT NULL
    DROP TABLE #ADHOC_parm
;
CREATE TABLE #ADHOC_parm (
      ParmID INT NOT NULL IDENTITY(1,1)
    -- parm values
    , AnalysisDate DATETIME NOT NULL
    , pfi_client_id INT NOT NULL
    , loan_number VARCHAR(50) NOT NULL
    , InputFile VARCHAR(1024) NOT NULL
    , InputFormatFile VARCHAR(1024) NOT NULL
    , PreloadTable SYSNAME NOT NULL
    -- parm constants
    , MantisID INT NOT NULL
    , TrackingText AS CONVERT(VARCHAR(50), REPLACE(REPLACE('M(${MantisID}) ${USER}', '${MantisID}', MantisID), '${USER}', ORIGINAL_LOGIN()))
    , ASC_Pending AS CONVERT(CHAR(1), 'P') PERSISTED
    , ASC_Active AS CONVERT(CHAR(1), 'A') PERSISTED
    , ASC_Error AS CONVERT(CHAR(1), 'E') PERSISTED
    , ASC_Inactive AS CONVERT(CHAR(1), 'I') PERSISTED
    , ASC_Complete AS CONVERT(CHAR(1), 'C') PERSISTED
    , AC_Update AS CONVERT(CHAR(1), 'U') PERSISTED
    , AC_Insert AS CONVERT(CHAR(1), 'I') PERSISTED
    , AC_Deactivate AS CONVERT(CHAR(1), 'D') PERSISTED
    , AC_Reactivate AS CONVERT(CHAR(1), 'R') PERSISTED
    , AC_None AS CONVERT(CHAR(1), '-') PERSISTED
    , CT_unk AS (CONVERT(INT, 0)) PERSISTED
    , CT_iim AS (CONVERT(INT, 2)) PERSISTED
    , CT_ess AS (CONVERT(INT, 3)) PERSISTED
    , FZ_Mandatory AS (CONVERT(VARCHAR, '[AV]%')) PERSISTED
    , COSC_Unknown AS (CONVERT(CHAR(1), '')) PERSISTED
    , COSC_Invalid AS (CONVERT(CHAR(1), '_')) PERSISTED
    , COSC_Vacant AS (CONVERT(CHAR(1), 'N')) PERSISTED
    , COSC_Occupied AS (CONVERT(CHAR(1), 'Y')) PERSISTED

    , PRIMARY KEY (ParmID)
    , UNIQUE (pfi_client_id, loan_number)
);

IF @pMessageLevel >= 1 RAISERROR('INFO: %s: Loading #parm', 0, 1, @procName) WITH NOWAIT;
SET @start = GETDATE();
INSERT INTO #ADHOC_parm (MantisID, AnalysisDate, pfi_client_id, loan_number, InputFile, InputFormatFile, PreloadTable) 
SELECT  MantisID = <Mantis,INT,00000>
      , AnalysisDate = ISNULL(CONVERT(DATETIME, NULLIF(<AnalysisDate, DATETIME, ''>, '')), DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE())))
      , pfi_Client_id = <pfi_client_id,INT,>
      , loan_number = '<loan_number,VARCHAR,>'
      , InputFile = REPLACE('<input file,SYSNAME,\\hq-community01\ArchiveCurrent\Mantis\I${MantisID}\Preload.txt>'
                          , '${MantisID}', RIGHT('0000000' + CONVERT(VARCHAR(7), @pMantisID), 7))
      , InputFormatFile = REPLACE('<input format file,SYSNAME,\\hq-community01\ArchiveCurrent\Mantis\I${MantisID}\Preload.fmt>'
                                , '${MantisID}', RIGHT('0000000' + CONVERT(VARCHAR(7), @pMantisID), 7))
      , PreloadTable = REPLACE(REPLACE('SCRATCH.${ResultsPrefix}_${SystemPrefix}_Preload'
                                                  , '${ResultsPrefix}', @resultsPrefix)
                                                  , '${SystemPrefix}', @systemPrefix)
;
SELECT @cnt = count(*) FROM #ADHOC_parm;
SELECT @resultsPrefix = ISNULL(ISNULL(  NULLIF(@resultsPrefix, '')
                                      , 'M' + RIGHT(REPLICATE('0', 7) + CONVERT(VARCHAR(7), MantisID), 7)), '') 
FROM #ADHOC_parm;
SET @span = DATEDIFF(MILLISECOND, @start, GETDATE());
IF @pMessageLevel >= 1 RAISERROR('INFO: %s: %d rows loaded into #parm in %dms', 0, 1, @procName, @cnt, @span) WITH NOWAIT;

--======================================================================================================================
--    
--======================================================================================================================
IF @pMessageLevel >= 1 RAISERROR('INFO: %s: ?', 0, 1, @procName) WITH NOWAIT;
SET @start = GETDATE();
SELECT * 
FROM #ADHOC_parm p
--JOIN 
ORDER BY p.ParmID
;
SET @cnt = @@ROWCOUNT;
SET @span = DATEDIFF(MILLISECOND, @start, GETDATE());
IF @pMessageLevel >= 1 RAISERROR('INFO: %s: %d ? in %dms', 0, 1, @procName, @cnt, @span) WITH NOWAIT;


--======================================================================================================================
--    postsets
--======================================================================================================================

SET NOCOUNT OFF;
