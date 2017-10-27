--======================================================================================================================
--    ATOMIC END
--======================================================================================================================
IF @cnt = @expected
BEGIN -- CRITICAL EXCEPTION THROWN HERE
  RAISERROR('INFO: %s: Transaction committed', 0, 1, @procName) WITH NOWAIT;
  COMMIT;
END ELSE BEGIN
  RAISERROR('INFO: %s: Transaction rolled back - unexpected count', 11, 1, @procName) WITH NOWAIT;
  ROLLBACK;
END
