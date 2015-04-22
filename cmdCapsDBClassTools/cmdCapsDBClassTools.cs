using CommandLine;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ConfigEncrypt;
using System.Threading;
using System.Runtime.InteropServices;
using CommandLine.Text;
using System.Reflection;
using CapsDBClassTools;

namespace cmdCapsDBClassTools
{
    class cmdCapsDBClassTools
    {
        #region Global Variables
        private static readonly Mutex mutex = new Mutex(true, Assembly.GetExecutingAssembly().GetName().CodeBase);
        static HandlerRoutine consoleHandler;
        #endregion

        #region UnManaged Code
        [DllImport("Kernel32")]
        public static extern bool SetConsoleCtrlHandler(HandlerRoutine Handler, bool Add);

        // A delegate type to be used as the handler routine for SetConsoleCtrlHandler.
        public delegate bool HandlerRoutine(CtrlTypes CtrlType);

        // An enumerated type for the control messages sent to the handler routine.
        public enum CtrlTypes
        {
            CTRL_C_EVENT = 0,
            CTRL_BREAK_EVENT,
            CTRL_CLOSE_EVENT,
            CTRL_LOGOFF_EVENT = 5,
            CTRL_SHUTDOWN_EVENT
        }

        private static bool ConsoleCtrlCheck(CtrlTypes ctrlType)
        {
            // Put your own handler here
            switch (ctrlType)
            {
                case CtrlTypes.CTRL_C_EVENT:
                    Console.WriteLine("CTRL+C received, shutting down");
                    break;

                case CtrlTypes.CTRL_BREAK_EVENT:
                    Console.WriteLine("CTRL+BREAK received, shutting down");
                    break;

                case CtrlTypes.CTRL_CLOSE_EVENT:
                    Console.WriteLine("Program being closed, shutting down");
                    Thread.Sleep(5000);
                    break;

                case CtrlTypes.CTRL_LOGOFF_EVENT:
                case CtrlTypes.CTRL_SHUTDOWN_EVENT:
                    Console.WriteLine("User is logging off!, shutting down");
                    Thread.Sleep(5000);
                    break;
            }

            return true;
        }
        #endregion

