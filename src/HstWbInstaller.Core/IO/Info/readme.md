# References

## Amiga Icon Formats reference

```
Dirk Stöcker <stoecker@epost.de>
17th February 2002

Format description of Amiga Icon Format.

This format is used by Amiga computers to display icons for each program
or project you want to access from the graphical user interface Workbench.

There are 3 different formats.
1) The OS1.x/OS2.x icons.
2) The NewIcon icon extension.
3) The OS3.5 icon extension.

A note about the used data descriptors. All elements are in Motorola byte
order (highest byte first):
APTR  - a memory pointer (usually this gets a boolean meaning on disk)
BYTE  - a single byte                   -128..127
UBYTE - an unsigned byte                   0..255
WORD  - a signed 16 bit value         -32768..32767
UWORD - an unsigned 16 bit value           0..65535
LONG  - a signed 32 bit value    -2147483648..2147483647
ULONG - a unsigned 32 bit value            0..4294967295
There are lots of elements marked with ???. These are usually filled with
values, which have no effect at all. Thus they can normally be ignored.
For some values the usual contents is described.

******************************
***** OS1.x/OS2.x format *****
******************************
The OS1.x/OS2.x format is mainly an storage of the in-memory structures on
disk. This means there is many crap in that format, which may have undefined
values. This text tries to show which values are important and which not.

0x00 UWORD ic_Magic          always 0xE310
0x00 UWORD ic_Version        always 1
0x04 struct Gadget           (described below)
0x30 UBYTE ic_Type
     1 DISK                  a disk
     2 DRAWER                a directory
     3 TOOL                  a program
     4 PROJECT               a project file with defined program to start
     5 GARBAGE               the trashcan
     6 DEVICE                should never appear
     7 KICK                  a kickstart disk
     8 APPICON               should never appear
0x31 UBYTE ic_Pad            <undefined>
0x32 APTR  ic_DefaultTool    <boolean>
0x36 APTR  ic_ToolTypes      <boolean>
0x3A LONG  ic_CurrentX       X position of icon in drawer/on WorkBench
0x3E LONG  ic_CurrentY       Y position of icon in drawer/on WorkBench
0x42 APTR  ic_DrawerData     <boolean>
0x46 APTR  ic_ToolWindow     <boolean>
0x4A LONG  ic_StackSize      the stack size for program execution
                             (values < 4096 mean 4096 is used)
This is followed by certain other data structures:
struct DrawerData            if ic_DrawerData is not zero (see below)
struct Image                 first image
struct Image                 second image if ga_SelectRender not zero
                             (see below) in gadget structure
DefaultTool text             if ic_DefaultTool not zero (format see below)
ToolTypes texts              if ic_ToolTypes not zero (format see below)
ToolWindow text              if ic_ToolWindow not zero (format see below)
                             this is an extension, which was never implemented
struct DrawerData2           if ic_DrawerData is not zero and ga_UserData
                             is 1 (see below)

Now a description of the sub-formats:

a) The text storage method (DefaultTool, ToolWindow and ToolTypes):
0x00 ULONG tx_Size           the size of tx_Text including zero byte (tx_Zero)
0x04 ...   tx_Text           the plain text
.... UBYTE tx_Zero           the finishing zero byte
This means the text "Hallo" will be encoded as \00\00\00\06Hallo\00.

As ToolTypes are an array of texts the encoding is preceeded by another
ULONG value containing the number of entries. But to make parsing more
interessting it is not the number as one would expect, but the number of
entries increased by one and multiplied by 4. Thus 10 entries will have
44 as count.

b) The Gadget structure:
0x00 APTR  ga_Next           <undefined> always 0
0x04 WORD  ga_LeftEdge       unused ???
0x06 WORD  ga_TopEdge        unused ???
0x08 WORD  ga_Width          the width of the gadget
0x0A WORD  ga_Height         the height of the gadget
0x0C UWORD ga_Flags          gadget flags
     bit 2                   always set (image 1 is an image ;-)
     bit 1                   if set, we use 2 image-mode
     bit 0                   if set we use backfill mode, else complement mode
                             complement mode: gadget colors are inverted
                             backfill mode: like complement, but region
                             outside (color 0) of image is not inverted
     As you see, it makes no sense having bit 0 and 1 set.
0x0E UWORD ga_Activation     <undefined>
0x10 UWORD ga_GadgetType     <undefined>
0x12 APTR  ga_GadgetRender   <boolean> unused??? always true
0x16 APTR  ga_SelectRender   <boolean> (true if second image present)
0x1A APTR  ga_GadgetText     <undefined> always 0 ???
0x1E LONG  ga_MutualExclude  <undefined>
0x22 APTR  ga_SpecialInfo    <undefined>
0x26 UWORD ga_GadgetID       <undefined>
0x28 APTR  ga_UserData       lower 8 bits:  0 for old, 1 for icons >= OS2.x
			     upper 24 bits: undefined

c) The DrawerData structure:
This structure is useful for drawers and disks (but there are some
icons of other types, which still have these obsolete entries).
0x00 struct NewWindow        (see below)
0x30 LONG  dd_CurrentX       the current X position of the drawer window
                             contents (this is the relative offset of the
                             drawer drawmap)
0x34 LONG  dd_CurrentY       the current Y position of the drawer window
                             contents

d) The NewWindow structure used by DrawerData:
0x00 WORD  nw_LeftEdge       left edge distance of window
0x02 WORD  nw_TopEdge        top edge distance of widndow
0x04 WORD  nw_Width          the width of the window (outer width)
0x06 WORD  nw_Height         the height of the window (outer height)
0x08 UBYTE nw_DetailPen      always 255 ???
0x09 UBYTE nw_BlockPen       always 255 ???
0x0A ULONG nw_IDCMPFlags     <undefined>
0x0E ULONG nw_Flags          <undefined>
0x12 APTR  nw_FirstGadget    <undefined>
0x16 APTR  nw_CheckMark      <undefined>
0x1A APTR  nw_Title          <undefined>
0x1E APTR  nw_Screen         <undefined>
0x22 APTR  nw_BitMap         <undefined>
0x26 WORD  nw_MinWidth       <undefined> often 94, minimum window width
0x28 WORD  nw_MinHeight      <undefined> often 65, minimum window height
0x2A UWORD nw_MaxWidth       <undefined> often 0xFFFF, maximum window width
0x2C UWORD nw_MaxHeight      <undefined> often 0xFFFF, maximum window width
0x2E UWORD nw_Type           <undefined>

e) The DrawerData2 structure for OS2.x drawers:
0x00 ULONG dd_Flags          flags for drawer display
     value 0                 handle viewmode like parent drawer current
                             setting (OS1.x compatibility mode)
     bit 0                   view icons
     bit 1                   view all files (bit 0 maybe set or unset
                             with this)
0x04 UWORD dd_ViewModes      viewmodes of drawer display
     value 0                 show icons (OS1.x compatibility mode)
     value 1                 show icons
     value 2                 show sorted by name
     value 3                 show sorted by date
     value 4                 show sorted by size
     value 5                 show sorted by type

f) And now the last element, the Image structure:
0x00 WORD  im_LeftEdge       always 0 ???
0x00 WORD  im_TopEdge        always 0 ???
0x04 WORD  im_Width          the width of the image
0x06 WORD  im_Height         the height of the image
0x08 WORD  im_Depth          the image bitmap depth
0x0A APTR  im_ImageData      <boolean> always true ???
0x0E UBYTE im_PlanePick      foreground color register index
0x0F UBYTE im_PlaneOnOff     background color register index
0x10 APTR  im_Next           always 0 ???
This is followed by the image data in planar mode. The width of the
image is always rounded to next 16bit boundary.

******************************
***** NewIcon extension ******
******************************

As the original format is very limited when using more than the 4 or 8 default
colors and also when using different palette sets than the default, there have
been ideas how to circumvent this. A Shareware author invented NewIcons
format, which uses the ToolTypes to store image data, as expanding the original
format very surely would haven broken compatibility.

The NewIcons stuff usually starts with following 2 ToolTypes text (text inside
of the "" only):
" "
"*** DON'T EDIT THE FOLLOWING LINES!! ***"

Aftwerwards the image data is encoded as ASCII. The lines for first image
always start with "IM1=". If present the second image starts with "IM2=".

The first line of each image set contains the image information and the
palette.
Example: "IM1=B}}!'��5(3%;ll����T�S9`�"

