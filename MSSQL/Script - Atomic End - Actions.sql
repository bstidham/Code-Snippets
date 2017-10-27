--======================================================================================================================
--    ATOMIC END
--======================================================================================================================
IF EXISTS (
    SELECT *
    FROM #<SystemPrefix,,ADHOC>_parm p 
    JOIN #<SystemPrefix,,ADHOC>_Action a
        ON  a.ActivityStatusCode <> p.ASC_Complete
)
BEGIN -- CRITICAL EXCEPTION THROWN HERE
	RAISERROR('INFO: %s: Transaction rolled back - incomplete actions exist', 11, 1, @procName) WITH NOWAIT;
	ROLLBACK;
END ELSE BEGIN
	RAISERROR('INFO: %s: Transaction committed', 0, 1, @procName) WITH NOWAIT;
	COMMIT;
END
