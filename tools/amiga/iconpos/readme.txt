IconPos
-------
Author: Henrik Noerfjand Stengaard
Date: 2019-01-14

IconPos is a tool to change icon position and drawer window position and size.

Compile with SAS C v6.58:

assign sc: [path-to-sasc]/sasc
assign lib: sc:lib add
assign include: sc:include add
assign cxxinclude: sc:cxxinclude add
path sc:c add
smake clean