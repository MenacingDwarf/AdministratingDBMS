SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Markin Stanislav
-- Create date: 18.01.2022
-- Description:	Restoring the database from the last backup
-- =============================================
CREATE PROCEDURE RestoreFromBackup 
	@database varchar(100) = 'database',
	@backup_date datetime = NULL
AS
BEGIN
	DECLARE @backups_dir varchar(100) = 'C:\Users\Menac\Documents\Backups\';
	DECLARE @last_full_backup_path varchar(100) = NULL;
	DECLARE @last_backup_path varchar(100) = NULL;
	IF @backup_date IS NULL SET @backup_date = GETDATE();

	-- Collect backup files names
	IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
      DROP TABLE #DirectoryTree;
	CREATE TABLE #DirectoryTree (
		   id int IDENTITY(1,1)
		  ,subdirectory nvarchar(512)
		  ,depth int
		  ,isfile bit);
	INSERT #DirectoryTree (subdirectory,depth,isfile)
	EXEC master.sys.xp_dirtree 'C:\Users\Menac\Documents\Backups\',1,1;

	-- Find last backup path
	SELECT @last_backup_path = CONCAT(@backups_dir, subdirectory)
	FROM (
	SELECT 
		subdirectory, 
		database_name, 
		backup_type, 
		event_date, 
		DATEDIFF(SECOND, event_date, @backup_date) as diff, 
		min(DATEDIFF(SECOND, event_date, @backup_date)) over() as min_diff
	FROM (
		SELECT
		subdirectory,
		PARSENAME(subdirectory, 4) AS 'database_name',
		PARSENAME(subdirectory, 3) AS 'backup_type',
		CONVERT(datetime, REPLACE(PARSENAME(subdirectory, 2), '_', ':'), 20) AS 'event_date'
		FROM #DirectoryTree
		WHERE isfile = 1 AND RIGHT(subdirectory, 4) = '.BAK' 
	) t
	WHERE database_name = @database and event_date < @backup_date
	) t2
	where diff = min_diff

	-- Find last full backup path
	SELECT @last_full_backup_path = CONCAT(@backups_dir, subdirectory)
	FROM (
	SELECT 
		subdirectory, 
		database_name, 
		backup_type, 
		event_date, 
		DATEDIFF(SECOND, event_date, @backup_date) as diff, 
		min(DATEDIFF(SECOND, event_date, @backup_date)) over() as min_diff
	FROM (
		SELECT
		subdirectory,
		PARSENAME(subdirectory, 4) AS 'database_name',
		PARSENAME(subdirectory, 3) AS 'backup_type',
		CONVERT(datetime, REPLACE(PARSENAME(subdirectory, 2), '_', ':'), 20) AS 'event_date'
		FROM #DirectoryTree
		WHERE isfile = 1 AND RIGHT(subdirectory, 4) = '.BAK' 
	) t
	WHERE database_name = @database and event_date < @backup_date and backup_type = 'full'
	) t2
	where diff = min_diff

	-- Restore from backup if exist
	if @last_full_backup_path is NULL select 'NO BACKUPS BEFORE THAT DATE!' as ERROR_MESSAGE;
	else
	begin
		if @last_full_backup_path = @last_backup_path
		begin
			RESTORE DATABASE @database
			FROM
			DISK = @last_backup_path
			WITH
			RECOVERY;

			select @last_backup_path;
		end;
		else
		begin
			RESTORE DATABASE @database
			FROM
			DISK = @last_full_backup_path
			WITH
			NORECOVERY;

			RESTORE DATABASE @database
			FROM
			DISK = @last_backup_path
			WITH
			RECOVERY;

			select @last_backup_path;
		end;
	end;
END
GO