        static void Main(string[] args)
        {
            ConfigEncrypt.ConfigEncrypt.EncryptConfig();

            //make sure we only have one....
            if (!mutex.WaitOne(TimeSpan.Zero, true))
            {
                Console.WriteLine("Another instance already running");
                Thread.Sleep(5000);
            }

            Console.Clear();

            //save a reference so it does not get GC'd
            consoleHandler = new HandlerRoutine(ConsoleCtrlCheck);

            //set our handler here that will trap exit
            SetConsoleCtrlHandler(consoleHandler, true);

            Console.Write("CTRL+C to exit or CTRL+BREAK to interrupt the operation\n");

            var options = new Options();

            if (System.Diagnostics.Debugger.IsAttached & (options.ConnectionString == null | options.DestinationFilePath == null))
            {
                var builder = new SqlConnectionStringBuilder(Properties.Settings.Default.DefaultConn.Decrypt());
                options.ConnectionString = builder.ConnectionString;
                options.DestinationFilePath = Properties.Settings.Default.DefaultFileLocation;
                options.Database = string.IsNullOrEmpty(builder.InitialCatalog) ? Properties.Settings.Default.DefaultDB : builder.InitialCatalog;
                options.ExcludeTables = Properties.Settings.Default.DefaultExcludeTables;
                options.ClassNamespace = Properties.Settings.Default.DefaultClassNamespace;
                options.References = Properties.Settings.Default.DefaultReferences;
                options.IndividualTable = Properties.Settings.Default.DefaultIndividualTable;
                options.SingleClassType = (ObjectType)Properties.Settings.Default.DefaultObjectType;
            }

            if (CommandLine.Parser.Default.ParseArguments(args, options))
            {
                // Values are available here
                if (!string.IsNullOrEmpty(options.ConnectionString)) Console.WriteLine("ConnectionString: {0}", options.ConnectionString);
                if (!string.IsNullOrEmpty(options.DestinationFilePath)) Console.WriteLine("DestinationFilePath: {0}", options.DestinationFilePath);
                if (!string.IsNullOrEmpty(options.ClassNamespace)) Console.WriteLine("ClassNamespace: {0}", options.ClassNamespace);
                if (!string.IsNullOrEmpty(options.Database)) Console.WriteLine("Database: {0}", options.Database);
                if (!string.IsNullOrEmpty(options.ExcludeTables)) Console.WriteLine("ExcludeTables: {0}", options.ExcludeTables);
                if (!string.IsNullOrEmpty(options.References)) Console.WriteLine("References: {0}", options.References);
                if (!string.IsNullOrEmpty(options.IndividualTable)) Console.WriteLine("IndividualTable: {0}", options.IndividualTable);
                if (options.SeperateCRUD) Console.WriteLine("SeperateCRUD: {0}", options.SeperateCRUD);
                if (options.SingleClassType != ObjectType.Default) Console.WriteLine("SingleClass: {0}", options.SingleClassType);
            }
            else
            {
                Console.WriteLine("Please provide the required parameters.");

                if (!System.Diagnostics.Debugger.IsAttached)
                {
                    return;
                }
            }

            if (string.IsNullOrEmpty(options.DestinationFilePath))
            {
                if (!System.IO.Directory.Exists(options.DestinationFilePath))
                {
                    System.IO.Directory.CreateDirectory(options.DestinationFilePath);
                }
            }

            try
            {
                new CapsDBClassTools.CreateObjects(
                    options.ConnectionString,
                    options.DestinationFilePath,
                    options.ClassNamespace,
                    options.Database,
                    options.ExcludeTables,
                    options.References,
                    options.IndividualTable,
                    options.SeperateCRUD,
                    options.SingleClassType);
            }
            catch (Exception ex)
            {
                Console.Write("Error using RefreshClasses: " + ex.Message);
            }
        }
    }

    class Options
    {
        private const string singleclassobject = "ModelClass = 0,\nControllerClass = 1,\nCRUDModelClass = 2,\nWCFClass = 3,\nStoredProcedure = 4,\nIWCFClass = 5";

        [Option('c', "connection-string", Required = false, HelpText = "Database Connection string.")]
        public string ConnectionString { get; set; }

        [Option('f', "destination-file-path", Required = false, HelpText = "Files output destination.")]
        public string DestinationFilePath { get; set; }

        [Option('n', "namespace", Required = false, HelpText = "Namespace for output class files")]
        public string ClassNamespace { get; set; }

        [Option('d', "database", Required = false, HelpText = "Database for output class files")]
        public string Database { get; set; }

        [Option('r', "class-references", Required = false, HelpText = "Class references for output class files")]
        public string References { get; set; }

        [Option('x', "tables-to-exclude", Required = false, HelpText = "List of tables to exclude class creation. Always use quotes to begin and end, Use commas seperate tables in the list, and always Use a single quote(') at the beginning and end of each tablename. ")]
        public string ExcludeTables { get; set; }

        [Option('t', "individual-tables", Required = false, HelpText = "Single table to have classes created")]
        public string IndividualTable { get; set; }

        [Option('s', "seperate-crud-class", Required = false, HelpText = "Creates a Model class and a CRUD Class seperately")]
        public bool SeperateCRUD { get; set; }

        [Option('b', "single-class-object", Required = false, HelpText = "Creates a single type of model class", MutuallyExclusiveSet = singleclassobject)]
        public ObjectType SingleClassType { get; set; }

        [ParserState]
        public IParserState LastParserState { get; set; }

        [HelpOption]
        public string GetUsage()
        {
            return HelpText.AutoBuild(this,
              (HelpText current) => HelpText.DefaultParsingErrorsHandler(this, current));
        }
    }
}
