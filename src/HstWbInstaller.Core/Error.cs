namespace HstWbInstaller.Core
{
    public class Error
    {
        public readonly string Message;

        public Error()
        {
            Message = "Error";
        }

        public Error(string message)
        {
            Message = message;
        }

        public override string ToString()
        {
            return Message;
        }
    }
}