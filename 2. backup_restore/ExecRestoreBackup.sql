declare @backup_datetime datetime = convert(datetime, '2022-01-18 20:29:00', 20);
exec dbo.RestoreFromBackup @database='Northwind', @backup_date=@backup_datetime;