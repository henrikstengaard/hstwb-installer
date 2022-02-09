```c#
            await 4.GB()
                .ToUniversalSize()
                .CreateRigidDiskBlock()
                .AddFileSystem("PDS3", await File.ReadAllBytesAsync(@"pfs3aio"))
                .AddPartition("DH0", 300.MB(), bootable: true)
                .AddPartition("DH1")
                .WriteToFile(@"4gb.hdf");

```