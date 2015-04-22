using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace DBConnection.old
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
        public DBConnection() { }

        public DBConnection(string connectionString)
        {
            ConnectionString = connectionString;
        }
        #endregion

        #region Connection Open/Close
        /// <summary>
        /// Open Connection
        /// </summary>
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

        /// <summary>
        /// Close Connection
        /// </summary>
        private void Close()
        {
            if (Connection != null)
            {
                Connection.Close();
            }
        }
        #endregion

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
                            returnObject = Command.ExecuteReader();
                            break;
                        case ExecuteType.ExecuteNonQuery:
                            returnObject = Command.ExecuteNonQuery();
                            break;
                        case ExecuteType.ExecuteScalar:
                            returnObject = Command.ExecuteScalar();
                            break;
                        default:
                            break;
                    }
                }
            }

            return returnObject;
        }

        /// <summary>
        /// Adds data to the output parameters for the Sql command
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
                        OutParameters.Add(new DbParameter(Command.Parameters[i].ParameterName, DbDirection.Output, Command.Parameters[i].Value));
                    }
                }
            }
        }

        /// <summary>
        /// Creates List of parameters based off of the Atributes class
        /// </summary>
        /// <param name="objClass"></param>
        /// <param name="ListType"></param>
        /// <returns></returns>
        public List<DbParameter> CreateParamList(object objClass, ParamListType ListType)
        {
            //Update to allow differeny ListTypes (Save = All columns, Get is Just PK)
            List<DbParameter> result = ClassToDbParameter.CreateParam(objClass);

            return result;
        }

        /// <summary>
        /// Executes a single return object
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="procedureName"></param>
        /// <param name="commandtype"></param>
        /// <returns></returns>
        public T ExecuteSingle<T>(string procedureName, CommandType commandtype = CommandType.StoredProcedure) where T : new()
        {
            return ExecuteSingle<T>(procedureName, null);
        }

        /// <summary>
        /// Returns a single return object;
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="commandText"></param>
        /// <param name="parameters"></param>
        /// <param name="commandtype"></param>
        /// <returns></returns>
        public T ExecuteSingle<T>(string commandText, List<DbParameter> parameters, CommandType commandtype = CommandType.StoredProcedure) where T : new()
        {
            Open();

            IDataReader reader = (IDataReader)Execute(commandText, ExecuteType.ExecuteReader, parameters, commandtype);

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

        public List<T> ExecuteList<T>(string commandText, CommandType commandtype = CommandType.StoredProcedure) where T : new()
        {
            return ExecuteList<T>(commandText, null);
        }

        public List<T> ExecuteList<T>(string commandText, List<DbParameter> parameters, CommandType commandtype = CommandType.StoredProcedure) where T : new()
        {
            List<T> objects = new List<T>();

            Open();
            IDataReader reader = (IDataReader)Execute(commandText, ExecuteType.ExecuteReader, parameters, commandtype);

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

        public int ExecuteNonQuery(string commandText, List<DbParameter> parameters, CommandType commandtype = CommandType.StoredProcedure)
        {
            int returnValue;

            Open();

            returnValue = (int)Execute(commandText, ExecuteType.ExecuteReader, parameters, commandtype);

            UpdateOutParameters();

            Close();

            return returnValue;
        }
    }

    /// <summary>
    /// SQL Execute Types
    /// </summary>
    public enum ExecuteType
    {
        ExecuteReader,
        ExecuteNonQuery,
        ExecuteScalar
    };

    /// <summary>
    /// Parameter Directions
    /// </summary>
    public enum DbDirection
    {
        Input,
        InputOutput,
        Output,
        ReturnValue
    }

    /// <summary>
    /// paramaters List Type 
    /// </summary>
    public enum ParamListType
    {
        Get,
        Save
    }

    public class DbParameter
    {
        public string Name { get; set; }
        public DbDirection Direction { get; set; }
        public object Value { get; set; }

        public DbParameter() { }

        public DbParameter(string parameterName, DbDirection parameterDirection, object parameterValue)
        {
            Name = parameterName;
            Direction = parameterDirection;
            Value = parameterValue;
        }
    }

    public static class ClassToDbParameter
    {
        public static List<DbParameter> CreateParam(object objClass)
        {
            var list = new List<DbParameter>();
            Type objType = objClass.GetType();
            DataTable result = new DataTable(objType.ToString().Split('+')[1]);
            List<PropertyInfo> propertyList = new List<PropertyInfo>(objType.GetProperties());

            foreach (PropertyInfo prop in propertyList)
            {
                Add(ref list, objClass);
            }

            return list;
        }


        private static void Add(ref List<DbParameter> list, object data)
        {
            Type objType = data.GetType();
            DbParameter param = new DbParameter();
            List<PropertyInfo> propertyList = new List<PropertyInfo>(objType.GetProperties());

            foreach (PropertyInfo prop in propertyList)
            {
                object propValue = prop.GetValue(data, null);

                param.Name = prop.Name;
                param.Value = propValue;
                param.Direction = DbDirection.Input;
            }
            list.Add(param);
        }
    }
}
