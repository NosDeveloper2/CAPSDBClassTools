
DECLARE @crlf VARCHAR(10) = '
'
DECLARE @tab VARCHAR(9) = '	'
DECLARE @filename VARCHAR(MAX)
DECLARE @Class VARCHAR(MAX)
DECLARE @ColList VARCHAR(MAX)
DECLARE @GetList VARCHAR(MAX)
DECLARE @GetParms VARCHAR(MAX)
DECLARE @GetParmsRouting VARCHAR(MAX)
DECLARE @TableName VARCHAR(255)
DECLARE @listID INT
SELECT @listID = MAX(TableID)
FROM @TableInfoList

WHILE @listID > 0
BEGIN
	SELECT @TableName = TableName,
		@GetParms  = COALESCE(
								@GetParms + ', '+DotNetCLRDataType+' '+ColumnName,
								DotNetCLRDataType+' '+ColumnName
							),
		@GetParmsRouting  = COALESCE(
								@GetParmsRouting + '/{'+ColumnName+':'+DotNetCLRDataType+'}',
								'{'+ColumnName+':'+DotNetCLRDataType+'}'
							),
		@GetList = COALESCE(@GetList + ', '+ColumnName, ColumnName)
	FROM @TableInfoList
	WHERE TableID = @listID
		AND key_ordinal IS NOT NULL

	SELECT @Class = '
using System;
using System.Collections.Generic;
using System.Data;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Description;
using '+@NameSpace+'.Model;
'+COALESCE(@References, '')+'

namespace '+@NameSpace+'.Controllers
{
	[RoutePrefix("api/'+@TableName+'")]
    public class '+@TableName+'Controller : ApiController
    {
        // GET api/'+@TableName+'
		[Route]
        public IList<'+@TableName+'> Get'+@TableName+'()
        {
			'+@TableName+'[] '+LOWER(@TableName)+' = null;

			try
            {
                '+@TableName+' cls'+LOWER(@TableName)+' = new '+@TableName+'();
                '+LOWER(@TableName)+' = cls'+LOWER(@TableName)+'.GetAll();
            }
            catch (Exception ex)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.InternalServerError, "Error on get: \n " + ex.Message));
            }

            if ('+LOWER(@TableName)+' == null)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.NotFound));
            }

            return '+LOWER(@TableName)+';
        }

        // GET api/'+@TableName+'/5
		[Route("'+@GetParmsRouting+'")]
        public '+@TableName+' Get'+@TableName+'('+@GetParms+')
        {
			'+@TableName+' '+LOWER(@TableName)+' = null;

            try
            {
                '+@TableName+' cls'+LOWER(@TableName)+' = new '+@TableName+'();
                '+LOWER(@TableName)+' = cls'+LOWER(@TableName)+'.Get('+@GetList+');
            }
            catch (Exception ex)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.InternalServerError, "Error on get: \n " + ex.Message));
            }

            if ('+LOWER(@TableName)+' == null)
            {
                throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.NotFound));
            }
			
            return '+LOWER(@TableName)+';
        }

        // PUT api/'+@TableName+'/1
		[Route("'+@GetParmsRouting+'")]
        [HttpPut]
        public '+@TableName+' Put'+@TableName+'('+@GetParms+', [FromBody] '+@TableName+' '+LOWER(@TableName)+')
        {
			try
			{
				'+@TableName+' cls'+LOWER(@TableName)+' = new '+@TableName+'();
				cls'+LOWER(@TableName)+'.Update('+LOWER(@TableName)+');
			}
			catch (Exception ex)
			{
				throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.InternalServerError, "Error on Save: \n" + ex.Message));
			}

            return '+LOWER(@TableName)+';
        }

        // POST api/'+@TableName+'/5
        [ResponseType(typeof('+@TableName+'))]
        [Route]
        [HttpPost]
        public '+@TableName+' Post'+@TableName+'([FromBody] '+@TableName+' '+LOWER(@TableName)+')
        {
			try
			{
				'+@TableName+' cls'+LOWER(@TableName)+' = new '+@TableName+'();
				cls'+LOWER(@TableName)+'.Insert('+LOWER(@TableName)+');
			}
			catch (Exception ex)
			{
				throw new HttpResponseException(Request.CreateResponse(HttpStatusCode.InternalServerError, "Error on Save: \n" + ex.Message));
			}

            return '+LOWER(@TableName)+';
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
	SET @GetParmsRouting = NULL
END

SELECT *
FROM @Objects