0x00 UBYTE ni_Transparency
     "B"                     transparency on
     "C"                     transparency off
0x01 UBYTE ni_Width          image width + 0x21  - "}" means width 92
0x02 UBYTE ni_Height         image height + 0x21 - "}" means height 92
0x03 UWORD ni_Colors         ASCII coded number of palette entries:
     entries are: ((buf[3]-0x21)<<6)+(buf[4]-0x21)
     "!'" means 6 entries
Afterwards the encoded palette is stored. Each element has 8 bit and colors
are stored in order red, green, blue. The encoded format is described below.
The ni_Width and ni_Height maximum values are 93. The maximum color value
is theoretically 255. I have seen images with at least 257 stored colors
(but less than 256 used).

The following lines contain the image data encoded with the same system as
the palette. The number of bits used to encode an entry depends of the number
of colors (6 colors f.e. need 3 bit). The lines have maximum 127 bytes
including the "IM1=" or "IM2=" header. Thus including the zero byte, the
string will be 128 byte.

En/Decoding algorithm:
Each byte encodes 7bit (except the RLE bytes)
Bytes 0x20 to 0x6F represent 7bit value 0x00 to 0x4F
Bytes 0xA1 to 0xD0 represent 7bit value 0x50 to 0x7F
Bytes 0xD1 to 0xFF are RLE bytes:
  0xD1 represents  1*7 zero bits,
  0xD2 represents  2*7 zero bits and the last value
  0xFF represents 47*7 zero bits.

