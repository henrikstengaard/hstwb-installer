namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;
    using System.Reflection;
    using System.Text;

    public class NewIconAsciiEncoder
    {
        public int BitsPerValue { get; private set; }
        public readonly List<TextData> TextDatas;

        private const int NewIconBitsPerByte = 7;
        private int pendingData;
        private int pendingBits;
        private readonly byte[] textDataHeader;
        private readonly List<byte> currentTextData;
        private int BytesLeft => Constants.NewIcon.MAX_TEXTDATA_LENGTH - currentTextData.Count - (pendingBits > 0 ? 1 : 0);

        public NewIconAsciiEncoder(int imageNumber)
        {
            this.BitsPerValue = 8;
            pendingData = 0;
            pendingBits = 0;

            textDataHeader = Encoding.ASCII.GetBytes($"IM{imageNumber}=");
            currentTextData = new List<byte>(textDataHeader);

            TextDatas = new List<TextData>();
        }

        public void SetBitsPerValue(int bitsPerValue)
        {
            this.BitsPerValue = bitsPerValue;
        }

        /// <summary>
        /// add encoded value
        /// </summary>
        /// <param name="value"></param>
        public void Add(byte value)
        {
            currentTextData.Add(value);

            if (BytesLeft <= 0)
            {
                Flush();
            }
        }

        private readonly int[] remainingBitMasks = { 0, 1, 3, 7, 15, 31, 63, 127, 255 };
        
        /// <summary>
        /// add value to encode
        /// </summary>
        /// <param name="value"></param>
        public void Encode(byte value)
        {
            byte nextValue = 0;
            if (pendingBits == NewIconBitsPerByte || BitsPerValue == NewIconBitsPerByte)
            {
                // set next value to value, if bits per value is equal to new icon bits per byte. otherwise next value is set to pending data
                nextValue = (byte)(BitsPerValue == NewIconBitsPerByte ? value : pendingData);
                
                // add ascii encoded next value and possible flush pending data, if no bytes left
                Add(AsciiEncode(nextValue));

                // return, if bits per value is equal to new icon bits per byte (no pending bits)
                if (BitsPerValue == NewIconBitsPerByte)
                {
                    return;
                }

                pendingData = 0;
                pendingBits = 0;
            }
            
            pendingBits += BitsPerValue;
            pendingData <<= BitsPerValue;
            pendingData |= value;

            // return, if pending bits is less than new icon bits per byte (has room for more bits in current value)
            if (pendingBits <= NewIconBitsPerByte)
            {
                return;
            }
            
            // subtract new icon bits per byte from pending bits 
            pendingBits -= NewIconBitsPerByte;
            
            // right shift pending data with pending bits
            nextValue = (byte)(pendingData >> pendingBits);
            
            // bitwise and pending data with remaining bit mask to keep bits left
            pendingData &= remainingBitMasks[pendingBits];
            
            // add ascii encoded next value and possible flush pending data, if no bytes left
            Add(AsciiEncode(nextValue));
        }

        public void Flush()
        {
            if (pendingBits > 0)
            {
                // left shifted pending data to match new icon bits per byte and add ascii encoded value 
                currentTextData.Add(AsciiEncode((byte)(pendingData << NewIconBitsPerByte - pendingBits)));
            }

            Next();
        }

        public void Next()
        {
            // add tool types line termination
            currentTextData.Add(0);

            TextDatas.Add(new TextData
            {
                Size = (uint)currentTextData.Count,
                Data = currentTextData.ToArray()
            });

            currentTextData.Clear();
            currentTextData.AddRange(textDataHeader);

            // reset pending data and bits
            pendingBits = 0;
            pendingData = 0;
        }

        private byte AsciiEncode(byte value)
        {
            return value < 0x50 ? (byte)(value + 0x20) : (byte)(value + 0x51);
        }
    }
}