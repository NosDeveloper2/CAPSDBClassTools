public static class GetClassText
{
    private static string attribute = DBConnection.Properties.Resources.Attributes;
    private static string connection = DBConnection.Properties.Resources.Connection;

    public static string Attribute
    {
        get
        {
            return attribute;
        }
    }
    public static string Connection
    {
        get
        {
            return connection;
        }
    }
}