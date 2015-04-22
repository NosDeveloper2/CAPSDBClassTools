using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DBConnection
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Struct, AllowMultiple = true)]
    public class DBClass : Attribute
    {
        #region fields
        private Type _classtype;
        private string _classname;
        private string _referencedtable;
        #endregion

        #region Properties
        public Type ClassType
        {
            get
            {
                return this._classtype;
            }
            set
            {
                this._classtype = value;
            }
        }

        public string Name
        {
            get
            {
                return _classname;
            }
            set
            {
                this._classname = value;
            }
        }

        public string TableReference
        {
            get
            {
                return _referencedtable;
            }
            set
            {
                this._referencedtable = value;
            }
        }
        #endregion

        #region Constructors
        public DBClass() { }
        public DBClass(Type ClassType)
        {
            this._classtype = ClassType;
        }
        public DBClass(Type ClassType, string Name)
        {
            this._classtype = ClassType;
            this._classname = Name;
        }
        public DBClass(Type ClassType, string Name, string TableReference)
        {
            this._classtype = ClassType;
            this._classname = Name;
            this._referencedtable = TableReference;
        }
        #endregion
    }

    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = true)]
    public class DBField : Attribute
    {
        #region Fields
        private string _name;
        private Type _type;
        private SqlDbType _sqldbtype;
        private string _sqldbtypedescription;
        #endregion

        #region Properties
        public string FieldName
        {
            get
            {
                return _name;
            }
            set
            {
                this._name = value;
            }

        }

        public Type FieldType
        {
            get
            {
                return this._type;
            }
            set
            {
                this._type = value;
            }
        }

        public SqlDbType SqlDbType
        {
            get
            {
                return this._sqldbtype;
            }
            set
            {
                this._sqldbtype = value;
            }
        }

        public string SQLDbTypeDescription
        {
            get
            {
                return _sqldbtypedescription;
            }
            set
            {
                this._sqldbtypedescription = value;
            }
        }
        #endregion

        #region Constructors
        public DBField(string FieldName, Type FieldType, SqlDbType SqlDbType, string SQLDbTypeDescription)
        {
            this._name = FieldName;
            this._type = FieldType;
            this._sqldbtype = SqlDbType;
            this._sqldbtypedescription = SQLDbTypeDescription;
        }
        public DBField(string FieldName, Type FieldType, SqlDbType SqlDbType)
        {
            this._name = FieldName;
            this._type = FieldType;
            this._sqldbtype = SqlDbType;
        }
        public DBField(string FieldName, Type FieldType, string SQLDbTypeDescription)
        {
            this._name = FieldName;
            this._type = FieldType;
            this._sqldbtypedescription = SQLDbTypeDescription;
        }
        public DBField(string FieldName)
        {
            this._name = FieldName;
        }
        public DBField() { }
        #endregion
    }

    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = true)]
    public class DBKeyField : DBField
    {
        #region Constructors
        public DBKeyField(string KeyFieldName, Type KeyFieldType, SqlDbType KeySqlDbType, string SQLDbTypeDescription)
        {
            this.FieldName = KeyFieldName;
            this.FieldType = KeyFieldType;
            this.SqlDbType = KeySqlDbType;
            this.SQLDbTypeDescription = SQLDbTypeDescription;
        }
        public DBKeyField(string KeyFieldName, Type KeyFieldType, SqlDbType KeySqlDbType)
        {
            this.FieldName = KeyFieldName;
            this.FieldType = KeyFieldType;
            this.SqlDbType = KeySqlDbType;
        }
        public DBKeyField(string KeyFieldName, Type KeyFieldType, string SQLDbTypeDescription)
        {
            this.FieldName = KeyFieldName;
            this.FieldType = KeyFieldType;
            this.SQLDbTypeDescription = SQLDbTypeDescription;
        }
        public DBKeyField(string KeyFieldName)
        {
            this.FieldName = KeyFieldName;
        }
        public DBKeyField() { }
        #endregion

        #region Properties
        public string KeyFieldName
        {
            get
            {
                return this.FieldName;
            }
            set
            {
                this.FieldName = value;
            }

        }

        public Type KeyFieldType
        {
            get
            {
                return this.FieldType;
            }
            set
            {
                this.FieldType = value;
            }
        }
        #endregion
    }
}
