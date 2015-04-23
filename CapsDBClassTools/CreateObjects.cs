//using DBConnection;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CapsDBClassTools
{
    public class CreateObjects
    {
        #region Fields
        public string ConnectionString { get; set; }
        public string Filepath { get; set; }
        public string ClassNamespace { get; set; }
        public string Database { get; set; }
        public string ExcludeTables { get; set; }
        public string References { get; set; }
        public string IndividualTable { get; set; }
        public bool SeperateCRUD { get; set; }
        public ObjectType ObjectType { get; set; }
        #endregion

        #region Constructors
        public CreateObjects(string connstring, string filepath, string classnamespace, string database, string excludetables, string references, string individualtable, bool seperatecrud, ObjectType objecttype)
        {
            ConnectionString = connstring;
            Filepath = filepath;
            ClassNamespace = classnamespace;
            Database = database;
            ExcludeTables = excludetables;
            References = references;
            IndividualTable = individualtable;
            SeperateCRUD = seperatecrud;
            ObjectType = objecttype;
            CreateFiles();
        }
        public CreateObjects(string connstring, string filepath, string classnamespace, string database, string excludetables, string references, string individualtable, bool seperatecrud)
        {
            ConnectionString = connstring;
            Filepath = filepath;
            ClassNamespace = classnamespace;
            Database = database;
            ExcludeTables = excludetables;
            References = references;
            IndividualTable = individualtable;
            SeperateCRUD = seperatecrud;
            CreateFiles();
        }
        public CreateObjects(string connstring, string filepath, string classnamespace, string database, string excludetables, string references, string individualtable)
        {
            ConnectionString = connstring;
            Filepath = filepath;
            ClassNamespace = classnamespace;
            Database = database;
            ExcludeTables = excludetables;
            References = references;
            IndividualTable = individualtable;
            CreateFiles();
        }
        public CreateObjects(string connstring, string filepath, string classnamespace, string database, string excludetables, string references)
        {
            ConnectionString = connstring;
            Filepath = filepath;
            ClassNamespace = classnamespace;
            Database = database;
            ExcludeTables = excludetables;
            References = references;
            CreateFiles();
        }
        public CreateObjects(string connstring, string filepath, string classnamespace, string database, string excludetables)
        {
            ConnectionString = connstring;
            Filepath = filepath;
            ClassNamespace = classnamespace;
            Database = database;
            ExcludeTables = excludetables;
            CreateFiles();
        }
        public CreateObjects(string connstring, string filepath, string classnamespace, string database)
        {
            ConnectionString = connstring;
            Filepath = filepath;
            ClassNamespace = classnamespace;
            Database = database;
            CreateFiles();
        }
        public CreateObjects(string connstring, string filepath, string classnamespace)
        {
            ConnectionString = connstring;
            Filepath = filepath;
            ClassNamespace = classnamespace;
            CreateFiles();
        }
        public CreateObjects()
        {
            if (string.IsNullOrEmpty(ConnectionString) || string.IsNullOrEmpty(Filepath))
            {
                return;
            }
            CreateFiles();
        }
        #endregion

        private void CreateFiles()
        {
            try
            {
                WriteClassesToFile(Filepath);
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private List<GeneratedObjects> CreateClasses()
        {
            try
            {
                Connection db = new Connection(ConnectionString);
                var builder = new SqlConnectionStringBuilder(ConnectionString);
                List<DbParameter> Params = new List<DbParameter>(){
                new DbParameter(){
                     Direction = DbDirection.Input,
                     Name ="Database",
                     Value = string.IsNullOrEmpty(Database) ? builder.InitialCatalog : Database
                },
                new DbParameter(){
                     Direction = DbDirection.Input,
                     Name ="NameSpace",
                     Value = string.IsNullOrEmpty(ClassNamespace) ? string.Empty : ClassNamespace
                },
                new DbParameter(){
                     Direction = DbDirection.Input,
                     Name ="ExcludeTables",
                     Value = string.IsNullOrEmpty(ExcludeTables) ? string.Empty : ExcludeTables
                },
                new DbParameter(){
                     Direction = DbDirection.Input,
                     Name ="References",
                     Value = string.IsNullOrEmpty(References) ? string.Empty : References
                },
                new DbParameter(){
                     Direction = DbDirection.Input,
                     Name ="IndividualTable",
                     Value = string.IsNullOrEmpty(IndividualTable) ? string.Empty : IndividualTable
                }
            };

                List<GeneratedObjects> classes = new List<GeneratedObjects>();
                string tableinfoscript = Properties.Resources.TableInfo;
                string combine;

                //Create Models
                if (SeperateCRUD)
                {
                    //Seperates CRUD Operations into seperate file that inherits from main model
                    combine = tableinfoscript + Properties.Resources.CreateModelClassDefinitions;
                    classes.AddRange(db.ExecuteList<GeneratedObjects>(combine, Params, System.Data.CommandType.Text));
                    combine = string.Empty;

                    //Crud methods inheriting above class
                    combine = tableinfoscript + Properties.Resources.CreateModelCrud;
                    classes.AddRange(db.ExecuteList<GeneratedObjects>(combine, Params, System.Data.CommandType.Text));
                    combine = string.Empty;
                }
                else
                {
                    //Everything for class in one file
                    combine = tableinfoscript + Properties.Resources.CreateClassDefinitions;
                    classes.AddRange(db.ExecuteList<GeneratedObjects>(combine, Params, System.Data.CommandType.Text));
                    combine = string.Empty;
                }

                //Add Controller classes
                combine = tableinfoscript + Properties.Resources.CreateControllerDefinitions;
                classes.AddRange(db.ExecuteList<GeneratedObjects>(combine, Params, System.Data.CommandType.Text));
                combine = string.Empty;

                //Add WCF Classes
                combine = tableinfoscript + Properties.Resources.CreateWCFClassDefinitions;
                classes.AddRange(db.ExecuteList<GeneratedObjects>(combine, Params, System.Data.CommandType.Text));
                combine = string.Empty;

                //Add CRUD Procedures
                combine = tableinfoscript + Properties.Resources.CreateCrudProcedureDefinitions;
                classes.AddRange(db.ExecuteList<GeneratedObjects>(combine, Params, System.Data.CommandType.Text));
                combine = string.Empty;


                //Create Connection File so others can use it directly(or modify it if needed)
                classes.Add(
                    new GeneratedObjects()
                    {
                        ObjectId=1000,
                        ObjectName = "Connection",
                        ObjectDefinition=GetClassText.Connection,
                        ObjectType=(int)ObjectType.Default
                    }
                );

                //Create Attributes File so others can use it directly(or modify it if needed)
                classes.Add(
                    new GeneratedObjects()
                    {
                        ObjectId = 1001,
                        ObjectName = "Attributes",
                        ObjectDefinition = GetClassText.Attribute,
                        ObjectType = (int)ObjectType.Default
                    }
                );

                //Return everything
                return classes;
            }
            catch (Exception ex)
            {
                throw new Exception("Error on Create Classes: \n" + ex.Message, ex.InnerException);
            }
        }

        private void WriteClassesToFile(string filePath)
        {
            var list = CreateClasses();

            //Get only the records where they match the Object Type if passed in Object Type is not ObjectType.Default
            if (ObjectType != ObjectType.Default)
            {
                list = list.Where(x => x.ObjectType == (int)ObjectType).ToList();
            }

            try
            {
                foreach (var cls in list)
                {
                    var otfe = new ObjectTypeFileExtensions(cls.ObjectType);
                    var extension = otfe.ExtensionTypeValue;
                    var folder = otfe.ExtensionFolder;
                    var path = filePath + "\\" + Database + "\\" + folder;
                    var filename = cls.ObjectName + "." + extension;
                    var fullpath = path + "\\" + filename;
                    if (!Directory.Exists(path))
                    {
                        Directory.CreateDirectory(path);
                    }

                    if (string.IsNullOrEmpty(cls.ObjectDefinition))
                    {
                        //write a response for files that are null
                    }
                    else
                    {
                        WriteTextAsync(fullpath, cls.ObjectDefinition);
                    }
                }
            }
            catch (Exception ex)
            {
                throw new Exception("Error on WriteClassesToFile: \n" + ex.Message, ex.InnerException);
            }
        }

        private static void WriteTextAsync(string filePath, string text)
        {
            byte[] encodedText = Encoding.Default.GetBytes(text);
            using (var sourceStream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None, 4096, true))
            {
                sourceStream.Write(encodedText, 0, encodedText.Length);
            }
        }
    }
}
