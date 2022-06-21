namespace HstWbInstaller.Core.IO.Info.Errors
{
    public class NewIconSpaceIsNotPresentError : Error
    {
        public NewIconSpaceIsNotPresentError() : base(
            "Tool type with a space is not present before \"Don't edit the following lines\" tool type")
        {
        }
    }
}