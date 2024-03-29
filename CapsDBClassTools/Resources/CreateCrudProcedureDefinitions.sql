DECLARE @crlf VARCHAR(10) = '
'
DECLARE @tab VARCHAR(9) = '	'
DECLARE @TableName VARCHAR(255)
DECLARE @filename VARCHAR(MAX)

DECLARE @ColList VARCHAR(MAX)
DECLARE @WhereList VARCHAR(MAX)
DECLARE @SetList VARCHAR(MAX)
DECLARE @KeyParams VARCHAR(MAX)
DECLARE @AllParams VARCHAR(MAX)
DECLARE @InsertParams VARCHAR(MAX)
DECLARE @InsertList VARCHAR(MAX)

DECLARE @deleteProcDef VARCHAR(MAX)
DECLARE @getProcDef VARCHAR(MAX)
DECLARE @getallProcDef VARCHAR(MAX)
DECLARE @insertProcDef VARCHAR(MAX)
DECLARE @updateProcDef VARCHAR(MAX)

DECLARE @listID INT
SELECT @listID = MAX(TableID)
FROM @TableInfoList

WHILE @listID > 0
BEGIN
	/*
	-- Create parameters
	*/
	SELECT 
		/*Tablename*/
		@TableName = TableName,
		/*All columns as parameters*/
		@AllParams = COALESCE(@AllParams + ',' + @crlf + @tab 
						+ '@' + ColumnName + ' '
						+SqlServerDataType
							+CASE
								WHEN SqlServerDataType IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR', 'NUMERIC', 'DECIMAL')
									THEN CASE
											WHEN SqlServerDataType IN ('NUMERIC', 'DECIMAL') THEN '('+CONVERT(VARCHAR(25), [Precision]) + ',' + CONVERT(VARCHAR(25), Scale )+')'
											WHEN ColMaxLength = -1 THEN '(MAX)'
											ELSE '('+CONVERT(VARCHAR(25), ColMaxLength)+')'
										END
								ELSE ''
							END,

						'@'+ColumnName + ' '
						+SqlServerDataType
							+CASE
								WHEN SqlServerDataType IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR', 'NUMERIC', 'DECIMAL')
									THEN CASE
											WHEN SqlServerDataType IN ('NUMERIC', 'DECIMAL') THEN '('+CONVERT(VARCHAR(25), [Precision]) + ',' + CONVERT(VARCHAR(25), Scale ) +')'
											WHEN ColMaxLength = -1 THEN '(MAX)'
											ELSE '('+CONVERT(VARCHAR(25), ColMaxLength)+')'
										END
								ELSE ''
							END
						),
		/*Column List*/
		@ColList = COALESCE(@ColList + ',' + @CRLF + @tab + ColumnName, ColumnName)
	FROM @TableInfoList
	WHERE TableID = @listID

	SELECT 
		/*Set List*/
		@SetList = COALESCE(@SetList + ',' + @CRLF + @tab + 'T.['+ColumnName+']  = CASE WHEN @'+ColumnName+' != T.['+ColumnName+'] THEN @'+ColumnName+' ELSE T.'+ColumnName+' END',
										'T.['+ColumnName+']  = CASE WHEN @'+ColumnName+' != T.['+ColumnName+'] THEN @'+ColumnName+' ELSE T.'+ColumnName+' END')
	FROM @TableInfoList
	WHERE TableID = @listID
		AND ISNULL(key_ordinal, 0) = 0

	SELECT
		/*Key Parameters*/
		@KeyParams = COALESCE(
						@KeyParams + ',' + @crlf + @tab 
						+ '@' + ColumnName + ' '
						+CASE
								WHEN SqlServerDataType IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR', 'NUMERIC', 'DECIMAL')
									THEN CASE
											WHEN SqlServerDataType IN ('NUMERIC', 'DECIMAL') THEN SqlServerDataType + '('+CONVERT(VARCHAR(25), [Precision]) + ',' + CONVERT(VARCHAR(25), Scale ) +')'
											WHEN ColMaxLength = -1 THEN '(MAX)'
											ELSE SqlServerDataType + '('+CONVERT(VARCHAR(25), ColMaxLength)+')'
										END
								ELSE SqlServerDataType
							END,

						'@'+ColumnName + ' '
							+CASE
								WHEN SqlServerDataType IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR', 'NUMERIC', 'DECIMAL')
									THEN CASE
											WHEN SqlServerDataType IN ('NUMERIC', 'DECIMAL') THEN SqlServerDataType + '('+CONVERT(VARCHAR(25), [Precision]) + ',' + CONVERT(VARCHAR(25), Scale ) +')'
											WHEN ColMaxLength = -1 THEN '(MAX)'
											ELSE SqlServerDataType + '('+CONVERT(VARCHAR(25), ColMaxLength)+')'
										END
								ELSE SqlServerDataType
							END
						),
		/*Where List*/
		@WhereList = COALESCE(
							@WhereList + @crlf + @tab + @tab + 'AND ' + ColumnName + ' = @' + ColumnName,
							ColumnName + ' = @' + ColumnName
						)
	FROM @TableInfoList
	WHERE TableID = @listID
		AND ISNULL(key_ordinal, 0) >= 1

	/*Cannot insert into identity column*/
	SELECT @InsertParams = COALESCE(@InsertParams + ', @' + ColumnName, '@'+ColumnName),
		@InsertList = COALESCE(@InsertList + ', ' + ColumnName, ColumnName)
	FROM @TableInfoList
	WHERE TableID = @listID
		AND is_identity = 0

	/*
	 Create definitions
	*/
	/*Delete Procedure*/
	SELECT @deleteProcDef = '
