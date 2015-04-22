using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CapsDBClassTools
{
    public class GeneratedObjects
    {
        public int ObjectId { get; set; }
        public string ObjectName { get; set; }
        public string ObjectDefinition { get; set; }
        public int ObjectType { get; set; }
    }

    public enum ObjectType
    {
        Default = 0,
        ModelClass = 1,
        ControllerClass = 2,
        CRUDModelClass = 3,
        WCFClass = 4,
        StoredProcedure = 5,
        IWCFClass = 6
    }

    public class ObjectTypeFileExtensions
    {
        private ObjectType extensiontype;
        private string extensiontypevalue;
        private string extensionfolder;

        public ObjectType ExtensionType
        {
            get
            {
                return extensiontype;
            }
            set
            {
                SetExtensionType((int)value);
            }
        }

        public string ExtensionTypeValue
        {
            get
            {
                return extensiontypevalue;
            }
            private set
            {
                SetExtensionTypeValue(extensiontype);
            }
        }

        public string ExtensionFolder
        {
            get {
                return extensionfolder;
            }
            private set {
                SetExtensionExtensionFolder(extensiontype);
            }
        }

        public ObjectTypeFileExtensions(ObjectType ot)
        {
            SetExtensionTypeValue(ot);
            SetExtensionType((int)ot);
            SetExtensionExtensionFolder(ot);
        }

        public ObjectTypeFileExtensions(int ot)
        {
            SetExtensionTypeValue((ObjectType)ot);
            SetExtensionType((int)ot);
            SetExtensionExtensionFolder((ObjectType)ot);
        }

        private void SetExtensionType(int i)
        {
            switch (i)
            {
                case (int)ObjectType.ModelClass:
                    extensiontype = ObjectType.ModelClass;
                    break;
                case (int)ObjectType.ControllerClass:
                    extensiontype = ObjectType.ControllerClass;
                    break;
                case (int)ObjectType.CRUDModelClass:
                    extensiontype = ObjectType.CRUDModelClass;
                    break;
                case (int)ObjectType.WCFClass:
                    extensiontype = ObjectType.WCFClass;
                    break;
                case (int)ObjectType.StoredProcedure:
                    extensiontype = ObjectType.StoredProcedure;
                    break;
                case (int)ObjectType.IWCFClass:
                    extensiontype = ObjectType.IWCFClass;
                    break;
                default:
                    extensiontype = ObjectType.Default;
                    break;
            }
        }

        private void SetExtensionTypeValue(ObjectType ot)
        {
            switch (ot)
            {
                case ObjectType.WCFClass:
                    extensiontypevalue = "svc.cs";
                    break;
                case ObjectType.StoredProcedure:
                    extensiontypevalue = "sql";
                    break;
                default:
                    extensiontypevalue = "cs";
                    break;
            }
        }

        private void SetExtensionExtensionFolder(ObjectType ot)
        {
            switch (ot)
            {
                case ObjectType.ModelClass:
                    extensionfolder = "ModelClass";
                    break;
                case ObjectType.ControllerClass:
                    extensionfolder = "ControllerClass";
                    break;
                case ObjectType.CRUDModelClass:
                    extensionfolder = "CRUDModelClass";
                    break;
                case ObjectType.WCFClass:
                    extensionfolder = "WCFClass";
                    break;
                case ObjectType.StoredProcedure:
                    extensionfolder = "StoredProcedure";
                    break;
                case ObjectType.IWCFClass:
                    extensionfolder = "IWCFClass";
                    break;
                default:
                    extensionfolder = "Other";
                    break;
            }
        }
    }
}
