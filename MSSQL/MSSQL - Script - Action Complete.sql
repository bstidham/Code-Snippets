--======================================================================================================================
--    Actions - Complete
--======================================================================================================================
IF @pMessageLevel >= 2 RAISERROR('INFO: %s: Completing actions', 0, 1, @procName) WITH NOWAIT;
SET @start = CURRENT_TIMESTAMP;
UPDATE a
SET ActivityStatusCode = p.ASC_Complete 
  , StatusMessage = 'Action complete'
  , Modified_Date = GETDATE()
  , Modified_By = p.TrackingText
FROM #<SystemPrefix,,ADHOC>_parm p
CROSS JOIN #<SystemPrefix,,ADHOC>_ActionsApplied aa
JOIN #<SystemPrefix,,>_Action a 
    ON  a.ActionID = aa.ActionID
;
SET @cnt = @@ROWCOUNT;
SET @span = DATEDIFF(MILLISECOND, @start, CURRENT_TIMESTAMP);
IF @pMessageLevel >= 2 RAISERROR('INFO: %s: %d actions completed in %dms', 0, 1, @procName, @cnt, @span) WITH NOWAIT
;
