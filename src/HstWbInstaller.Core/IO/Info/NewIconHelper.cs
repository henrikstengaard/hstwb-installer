namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;
    using System.Linq;
    using Errors;

    public static class NewIconHelper
    {
        public static void RemoveNewIconImage(DiskObject diskObject, int imageNumber)
        {
            var imageHeader = $"IM{imageNumber}=";

            if (diskObject.ToolTypes == null)
            {
                return;
            }
            
            // remove new icon image number text datas
            diskObject.ToolTypes.TextDatas = RemoveNewIconTextDatas(diskObject.ToolTypes.TextDatas, imageHeader).ToList();
        }

        public static void SetNewIconImage(DiskObject diskObject, int imageNumber, NewIcon newIcon)
        {
            var imageHeader = $"IM{imageNumber}=";

            if (diskObject.ToolTypes == null)
            {
                diskObject.ToolTypesPointer = 1;
                diskObject.ToolTypes = new ToolTypes();
            }
            
            // remove new icon image number text datas
            var textDatas = RemoveNewIconTextDatas(diskObject.ToolTypes.TextDatas, imageHeader).ToList();
            
            // get new icon header bytes
            var newIconHeaderBytes = AmigaTextHelper.GetBytes(Constants.NewIcon.Header).Concat(new byte[]{0});
            
            // find text data with new icon header bytes
            var newIconHeaderTextData = textDatas.FirstOrDefault(x => x.Data.SequenceEqual(newIconHeaderBytes));
            
            // disk object has new icons, if new icon header is present in text data
            var hasNewIcons = newIconHeaderTextData != null;

            // add new icon header, if no new icons are present in disk object
            if (!hasNewIcons)
            {
                textDatas.Add(InfoHelper.CreateTextData(" "));
                newIconHeaderTextData = InfoHelper.CreateTextData(Constants.NewIcon.Header);
                textDatas.Add(newIconHeaderTextData);
            }
            
            // encode new icon to text datas 
            var newIconTextDatas = NewIconToolTypesEncoder.Encode(imageNumber, newIcon).ToList();

            // find index of new icon header text data
            var newIconHeaderIndex = textDatas.IndexOf(newIconHeaderTextData);
            
            // insert new icon text datas after new icon header, if image number is 1. otherwise append new icon text datas
            if (imageNumber == 1)
            {
                textDatas.InsertRange(newIconHeaderIndex + 1, newIconTextDatas);
            }
            else
            {
                textDatas.AddRange(newIconTextDatas);
            }
            
            diskObject.ToolTypes.TextDatas = textDatas;
        }

        private static IEnumerable<TextData> RemoveNewIconTextDatas(IEnumerable<TextData> textDatas, string imageHeader)
        {
            return textDatas
                .Where(x => !MatchesImageHeader(x, imageHeader));
        }

        private static bool MatchesImageHeader(TextData textData, string imageHeader)
        {
            return textData.Data.Length >= 4 && AmigaTextHelper.GetString(textData.Data, 0, 4).Equals(imageHeader);
        }

        public static bool HasValidNewIcon(DiskObject diskObject)
        {
            return ValidateNewIcon(diskObject).IsSuccess;
        }

        public static Result ValidateNewIcon(DiskObject diskObject)
        {
            // return error, if new icon header space is not present before new icon header
            if (diskObject.Gadget.GadgetRenderPointer == 0 || diskObject.FirstImageData == null)
            {
                return new Result<Error>(new NormalPlanarImageIsNotSetError());
            }
            
            var textDatas = (diskObject.ToolTypes?.TextDatas ?? Enumerable.Empty<TextData>()).ToList();
            
            // get new icon header bytes
            var newIconHeaderBytes = AmigaTextHelper.GetBytes(Constants.NewIcon.Header).Concat(new byte[]{0});
            
            // find text data with new icon header bytes
            var newIconHeaderTextData = textDatas.FirstOrDefault(x => x.Data.SequenceEqual(newIconHeaderBytes));

            // return error, if new icon header text data is not present
            if (newIconHeaderTextData == null)
            {
                return new Result<Error>(new NewIconHeaderIsNotPresentError());
            }
            
            // find index of new icon header text data
            var newIconHeaderIndex = textDatas.IndexOf(newIconHeaderTextData);

            // return error, if new icon space is not present before new icon header text data 
            if (newIconHeaderIndex == 0)
            {
                return new Result<Error>(new NewIconSpaceIsNotPresentError());
            }

            // return error, if new icon space is not present before new icon header text data
            var newIconSpaceTextData = textDatas[newIconHeaderIndex - 1];
            if (!(newIconSpaceTextData.Data.Length == 2 && newIconSpaceTextData.Data.SequenceEqual(new byte[] { 32, 0 })))
            {
                return new Result<Error>(new NewIconSpaceIsNotPresentError());
            }

            // set new icon image 1 tool type index
            var image1ToolTypeIndex = newIconHeaderIndex + 1;
            
            // find next tool types matching new icon image number 1 header
            var newIconToolTypeHeader = "IM1=";
            var textDataOffset = image1ToolTypeIndex;
            for (; textDataOffset < textDatas.Count && MatchesImageHeader(textDatas[textDataOffset], newIconToolTypeHeader); textDataOffset++)
            {
            }

            // return error, if new icon image 1 text datas count is less than 2
            // (minimum 1 for header and palette and minimum 1 for image pixels)
            var image1TextDatasCount = textDataOffset - image1ToolTypeIndex; 
            if (image1TextDatasCount < 2)
            {
                return new Result<Error>(new NewIconImage1ToolTypesNotPresentError());
            }
            
            // set new icon image 2 tool type index
            var image2ToolTypeOffset = textDataOffset;

            // find next tool types matching new icon image number 2 header
            newIconToolTypeHeader = "IM2=";
            for (; textDataOffset < textDatas.Count && MatchesImageHeader(textDatas[textDataOffset], newIconToolTypeHeader); textDataOffset++)
            {
            }

            // return error, if new icon image 2 text datas count after new icon image 1 text datas are present and
            // less than 2 (minimum 1 for header and palette and minimum 1 for image pixels)
            var image2TextDatasCount = textDataOffset - image2ToolTypeOffset; 
            if (image2TextDatasCount is > 0 and < 2)
            {
                return new Result<Error>(new NewIconImage2ToolTypesNotPresentError());
            }
            
            return new Result();
        }
    }
}