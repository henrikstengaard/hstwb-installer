namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;
    using System.Text;

    public class NewIconAsciiEncoder
    {
        public int BitsPerValue { get; private set; }
        public readonly List<TextData> TextDatas;

        private const int BitsPerByte = 7;
        private byte pendingBits;
        private int bitsLeft;
        private byte[] textDataHeader;
        private List<byte> encodedBytes;
        private int BytesLeft => Constants.NewIcon.MAX_STRING_LENGTH - encodedBytes.Count - (bitsLeft < 7 ? 1 : 0);

        public NewIconAsciiEncoder(int imageNumber, int bitsPerValue = 8)
        {
            this.BitsPerValue = bitsPerValue;
            pendingBits = 0;
            bitsLeft = BitsPerByte;

            textDataHeader = Encoding.ASCII.GetBytes($"IM{imageNumber}=");
            encodedBytes = new List<byte>(textDataHeader);

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
            encodedBytes.Add(value);
        }

        /// <summary>
        /// add value to encode
        /// </summary>
        /// <param name="value"></param>
        public void Encode(byte value)
        {
            var remainingBits = BitsPerValue - bitsLeft;
            pendingBits |= (byte)(bitsLeft - BitsPerValue < 0
                ? value >> remainingBits
                : value << (bitsLeft - BitsPerValue));
            bitsLeft -= BitsPerValue;

            if (bitsLeft > 0)
            {
                return;
            }

            // add pending bits ascii encoded
            encodedBytes.Add(AsciiEncode(pendingBits));

            if (bitsLeft < 0)
            {
                // shift remaining bits left and bitwise and 127 (bits 1-7)
                pendingBits = (byte)((value << (bitsLeft + BitsPerByte)) & 0x7f);
                
                // 00110100 = 52
                // << 3
                // 0000000110100000 = 416
                // &
                // 0000000001111111 = 127
                // =
                // 0000000000100000 = 32
            }

            if (BytesLeft <= 0)
            {
                Flush();
                return;
            }
            
            // add bits per byte to bits left in pending bits
            bitsLeft += BitsPerByte;

            if (bitsLeft != 0)
            {
                return;
            }
            
            // add pending bits ascii encoded
            encodedBytes.Add(AsciiEncode(pendingBits));
            pendingBits = 0;
            bitsLeft += BitsPerByte;
                
            if (BytesLeft <= 0)
            {
                Flush();
            }
        }

        public void Flush()
        {
            if (bitsLeft < BitsPerByte)
            {
                // add pending bits ascii encoded
                encodedBytes.Add(AsciiEncode(pendingBits));
            }

            Next();
        }

        public void Next()
        {
            // add tool types line termination
            encodedBytes.Add(0);

            TextDatas.Add(new TextData
            {
                Size = (uint)encodedBytes.Count,
                Data = encodedBytes.ToArray()
            });

            encodedBytes.Clear();
            encodedBytes.AddRange(textDataHeader);

            pendingBits = 0;
            bitsLeft = BitsPerByte;
        }

        private byte AsciiEncode(byte value)
        {
            return value < 0x50 ? (byte)(value + 0x20) : (byte)(value + 0x51);
        }
    }
}