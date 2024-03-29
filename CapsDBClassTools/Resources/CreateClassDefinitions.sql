
DECLARE @crlf VARCHAR(10) = '
'
DECLARE @tab VARCHAR(9) = '	'
DECLARE @filename VARCHAR(MAX)
DECLARE @Class VARCHAR(MAX)
DECLARE @ColList VARCHAR(MAX)
DECLARE @GetList VARCHAR(MAX)
DECLARE @GetParms VARCHAR(MAX)
DECLARE @KeyList VARCHAR(MAX)
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

	SELECT @KeyList = COALESCE(
						@KeyList + @CRLF + @CRLF + @tab + @tab + 'public '+DotNetCLRDataType+' '+ColumnName+' { get; set; }',
						@CRLF + @CRLF + @tab + @tab + 'public '+DotNetCLRDataType+' '+ColumnName+' { get; set; }'
					)
	FROM @TableInfoList
	WHERE Key_Ordinal >= 1

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

		#region SpNames
		private static string GetProc = "proc_'+@TableName+'_Get";
		private static string GetAllProc = "proc_'+@TableName+'_GetAll";
		private static string GetUpdateProc = "proc_'+@TableName+'_Update";
		private static string GetInsertProc = "proc_'+@TableName+'_Insert";
		#endregion

		#region Methods
		private static '+@TableName+'[] '+@TableName+'Array()
		{
			var dbconn = new Connection();
			return dbconn.ExecuteList<'+@TableName+'>(GetAllProc).ToArray();
		}

		public '+@TableName+'KeyFieldResult Update('+@TableName+' '+LOWER(@TableName)+')
		{
			var dbconn = new Connection();
			var paramlist = dbconn.CreateParamList('+LOWER(@TableName)+', ParamListType.All);
			//dbconn.ExecuteNonQuery(GetUpdateProc, paramlist, CommandType.StoredProcedure);
			return dbconn.ExecuteSingle<'+@TableName+'KeyFieldResult>(GetUpdateProc, paramlist, CommandType.StoredProcedure);
		}

		public '+@TableName+'KeyFieldResult Insert('+@TableName+' '+LOWER(@TableName)+')
		{
			var dbconn = new Connection();
			var paramlist = dbconn.CreateParamList('+LOWER(@TableName)+', ParamListType.All);
			//dbconn.ExecuteNonQuery(GetInsertProc, paramlist, CommandType.StoredProcedure);
			return dbconn.ExecuteSingle<'+@TableName+'KeyFieldResult>(GetInsertProc, paramlist, CommandType.StoredProcedure);
		}

		public '+@TableName+' Get('+@GetParms+')
		{
			var dbconn = new Connection();
			var paramlist = new List<DbParameter>() {'+@GetList+'};
			return dbconn.ExecuteSingle<'+@TableName+'>(GetProc, paramlist, CommandType.StoredProcedure);
		}

		public '+@TableName+'[] GetAll()
		{
			return '+@TableName+'Array();
		}
		#endregion
	}

	public partial class '+@TableName+'KeyFieldResult
	{
		'+@KeyList+'
	}
}
'

	EXECUTE master.dbo.PrintMaxString @Class
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES(@TableName, @Class, 1) /*1 == model class*/

	SET @listID -= 1
	SET @Class = NULL
	SET @ColList = NULL
	SET @TableName = NULL
	SET @GetList = NULL
	SET @GetParms = NULL
	SET @KeyList = NULL
END

SELECT *
FROM @Objects