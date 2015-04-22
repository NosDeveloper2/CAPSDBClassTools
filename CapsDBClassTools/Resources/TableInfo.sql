/*
DECLARE @NameSpace VARCHAR(255) = 'Pros.Model',--My Default
	@IndividualTable VARCHAR(255) = NULL, -- Leave Null For all Tables
	@References VARCHAR(255) = NULL,
	@Database VARCHAR(50) = NULL,
	@ExcludeTables VARCHAR(2018) = null
*/
SET NOCOUNT ON

SELECT @IndividualTable = CASE @IndividualTable WHEN '' THEN NULL ELSE @IndividualTable END, -- Leave Null For all Tables
	@References = CASE @References WHEN '' THEN NULL ELSE @References END

DECLARE @tableinfo VARCHAR(MAX) = '
	SELECT 
		T.TableID,
		C.ORDINAL_POSITION AS ColOrdinal,
		T.TABLE_NAME,
		C.COLUMN_NAME,
		CASE WHEN c.IS_NULLABLE = ''NO'' THEN 0 ELSE 1 END AS Col_is_Nullable,
		CLR.DotNetNullable AS NullableDotNetType,
		CLR.DotNetCLRDataType,
		CLR.SqlServerDataType,
		CLR.SQLDbTypeEnum,
		C.CHARACTER_MAXIMUM_LENGTH AS ColMaxLength,
		CLR.[Precision],
		CLR.Scale,
		ixc.key_ordinal
	FROM (
		SELECT TOP 100 PERCENT
			ROW_NUMBER() OVER(ORDER BY TABLE_NAME DESC) AS TableID,
			TABLE_NAME
		FROM '+@Database+'.INFORMATION_SCHEMA.TABLES
		WHERE TABLE_TYPE = ''BASE TABLE''
			'+
			CASE
				WHEN @IndividualTable IS NOT NULL
					THEN 'AND TABLE_NAME = COALESCE('''+@IndividualTable+''', TABLE_NAME)'
				ELSE ''
			END
			+'
			'+
			CASE
				WHEN @ExcludeTables IS NOT NULL
					THEN 'AND TABLE_NAME NOT IN ('+@ExcludeTables+')'
				ELSE ''
			END
			+'
		ORDER BY TABLE_NAME DESC
	) AS T
	INNER JOIN '+@Database+'.INFORMATION_SCHEMA.COLUMNS C
		ON T.TABLE_NAME = C.TABLE_NAME
	INNER JOIN '+@Database+'.sys.tables sT
		ON T.TABLE_NAME = sT.name
	INNER JOIN #CLRDataTypes CLR
		ON C.DATA_TYPE = CLR.SqlServerDataType
	INNER JOIN '+@Database+'.sys.columns sC
		ON sT.object_id = sC.object_id
			AND C.COLUMN_NAME = sC.name
	LEFT OUTER JOIN '+@Database+'.sys.key_constraints KC
		ON sT.object_id = KC.parent_object_id
			AND KC.type = ''PK''
	LEFT OUTER JOIN '+@Database+'.sys.index_columns IXC
		ON KC.parent_object_id = IXC.object_id
			AND KC.unique_index_id = IXC.index_id
			AND sC.column_id = IXC.column_id
	ORDER BY T.TableID, C.ORDINAL_POSITION
'
IF (SELECT OBJECT_ID('tempdb..#CLRDataTypes')) IS NOT NULL
BEGIN
	DROP TABLE #CLRDataTypes
END
CREATE TABLE #CLRDataTypes
(
	DataTypeID INT,
	SqlServerDataType VARCHAR(255),
	SQLDbTypeEnum VARCHAR(255),
	DotNetCLRDataType VARCHAR(255),
	DotNetNullable BIT,
	[MaxLength] INT,
	[Precision] INT,
	Scale INT
)
INSERT INTO #CLRDataTypes
VALUES(1,'BIGINT','BigInt','Int64',1,8,19,0),
(2,'BINARY','Binary','Byte[]',0,8000,0,0),
(3,'BIT','Bit','Boolean',1,1,1,0),
(4,'CHAR','Char','String',1,8000,0,0),
(5,'DATE','Date','DateTime',1,3,10,0),
(6,'DATETIME','DateTime','DateTime',1,8,23,3),
(7,'DATETIME2','DateTime2','DateTime',1,8,27,7),
(8,'DATETIMEOFFSET','DateTimeOffset','DateTimeOffset',1,10,34,7),
(9,'DECIMAL','Decimal','Decimal',1,17,38,38),
(10,'FLOAT','Float','Double',1,8,53,0),
(11,'IMAGE','Image','Byte[]',0,16,0,0),
(12,'INT','Int','Int32',1,4,10,0),
(13,'MONEY','Money','Decimal',1,8,19,4),
(14,'NCHAR','NChar','String',1,8000,0,0),
(15,'NTEXT','NText','Byte[]',0,16,0,0),
(16,'NUMERIC','Decimal','Decimal',1,17,38,38),
(17,'NVARCHAR','NVarChar','String',1,8000,0,0),
(18,'REAL','Real','Single',1,4,24,0),
(19,'SMALLINT','SmallInt','Int16',1,2,5,0),
(20,'SQL_VARIANT','Variant','Object',0,8016,0,0),
(21,'TEXT','Text','Byte[]',0,16,0,0),
(22,'TIME','Time','TimeSpan',1,5,16,7),
(23,'TIMESTAMP','Timestamp','',0,8,0,0),
(24,'TINYINT','TinyInt','Byte',1,1,3,0),
(25,'UNIQUEIDENTIFIER','UniqueIdentifier','Guid',0,16,0,0),
(26,'VARBINARY','VarBinary','Byte[]',0,8000,0,0),
(27,'VARCHAR','VarChar','String',1,8000,0,0),
(28,'XML','Xml','String',0,-1,0,0),
(29,'Geography','','',1,0,0,0),
(30,'Geometry','','',1,0,0,0)

DECLARE @Objects TABLE
(
	ObjectId INT IDENTITY(1,1),
	ObjectName NVARCHAR(255),
	ObjectDefinition NVARCHAR(MAX),
	ObjectType INT
)
DECLARE @TableInfoList TABLE
(
	TableID INT,
	ColOrdinal INT,
	TableName VARCHAR(255),
	ColumnName VARCHAR(255),
	Col_Is_Nullable BIT,
	NullableDotNetType BIT,
	DotNetCLRDataType VARCHAR(255),
	SqlServerDataType VARCHAR(255),
	SQLDbTypeEnum VARCHAR(255),
	ColMaxLength INT,
	[Precision] INT,
	Scale INT,
	Key_Ordinal INT
)
INSERT INTO @TableInfoList
EXEC(@tableinfo)