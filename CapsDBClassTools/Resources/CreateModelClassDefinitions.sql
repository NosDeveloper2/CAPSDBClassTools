
DECLARE @crlf VARCHAR(10) = '
'
DECLARE @tab VARCHAR(9) = '	'
DECLARE @filename VARCHAR(MAX)
DECLARE @Class VARCHAR(MAX)
DECLARE @ColList VARCHAR(MAX)
DECLARE @GetList VARCHAR(MAX)
DECLARE @GetParms VARCHAR(MAX)
DECLARE @TableName VARCHAR(255)
DECLARE @listID INT
SELECT @listID = MAX(TableID)
FROM @TableInfoList

WHILE @listID > 0
BEGIN
	SELECT @TableName = TableName,
		@GetParms  = CASE
						WHEN key_ordinal IS NOT NULL
							THEN COALESCE(
								@GetParms + ', '+DotNetCLRDataType+' '+ColumnName,
								DotNetCLRDataType+' '+ColumnName
							)
						ELSE @GetParms
					END,
		@GetList = CASE
						WHEN key_ordinal IS NOT NULL
							THEN COALESCE(
								@GetList + ', new DbParameter("'+ColumnName+'", DbDirection.Input, SqlDbType.'+SQLDbTypeEnum+', '+ColumnName+')',
								'new DbParameter("'+ColumnName+'", DbDirection.Input, SqlDbType.'+SQLDbTypeEnum+', '+ColumnName+')'
							)
						ELSE @GetList
					END,
		@ColList = COALESCE(
						@ColList + @CRLF + @CRLF + @tab + @tab + 
						CASE WHEN Key_Ordinal = 1 THEN '[DBKeyField("' ELSE '[DBField("' END 
						+ColumnName
						+'", typeof('+DotNetCLRDataType+'), SqlDbType.'+SQLDbTypeEnum+')]'
						+ @CRLF + @tab + @tab +'public '+DotNetCLRDataType+' '+ColumnName+' { get; set; }',
						
						CASE WHEN Key_Ordinal = 1 THEN '[DBKeyField("' ELSE '[DBField("' END +
						ColumnName
						+'", typeof('+DotNetCLRDataType+'), SqlDbType.'+SQLDbTypeEnum+')]'
						+ @CRLF + @tab + @tab +'public '+DotNetCLRDataType+' '+ColumnName+' { get; set; }'
					)
	FROM @TableInfoList
	WHERE TableID = @listID

	SELECT @Class = '
using System;
using System.Collections.Generic;
using System.Data;
'+ISNULL(@References, '')+'

namespace '+@NameSpace+'.Model
{	
	[DBClass(typeof('+@TableName+'), "'+@TableName+'", "'+@TableName+'")]
	public partial class '+@TableName+'
	{
		#region Fields
		'+@ColList+'
		#endregion
	}
}
'

	EXECUTE master.dbo.PrintMaxString @Class
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES(@TableName, @Class, 1) /*1==Model Class*/

	SET @listID -= 1
	SET @Class = NULL
	SET @ColList = NULL
	SET @TableName = NULL
	SET @GetList = NULL
	SET @GetParms = NULL
END

SELECT *
FROM @Objects