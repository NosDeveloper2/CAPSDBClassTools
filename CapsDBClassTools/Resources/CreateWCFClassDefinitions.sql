
DECLARE @crlf VARCHAR(10) = '
'
DECLARE @tab VARCHAR(9) = '	'
DECLARE @filename VARCHAR(MAX)
DECLARE @WcfClass VARCHAR(MAX)
DECLARE @IWcfClass VARCHAR(MAX)
DECLARE @Methods VARCHAR(MAX) = ''
DECLARE @IMethods VARCHAR(MAX) = ''
DECLARE @TableName VARCHAR(255)
DECLARE @listID INT
SELECT @listID = MAX(TableID)
FROM @TableInfoList

WHILE @listID > 0
BEGIN
	SELECT @TableName = TableName
	FROM @TableInfoList
	WHERE TableID = @listID

	SELECT @Methods += '
        #region '+@TableName+'
        public IList<'+@TableName+'> Get'+@TableName+'(int id)
        {
            try
            {
                return new '+@TableName+'Controller().Get'+@TableName+'();
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public Agency Get'+@TableName+'(int id)
        {
            try
            {
                return new '+@TableName+'Controller().Get'+@TableName+'(id);
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public int Insert'+@TableName+'('+@TableName+' '+LOWER(@TableName)+')
        {
            try
            {
                return new '+@TableName+'Controller().Post'+@TableName+'('+LOWER(@TableName)+').'+@TableName+'ID;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public '+@TableName+' Update'+@TableName+'(int id, '+@TableName+' '+LOWER(@TableName)+')
        {
            try
            {
                return new '+@TableName+'Controller().Put'+@TableName+'(id, '+LOWER(@TableName)+');
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public int Delete'+@TableName+'(int id)
        {
            try
            {
                return new '+@TableName+'Controller().Delete'+@TableName+'(id);
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        #endregion
	'

	SELECT @IMethods += '
        #region '+@TableName+'
        [OperationContract]
        public IList<'+@TableName+'> Get'+@TableName+'();

        [OperationContract]
        public '+@TableName+' Get'+@TableName+'(int id);

        [OperationContract]
        public int Insert'+@TableName+'('+@TableName+' '+LOWER(@TableName)+');

        [OperationContract]
        public '+@TableName+' Update'+@TableName+'(int id, '+@TableName+' '+LOWER(@TableName)+');

        [OperationContract]
        public int Delete'+@TableName+'(int id);
        #endregion
'

	SET @listID -= 1
	SET @TableName = NULL
END

SELECT @WcfClass = '
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;
'+COALESCE(@References, '')+'

namespace '+@NameSpace+'
{
    public class WCFService : IWCFService
    {
        '+@Methods+'
    }
}'

SELECT @IWcfClass = '
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;
'+COALESCE(@References, '')+'

namespace '+@NameSpace+'
{
    public interface IWCFService
    {
        '+@IMethods+'
    }
}'


EXECUTE master.dbo.PrintMaxString @WcfClass
INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
VALUES('WCFService.svc', @WcfClass, 4) /*4==WCF Class*/

EXECUTE master.dbo.PrintMaxString @IWcfClass
INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
VALUES('IWCFService', @IWcfClass, 6) /*6==IWCF Class*/

SELECT *
FROM @Objects
