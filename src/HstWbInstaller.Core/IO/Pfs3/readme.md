## C code migration:

~ is a bitwise not/complement, aka it changes all 0's to 1's and vice-versa. ~0 is a value with all bits set to 1.

uint: ~0 = UInt32.MaxValue 

A block is the same as sector size.

First reserved is 2 by default as boot block uses the first 2 blocks followed by root block.

Reserved block number:
- 0: Boot block
- 1: Boot block (continued)
- 2: Root block
- 3: BM: Reserved bitmap block (g.glob_allocdata.res_bitmap)
- 4: BM: Reserved bitmap block (continued)
- 5: Blank
- 6: EX: Root block extension
- 8: MI: Bitmap index block
- 9: MI: Bitmap index block (continued)
- 10 - x: BM: Bitmap blocks for partition.
- 
- x - 14 : IB
- x - 12 : AB
- x - 10 : DB
- x - 8 : DD
- x - 6 : DD
- x - 4 : EX
- x - 2 : EX 
- x : EX