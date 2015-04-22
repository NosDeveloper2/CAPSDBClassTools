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
	SELECT @TableName = TableName,

		/*All columns as parameters*/
		@AllParams = COALESCE(@AllParams + ',' + @crlf + @tab 
						+ '@' + ColumnName + ' '
						+SqlServerDataType
							+CASE
								WHEN SqlServerDataType IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR', 'NUMERIC', 'DECIMAL')
									THEN CASE
											WHEN SqlServerDataType IN ('NUMERIC', 'DECIMAL') THEN '('+CONVERT(VARCHAR(25), [Precision]) + ',' + CONVERT(VARCHAR(25), Scale )+')'
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
											ELSE '('+CONVERT(VARCHAR(25), ColMaxLength)+')'
										END
								ELSE ''
							END
						),
		/*Key Parameters*/
		@KeyParams = CASE
						WHEN key_ordinal = 1
							THEN COALESCE(@KeyParams + ',' + @crlf + @tab 
									+ '@' + ColumnName + ' '
									+CASE
											WHEN SqlServerDataType IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR', 'NUMERIC', 'DECIMAL')
												THEN CASE
														WHEN SqlServerDataType IN ('NUMERIC', 'DECIMAL') THEN SqlServerDataType + '('+CONVERT(VARCHAR(25), [Precision]) + ',' + CONVERT(VARCHAR(25), Scale ) +')'
														ELSE SqlServerDataType + '('+CONVERT(VARCHAR(25), ColMaxLength)+')'
													END
											ELSE SqlServerDataType
										END,

									'@'+ColumnName + ' '
										+CASE
											WHEN SqlServerDataType IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR', 'NUMERIC', 'DECIMAL')
												THEN CASE
														WHEN SqlServerDataType IN ('NUMERIC', 'DECIMAL') THEN SqlServerDataType + '('+CONVERT(VARCHAR(25), [Precision]) + ',' + CONVERT(VARCHAR(25), Scale ) +')'
														ELSE SqlServerDataType + '('+CONVERT(VARCHAR(25), ColMaxLength)+')'
													END
											ELSE SqlServerDataType
										END
									)
						ELSE @KeyParams
					END,
		/*Set List*/
		@SetList = COALESCE(@SetList + ',' + @CRLF + @tab + 'CASE WHEN @'+ColumnName+' != T.['+ColumnName+'] THEN @'+ColumnName+' ELSE T.'+ColumnName+' END',
						'CASE WHEN @'+ColumnName+' != T.['+ColumnName+'] THEN @'+ColumnName+' ELSE T.'+ColumnName+' END'),
		/*Where List*/
		@WhereList = CASE
						WHEN key_ordinal = 1
							THEN COALESCE(
									@WhereList + @crlf + @tab + @tab + 'AND ' + ColumnName + ' = @' + ColumnName,
									ColumnName + ' = @' + ColumnName
								)
						ELSE @WhereList
					END,
		/*Column List*/
		@ColList = COALESCE(@ColList + ',' + @CRLF + @tab + ColumnName, ColumnName),
		/*Insert Parameters List*/
		@InsertParams = COALESCE(@InsertParams + ', @' + ColumnName, '@'+ColumnName)
	FROM @TableInfoList
	WHERE TableID = @listID


	/*
	-- Create definitions
	*/
	-- Delete Procedure
	SELECT @deleteProcDef = '
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

	-- Get Procedure
	SELECT @getProcDef = '
IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''proc_'+@TableName+'_Get'' AND ROUTINE_SCHEMA = ''dbo'')
BEGIN
	DROP PROCEDURE [dbo].[proc_'+@TableName+'_Get]
END
GO

CREATE PROCEDURE [dbo].[proc_'+@TableName+'_Get]
(
	'+@KeyParams+'
)AS
SET NOCOUNT ON

SELECT '+@ColList+'
FROM [dbo].['+@TableName+']
WHERE '+@WhereList+'
GO
'

	-- Get All Procedure
	SELECT @getallProcDef = '
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

	-- Insert Procedure
	SELECT @insertProcDef = '
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
	INSERT INTO [dbo].['+@TableName+']('+REPLACE(REPLACE(@ColList, @crlf, ' '), @tab, '')+')
	VALUES('+@InsertParams+')
END
GO
'

	-- Update Procedure
	SELECT @updateProcDef = '
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
	-- Insert definitions
	*/
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES('proc_'+@TableName+'_Delete', @deleteProcDef, 5) /*5==StoredProcedures*/
	
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
	--Clean Parameters for next iteration
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
END

SELECT *
FROM @Objects
