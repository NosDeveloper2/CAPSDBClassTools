
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

	SELECT @Class = 'namespace '+@NameSpace+'
{	
	'+ISNULL(@References, '')+'
	[DBClass(typeof('+@TableName+'), "'+@TableName+'", "'+@TableName+'", "proc_'+@TableName+'_Get", "proc_'+@TableName+'_GetAll", "proc_'+@TableName+'_Update", "proc_'+@TableName+'_Delete", "proc_'+@TableName+'_Insert")]
	public partial class '+@TableName+'
	{
		#region Fields
		'+@ColList+'
		#endregion

		#region SpNames
		private static string GetProc = "proc_'+@TableName+'_Get";
		private static string GetAllProc = "proc_'+@TableName+'_GetAll";
		private static string GetUpdateProc = "proc_'+@TableName+'_Update";
		private static string GetDeleteProc = "proc_'+@TableName+'_Delete";
		private static string GetInsertProc = "proc_'+@TableName+'_Insert";
		#endregion

		#region Methods
		private static '+@TableName+'[] '+@TableName+'Array()
		{
			var dbconn = new DBConnection();
			return dbconn.ExecuteList<'+@TableName+'>(GetAllProc).ToArray();
		}

		public void Update('+@TableName+' '+LOWER(@TableName)+')
		{
			var dbconn = new DBConnection();
			var paramlist = dbconn.CreateParamList('+LOWER(@TableName)+', ParamListType.Update);
			dbconn.ExecuteNonQuery(GetUpdateProc, paramlist);
		}

		public void Insert('+@TableName+' '+LOWER(@TableName)+')
		{
			var dbconn = new DBConnection();
			var paramlist = dbconn.CreateParamList('+LOWER(@TableName)+', ParamListType.Insert);
			dbconn.ExecuteNonQuery(GetInsertProc, paramlist);
		}

		public void Delete('+@TableName+' '+LOWER(@TableName)+')
		{
			var dbconn = new DBConnection();
			var paramlist = dbconn.CreateParamList('+LOWER(@TableName)+', ParamListType.Delete);
			dbconn.ExecuteNonQuery(GetDeleteProc, paramlist);
		}

		public '+@TableName+' Get('+@GetParms+')
		{
			var dbconn = new DBConnection();
			var paramlist = new List<DbParameter>() {'+@GetList+'};
			return dbconn.ExecuteSingle<'+@TableName+'>(GetProc, paramlist);
		}

		public '+@TableName+'[] GetAll()
		{
			return '+@TableName+'Array();
		}
		#endregion
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
END

SELECT *
FROM @Objects