Free
----
Author: Henrik Noerfjand Stengaard
Date: 2019-06-21

Free is a tool to returns a device's free space in mega bytes.
Usage: Free [DEVICE].

Compile with SAS C v6.58:

assign sc: [path-to-sasc]/sasc
assign lib: sc:lib add
assign include: sc:include add
assign cxxinclude: sc:cxxinclude add
path sc:c add
smake clean