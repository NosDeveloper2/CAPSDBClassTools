using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;
using ConfigEncrypt;

namespace DBConnection
{
    public class DBConnection
    {
        #region Fields
        public string ConnectionString { get; set; }
        public SqlConnection Connection { get; set; }
        public SqlCommand Command { get; set; }
        public List<DbParameter> OutParameters { get; private set; }
        #endregion

        #region Constructors
        /// <summary>
        /// Default Constructor will automatically create Connection to locally defined ConnectionString
        /// </summary>
        public DBConnection()
        {
        }

        /// <summary>
        /// Constutor that overrides local ConnectionString
        /// </summary>
        /// <param name="connectionString"></param>
        public DBConnection(string connectionString)
        {
            ConnectionString = connectionString;
        }
        #endregion

        #region Open/Close
        private void Open()
        {
            try
            {
                Connection = new SqlConnection(ConnectionString);
                Connection.Open();

            }
            catch (Exception ex)
            {
                Connection.Close();
                throw new Exception(ex.Message);
            }
        }

        private void Close()
        {
            if (Connection != null)
            {
                Connection.Close();
            }
        }
        #endregion

        #region Private Methods
        /// <summary>
        /// Allows the execution of Sql Text or SQL Stored Procedure with parameters.
        /// </summary>
        /// <param name="sqltext"> Stored Procedure name or SQL Text to be executed against</param>
        /// <param name="executeType">NonQuery, Reader, or Scalar execution</param>
        /// <param name="parameters">List of DbParameter class.</param>
        /// <param name="commandType">Stored Procedure, SqlText, or Direct Table</param>
        /// <returns></returns>
        private object Execute(string commandText, ExecuteType executeType, List<DbParameter> parameters, CommandType commandType = CommandType.StoredProcedure)
        {
            object returnObject = null;

            if (Connection != null)
            {
                if (Connection.State == ConnectionState.Open)
                {
                    Command = new SqlCommand(commandText, Connection);
                    Command.CommandType = commandType;

                    if (parameters != null)
                    {
                        Command.Parameters.Clear();

                        foreach (DbParameter dbParameter in parameters)
                        {
                            SqlParameter parameter = new SqlParameter();
                            parameter.ParameterName = "@" + dbParameter.Name;
                            parameter.Direction = (ParameterDirection)dbParameter.Direction;
                            parameter.Value = dbParameter.Value;
                            parameter.DbType = DbType.AnsiString;
                            Command.Parameters.Add(parameter);
                        }
                    }

                    switch (executeType)
                    {
                        case ExecuteType.ExecuteReader:
                            SqlDataReader reader = Command.ExecuteReader();
                            returnObject = reader;
                            break;
                        case ExecuteType.ExecuteNonQuery:
                            int retval = Command.ExecuteNonQuery();
                            returnObject = retval;
                            break;
                        case ExecuteType.ExecuteScalar:
                            object obj= Command.ExecuteScalar();
                            returnObject = obj;
                            break;
                        default:
                            break;
                    }
                }
            }

            return returnObject;
        }

