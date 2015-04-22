
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
	SELECT @TableName = TableName
	FROM @TableInfoList
	WHERE TableID = @listID

	SELECT @Class = '
using System;
using System.Collections.Generic;
using System.Data;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Description;
'+COALESCE(@References, '')+'

namespace '+@NameSpace+'.Controllers
{
    public class '+@TableName+'Controller : ApiController
    {
        // GET api/'+@TableName+'
        public IList<'+@TableName+'> Get'+@TableName+'()
        {
            '+@TableName+' cls'+LOWER(@TableName)+' = new '+@TableName+'();
            var '+LOWER(@TableName)+' = cls'+LOWER(@TableName)+'.GetAll();
            return '+LOWER(@TableName)+';
        }

        // GET api/'+@TableName+'/5
        public '+@TableName+' Get'+@TableName+'(int id)
        {
            '+@TableName+' cls'+LOWER(@TableName)+' = new '+@TableName+'();
            var '+LOWER(@TableName)+' = cls'+LOWER(@TableName)+'.Get(id);
            if ('+LOWER(@TableName)+' == null)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.NotFound));
            }

            return '+LOWER(@TableName)+';
        }

		// POST api/'+@TableName+'/5
        public '+@TableName+' Put'+@TableName+'(int id, '+@TableName+' '+LOWER(@TableName)+')
        {
            '+LOWER(@TableName)+'.Insert('+LOWER(@TableName)+');
            if ('+LOWER(@TableName)+' == null)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.NotFound));
            }

            return '+LOWER(@TableName)+';
        }

		// PUT api/'+@TableName+'
        [ResponseType(typeof('+@TableName+'))]
        public '+@TableName+' Post'+@TableName+'('+@TableName+' '+LOWER(@TableName)+')
        {
            '+LOWER(@TableName)+'.Insert('+LOWER(@TableName)+');
            if ('+LOWER(@TableName)+' == null)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.NotFound));
            }

            return '+LOWER(@TableName)+';
        }

		// PUT api/'+@TableName+'
        [ResponseType(typeof('+@TableName+'))]
        public int Delete'+@TableName+'(int id)
        {
            '+@TableName+' cls'+LOWER(@TableName)+' = new '+@TableName+'();
            var '+LOWER(@TableName)+' = cls'+LOWER(@TableName)+'.Get(id);
            '+LOWER(@TableName)+'.Delete(id);
            if ('+LOWER(@TableName)+' == null)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.NotFound));
            }

            return id;
        }
    }
}
'

	EXECUTE master.dbo.PrintMaxString @Class
	INSERT INTO @Objects(ObjectName, ObjectDefinition, ObjectType)
	VALUES(@TableName+'Controller', @Class, 2) /*2==controller class*/

	SET @listID -= 1
	SET @Class = NULL
	SET @ColList = NULL
	SET @TableName = NULL
	SET @GetList = NULL
	SET @GetParms = NULL
END

SELECT *
FROM @Objects
