Free
----
Author: Henrik Noerfjand Stengaard
Date: 2019-06-24

Trim is a tool to trim leading and tailing whitespaces from text.

Compile with SAS C v6.58:

assign sc: [path-to-sasc]/sasc
assign lib: sc:lib add
assign include: sc:include add
assign cxxinclude: sc:cxxinclude add
path sc:c add
smake clean