        /// <summary>
        /// Adds values to the output parameters for the current command
        /// </summary>
        private void UpdateOutParameters()
        {
            if (Command.Parameters.Count > 0)
            {
                OutParameters = new List<DbParameter>();
                OutParameters.Clear();

                for (int i = 0; i < Command.Parameters.Count; i++)
                {
                    if (Command.Parameters[i].Direction == ParameterDirection.Output)
                    {

                        OutParameters.Add(new DbParameter(Command.Parameters[i].ParameterName, DbDirection.Output, Command.Parameters[i].SqlDbType, Command.Parameters[i].Value));
                    }
                }
            }
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Creates a list of parametrs based off of the object class and it's values
        /// </summary>
        /// <param name="objClass">Class to be reflected into parameters</param>
        /// <param name="ListType">Value determines all columns, or just the key values should be parameterized</param>
        /// <returns></returns>
        public List<DbParameter> CreateParamList(object objClass, ParamListType ListType)
        {
            //Update to allow differeny ListTypes (Save = All columns, Get is Just PK)
            List<DbParameter> result = ClassToDbParameter.CreateParam(objClass, ListType);

            return result;
        }

        /// <summary>
        /// Execute Procedure or SQL Text and returns a single object (not used for SQL Text)
        /// </summary>
        /// <typeparam name="T">Class Object Name</typeparam>
        /// <param name="commandText">SQL Stored Procedure Name</param>
        /// <returns>Object T</returns>
        public T ExecuteSingle<T>(string commandText) where T : new()
        {
            return ExecuteSingle<T>(commandText, null, CommandType.StoredProcedure);
        }

        /// <summary>
        /// Execute Procedure or SQL Text and returns a single object (not used for SQL Text)
        /// </summary>
        /// <typeparam name="T">Class Object Name</typeparam>
        /// <param name="parameters">parameter list</param>
        /// <param name="commandText">SQL Stored Procedure Name</param>
        /// <returns>Object T</returns>
        public T ExecuteSingle<T>(string commandText, List<DbParameter> parameters) where T : new()
        {
            return ExecuteSingle<T>(commandText, parameters, CommandType.StoredProcedure);
        }

        /// <summary>
        /// Execute Procedure or SQL Text and returns a single object (commandType must equal CommandType.Text for SQL Text)
        /// </summary>
        /// <typeparam name="T">Class Object Name</typeparam>
        /// <param name="parameters">parameter list</param>
        /// <param name="commandText">SQL Stored Procedure Name</param>
        /// <param name="commandType">Type of SQL Command, Text or StoredProcedure</param>
        /// <returns>Object T</returns>
        public T ExecuteSingle<T>(string commandText, List<DbParameter> parameters, CommandType commandType) where T : new()
        {
            Open();
            IDataReader reader = (IDataReader)Execute(commandText, ExecuteType.ExecuteReader, parameters, commandType);
            T tempObject = new T();

            if (reader.Read())
            {
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    PropertyInfo propertyInfo = typeof(T).GetProperty(reader.GetName(i));
                    propertyInfo.SetValue(tempObject, reader.GetValue(i), null);
                }
            }

            reader.Close();

            UpdateOutParameters();

            Close();

            return tempObject;
        }

        /// <summary>
        /// Execute Procedure or SQL Text and returns a List of object
        /// </summary>
        /// <typeparam name="T">Class Object Name</typeparam>
        /// <param name="commandText">SQL Stored Procedure Name</param>
        /// <returns>Object T</returns>
        public List<T> ExecuteList<T>(string commandText) where T : new()
        {
            return ExecuteList<T>(commandText, null, CommandType.StoredProcedure);
        }

        /// <summary>
        /// Execute Procedure or SQL Text and returns a List of object
        /// </summary>
        /// <typeparam name="T">Class Object Name</typeparam>
        /// <param name="commandText">SQL Stored Procedure Name</param>
        /// <param name="commandType">Type of SQL Command, Text or StoredProcedure</param>
        /// <returns>Object T</returns>
        public List<T> ExecuteList<T>(string commandText, CommandType commandType) where T : new()
        {
            return ExecuteList<T>(commandText, null, commandType);
        }

