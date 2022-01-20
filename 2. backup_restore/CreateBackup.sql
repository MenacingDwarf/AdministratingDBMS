SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Markin Stanislav
-- Create date: 17.01.2022
-- Description:	Creating a database backup for further recovery from it
-- =============================================
CREATE PROCEDURE CreateDatabaseBackup 
	@database varchar(100) = 'database'
AS
BEGIN
	DECLARE @backups_dir varchar(100) = 'C:\Users\Menac\Documents\Backups\'
	DECLARE @last_full_date datetime = GETDATE()

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

	-- Find last full backup datetime
	SELECT @last_full_date = max(BACKUP_DATE)
	  FROM (
		SELECT
		  PARSENAME(subdirectory, 4) AS BACKUP_DB,
		  PARSENAME(subdirectory, 3) AS BACKUP_TYPE,
		  CONVERT(datetime, REPLACE(PARSENAME(subdirectory, 2), '_', ':'), 20) AS BACKUP_DATE
		FROM #DirectoryTree
		WHERE isfile = 1 AND RIGHT(subdirectory, 4) = '.BAK'
	  ) t
	  WHERE BACKUP_TYPE = 'full'
	  AND BACKUP_DB = @database

	-- Create backup: full or differencial
	declare @backup_path varchar(100);
	if @last_full_date is NULL OR DATEDIFF(day, @last_full_date, GETDATE()) > 7
	begin
	-- Full backup
		set @backup_path = CONCAT(@backups_dir, @database, '.', 'full', '.', REPLACE(convert(varchar, GETDATE(), 20), ':', '_'), '.bak');
		BACKUP DATABASE @database
		TO
		DISK = @backup_path
		WITH INIT;
	end;
	else
	begin
	-- Differential backup
		set @backup_path = CONCAT(@backups_dir, @database, '.', 'diff', '.', REPLACE(convert(varchar, GETDATE(), 20), ':', '_'), '.bak');
		BACKUP DATABASE @database
		TO
		DISK = @backup_path
		WITH DIFFERENTIAL, INIT;
	end;
	
	-- Print path of new backup
	select CONCAT(@backup_path);
END
GO
