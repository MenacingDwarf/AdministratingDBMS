SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Markin Stanislav
-- Create date: 17.01.2022
-- Description:	
-- =============================================
CREATE PROCEDURE GetAllPermissions 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select TABLE_NAME, permission_name
	from INFORMATION_SCHEMA.TABLES
	cross join fn_my_permissions(NULL, 'DATABASE')
	WHERE TABLE_TYPE = 'BASE TABLE'
	AND HAS_PERMS_BY_NAME(TABLE_NAME, 'OBJECT', permission_name) = 1;
END
GO