        /// <summary>
        /// Execute Procedure or SQL Text and returns a List of object
        /// </summary>
        /// <typeparam name="T">Class Object Name</typeparam>
        /// <param name="parameters">parameter list</param>
        /// <param name="commandText">SQL Stored Procedure Name</param>
        /// <param name="commandType">Type of SQL Command, Text or StoredProcedure</param>
        /// <returns>Object T</returns>
        public List<T> ExecuteList<T>(string commandText, List<DbParameter> parameters, CommandType commandType) where T : new()
        {
            List<T> objects = new List<T>();

            Open();
            IDataReader reader = (IDataReader)Execute(commandText, ExecuteType.ExecuteReader, parameters, commandType);

            while (reader.Read())
            {
                T tempObject = new T();

                for (int i = 0; i < reader.FieldCount; i++)
                {
                    if (reader.GetValue(i) != DBNull.Value)
                    {
                        PropertyInfo propertyInfo = typeof(T).GetProperty(reader.GetName(i));
                        propertyInfo.SetValue(tempObject, reader.GetValue(i), null);
                    }
                }

                objects.Add(tempObject);
            }

            reader.Close();

            UpdateOutParameters();

            Close();

            return objects;
        }

        /// <summary>
        /// Execute Procedure or Sql Text and returns TSQL Return success value
        /// </summary>
        /// <param name="commandText"></param>
        /// <param name="parameters"></param>
        /// <param name="commandType"></param>
        /// <returns></returns>
        public int ExecuteNonQuery(string commandText, List<DbParameter> parameters, CommandType commandType)
        {
            int returnValue;

            Open();

            returnValue = (int)Execute(commandText, ExecuteType.ExecuteNonQuery, parameters, commandType);

            UpdateOutParameters();

            Close();

            return returnValue;
        }
        #endregion
    }

    public enum ExecuteType
    {
        ExecuteReader,
        ExecuteNonQuery,
        ExecuteScalar
    };

    public enum DbDirection
    {
        Input,
        InputOutput,
        Output,
        ReturnValue
    }

    /// <summary>
    /// Based on the type only Key or All columns are parameterized
    /// </summary>
    public enum ParamListType
    {
        Key,
        All
    }

    /// <summary>
    /// Allows creation of database parameters
    /// </summary>
    public class DbParameter
    {
        #region Fields
        public string Name { get; set; }
        public DbDirection Direction { get; set; }
        public object Value { get; set; }
        public SqlDbType SqlType { get; set; }
        #endregion

        #region Constructors
        public DbParameter() { }

        public DbParameter(string parameterName, DbDirection parameterDirection, SqlDbType sqltype, object parameterValue)
        {
            Name = parameterName;
            Direction = parameterDirection;
            Value = parameterValue;
            SqlType = sqltype;
        }

        public DbParameter(string parameterName, DbDirection paramaeterDirection, object parameterValue)
        {
            Name = parameterName;
            Direction = paramaeterDirection;
            Value = parameterValue;
        }
        #endregion
    }

    /// <summary>
    /// Converts a class to DB Parameters. Relies on Class having DBClass, DBField, and DBKeyfield Attributes
    /// </summary>
    public static class ClassToDbParameter
    {
        public static List<DbParameter> CreateParam(object objClass, ParamListType ParamType)
        {
            var list = new List<DbParameter>();
            Add(ref list, objClass, ParamType);
            return list;
        }

        private static void Add(ref List<DbParameter> list, object data, ParamListType ParamType)
        {
            Type objType = data.GetType();
            List<PropertyInfo> propertyList = new List<PropertyInfo>(objType.GetProperties());
            System.Attribute[] AttributeList = System.Attribute.GetCustomAttributes(objType);

            for (int i = 0; i < propertyList.Count; ++i)
            {
                var prop = propertyList.ToArray()[i];
                DBKeyField keyAttr = (DBKeyField)AttributeList[i];
                DBField attr = (DBField)AttributeList[i];
                DbParameter param = new DbParameter();
                object propValue = prop.GetValue(data, null);

                param.Name = prop.Name;
                param.Value = propValue;
                param.Direction = DbDirection.Input;
                param.SqlType = keyAttr == null ? attr.SqlDbType : keyAttr.SqlDbType;
                if (ParamType == ParamListType.Key)
                {
                    if (keyAttr != null)
                    {
                        list.Add(param);
                    }
                }
                else
                {
                    list.Add(param);
                }

            }
        }
    }
}