USE '+@Database+'
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''proc_'+@TableName+'_Delete'' AND ROUTINE_SCHEMA = ''dbo'')
BEGIN
	DROP PROCEDURE [dbo].[proc_'+@TableName+'_Delete]
END
GO

CREATE PROCEDURE [dbo].[proc_'+@TableName+'_Delete]
(
	'+@KeyParams+'
)
AS
SET NOCOUNT ON

DELETE [dbo].['+@TableName+']
WHERE '+@WhereList+'
GO
'

	/*Get Procedure*/
	SELECT @getProcDef = '
USE '+@Database+'
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''proc_'+@TableName+'_Get'' AND ROUTINE_SCHEMA = ''dbo'')
BEGIN
	DROP PROCEDURE [dbo].[proc_'+@TableName+'_Get]
END
GO

CREATE PROCEDURE [dbo].[proc_'+@TableName+'_Get]
(
	'+@KeyParams+'
)
AS
SET NOCOUNT ON

SELECT '+@ColList+'
FROM [dbo].['+@TableName+']
WHERE '+@WhereList+'
GO
'

	/* Get All Procedure*/
	SELECT @getallProcDef = '
USE '+@Database+'
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''proc_'+@TableName+'_GetAll'' AND ROUTINE_SCHEMA = ''dbo'')
BEGIN
	DROP PROCEDURE [dbo].[proc_'+@TableName+'_GetAll]
END
GO

CREATE PROCEDURE [dbo].[proc_'+@TableName+'_GetAll]
AS
SET NOCOUNT ON

SELECT '+@ColList+'
FROM [dbo].['+@TableName+']
GO
'

	/* Insert Procedure*/
	SELECT @insertProcDef = '
USE '+@Database+'
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''proc_'+@TableName+'_Insert'' AND ROUTINE_SCHEMA = ''dbo'')
BEGIN
	DROP PROCEDURE [dbo].[proc_'+@TableName+'_Insert]
END
GO

CREATE PROCEDURE [dbo].[proc_'+@TableName+'_Insert]
(
	'+@AllParams+'
)AS
SET NOCOUNT ON

IF NOT EXISTS(SELECT * FROM [dbo].['+@TableName+'] WHERE '+@WhereList+')
BEGIN
	INSERT INTO [dbo].['+@TableName+']('+@InsertList+')
	VALUES('+@InsertParams+')
END
GO
'

	/* Update Procedure*/
	SELECT @updateProcDef = '
USE '+@Database+'
GO
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''proc_'+@TableName+'_Update'' AND ROUTINE_SCHEMA = ''dbo'')
BEGIN
	DROP PROCEDURE [dbo].[proc_'+@TableName+'_Update]
END
GO

CREATE PROCEDURE [dbo].[proc_'+@TableName+'_Update]
(
	'+@AllParams+'
)AS
SET NOCOUNT ON

UPDATE T
SET '+@SetList+'
FROM [dbo].['+@TableName+'] T
WHERE '+@WhereList+'
GO
'


	/*
	Insert definitions
	*/

	/*
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES('proc_'+@TableName+'_Delete', @deleteProcDef, 5) /*5==StoredProcedures*/
	*/
	
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES('proc_'+@TableName+'_Get', @getProcDef, 5) /*5==StoredProcedures*/
	
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES('proc_'+@TableName+'_GetAll', @getallProcDef, 5) /*5==StoredProcedures*/
	
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES('proc_'+@TableName+'_Insert', @insertProcDef, 5) /*5==StoredProcedures*/
	
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES('proc_'+@TableName+'_Update', @updateProcDef, 5) /*5==StoredProcedures*/

	/*
	Print out results (testing)
	*/

	exec master.dbo.PrintMaxString @deleteProcDef
	exec master.dbo.PrintMaxString @getProcDef
	exec master.dbo.PrintMaxString @getallProcDef
	exec master.dbo.PrintMaxString @insertProcDef
	exec master.dbo.PrintMaxString @updateProcDef


	/*
	Clean Parameters for next iteration
	*/
	SET @listID -= 1

	SET @deleteProcDef = NULL
	SET @getProcDef = NULL
	SET @getallProcDef = NULL
	SET @insertProcDef = NULL
	SET @updateProcDef = NULL
	SET @InsertParams = NULL

	SET @ColList = NULL
	SET @TableName = NULL
	SET @WhereList = NULL
	SET @KeyParams = NULL
	SET @AllParams = NULL
    SET @SetList = NULL
	SET @InsertList = NULL
END

SELECT *
FROM @Objects