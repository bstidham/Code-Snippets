--======================================================================================================================
--    Action
--======================================================================================================================
IF OBJECT_ID('tempdb..#<SystemPrefix,,ADHOC>_Action', 'U') IS NOT NULL
    DROP TABLE #<SystemPrefix,,ADHOC>_Action 
;
CREATE TABLE #<SystemPrefix,,ADHOC>_Action (
      ActionID INT NOT NULL IDENTITY(1,1)
    -- entity
    , Entity SYSNAME NOT NULL
    , EntityID BIGINT NULL
    -- values
    , !TODO! 
    -- controls
    , ActionCode CHAR(1) NOT NULL
    , ActivityStatusCode CHAR(1) NOT NULL 
    , StatusMessage VARCHAR(100) NOT NULL 
    , Created_Date DATETIME NOT NULL DEFAULT (GETDATE())
    , Created_By VARCHAR(50) NOT NULL DEFAULT (LEFT(ORIGINAL_LOGIN(), 50))
    , Modified_Date DATETIME NULL
    , Modified_By VARCHAR(50) NULL
    -- keys
    , PRIMARY KEY (ActionID)
    , UNIQUE (Entity, EntityID, ActionCode)
    , CHECK (ActionCode IN ('', 'U', 'I', 'D', 'R'))
);
IF OBJECT_ID('tempdb..#<SystemPrefix,,ADHOC>_ActionsApplied', 'U') IS NOT NULL
    DROP TABLE #<SystemPrefix,,ADHOC>_ActionsApplied 
;
CREATE TABLE #ADHOC_ActionsApplied (
      ActionID INT NOT NULL 
    , PRIMARY KEY (ActionID)
);
