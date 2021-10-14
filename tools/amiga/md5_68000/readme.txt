MD5
---
Author: Henrik Noerfjand Stengaard
Date: 2018-05-01

MD5 for 68000 based on http://aminet.net/dev/c/md5.lha.

Compile with SAS C v6.58:

assign sc: sys:programs/sasc

assign lib: sc:lib add
assign include: sc:include add
assign cxxinclude: sc:cxxinclude add
path sc:c add
smake