Opposite to the original icon format, the NewIcons format uses chunky modus
to store the image data.

The encoding for images and palette stops at the string boundary (127 bytes)
with buffer flush (and adding pad bits) and is restarted with next line.

******************************
****** OS3.5 extension *******
******************************

The OS3.5 format introduces nearly the same information as in NewIcons, but
in a more usable format. The tooltypes are no longer misused, but a new data
block is appended at the end of the icon file. This data block is in IFF
format.
It consists of the standard header
0x00 UBYTE[4] ic_Header      set to "FORM"
0x04 ULONG    ic_Size        size [excluding the first 8 bytes!]
0x08 UBYTE[4] ic_Identifier  set to "ICON"

Now Chunks of different data follow. Each chunk consists of 8 header bytes
and the data bytes. If the size in header is uneven, then it is automatically
paddind with 1 byte at the end.

Currently 3 chunks are used with following data. Note that IFF generally
allows expansion and chunk reordering, so do not rely on any current size
information or chunk order, but skip unknown data based on the size
information stored in file.

1)
0x00 UBYTE[4] fc_Header      set to "FACE"
0x04 ULONG    fc_Size        size [excluding the first 8 bytes!]
0x08 UBYTE    fc_Width       icon width subtracted by 1
0x09 UBYTE    fc_Height      icon height subtracted by 1
0x0A UBYTE    fc_Flags       flags
     bit 0                   icon is frameless
0x0B UBYTE    fc_Aspect      image aspect ratio:
     upper 4 bits            x aspect
     lower 4 bits            y aspect
0x0C UWORD    fc_MaxPalBytes maximum number of bytes used in image palettes
                             subtracted by 1 (i.e. if palette 1 has 17 and
                             palette 2 has 45 entries, then this is 45)

2) Now 2 chunks of this type may come, where first chunk is image 1
and second chunk is image 2.
0x00 UBYTE[4] im_Header      set to "IMAG"
0x04 ULONG    im_Size        size [excluding the first 8 bytes!]
0x08 UBYTE    im_Transparent number of the transparent color
0x09 UBYTE    im_NumColors   number of colors subtracted by 1
0x0A UBYTE    im_Flags
     bit 0                   there exists a transparent color
     bit 1                   a palette data is attached (NOTE, that first
                             image always needs palette data, whereas the
                             second one can reuse the first palette.)
0x0B UBYTE    im_ImageFormat storage format of image data
     value 0                 uncompressed
     value 1                 run-length compressed
0x0C UBYTE    im_PalFormat   storage format of palette data (same as above)
0x0D UBYTE    im_Depth       the number of bits used to store a pixel
0x0E UWORD    im_ImageSize   number of bytes used to store image (subtracted
                             by 1)
0x10 UWORD    im_PalSize     number of bytes used to store palette
                             (subtracted by 1)
0x12 UBYTE[...]              the image data
.... UBYTE[...]              the palette data (if existing)


Now about the run-length compression. This is equal to the run-length method
in IFF-ILBM format: The input data is seen as a bit-stream, where each entry
has im_Depth bits for image or 8 bits for palette. First comes an 8 bit RLE
block with following meaning:
0x00 .. 0x7F copy the next n entries as they are, where n is "RLE-value"+1
0x80         ignore this, do nothing
0x81 .. 0xFF produce the next entry n times, where n is 256-"RLE-value"+1
             (if using signed chars n is "RLE-value"+1)

In uncompressed mode, each byte represents one pixel (even if lower depth is
used).
```

## infotopam reference

From: https://linux.die.net/man/1/infotopam

Thanks to the following people on comp.sys.amiga.programmer for tips and pointers on decoding the info file format:

- Ben Hutchings
- Thomas Richter

- Kjetil Svalastog Matheussen

- Anders Melchiorsen

- Dirk Stoecker

- Ronald V.D.

The format of the Amiga .info file is as follows:
```
DiskObject header            78 bytes
Optional DrawerData header   56 bytes
First icon header            20 bytes
First icon data              Varies
Second icon header           20 bytes
Second icon data             Varies
```
The DiskObject header contains, among other things, the magic number (0xE310), the object width and height (inside the embedded Gadget header), and the version.
Each icon header contains the icon width and height, which can be smaller than the object width and height, and the number of bit-planes.

The icon data has the following format:

BIT-PLANE planes, each with HEIGHT rows of (WIDTH +15) / 16 * 2 bytes length.
So if you have a 9x3x2 icon, the icon data will look like this:
```
aaaa aaaa a000 0000
aaaa aaaa a000 0000
aaaa aaaa a000 0000
bbbb bbbb b000 0000
bbbb bbbb b000 0000
bbbb bbbb b000 0000
```

where a is a bit for the first bit-plane, b is a bit for the second bit-plane, and 0 is padding. Thanks again to Ben Hutchings for his very helpful post!