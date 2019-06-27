; FILE: Source:WhichAmiga.ASM          REV: 772 --- Identify which Amiga model you're running
; Hist
; 0-17    Prehistoric revisions. Working hard(?) 19.7.95.
;  18     Fixed a bug, it would have caused an enforcer hit under
;         KS 1.3. ;-)
;  30     Added Workbench startup.
;  41     Machine evaluation works.
;  47     Added more machine formulas about 3.00 AM 20.7.95.
;  52     Added waterproof A3000 check (ramsey&gary test). Fixed machine
;         formulas. Fixed CD³² KS version to V40.
;  57     Added FindConfigDev routine. Added A2500 and A500old.
;  71     Added all machine formulas.
;  74     Fixed MMU disable/enable as much as possible.
;  93     Aaargh! Movec with TC doesn't work! Use pmove.l (an) instead!!
;  96     GetCPU surrounded with DisableMMU/EnableMMU pair.
; 97-148  MUCH improved.
;  149    Added better console output code for running under V37 or better.
;         CD³² users aren't forced to press return anymore... :- )
;  183    Added correct 68EC020 test.
;  197    Added real 68060 test and fixed MMU codes.
;  214    Fixed 68060 test and MMU codes.
;  228    Bug?: Sometimes can't disable MMU!?
;  275    Fixed MMU code a *lot*! Now display is blanked when display doesn't
;         have 4x bandwidth. Now WhichAmiga works with Enforcer, CPU FASTROM and
;         VMM etc.
;  281    Now checks cardslot via hardware.
;  282    Added test for stock model Walker.
;  301    Added display for Paula, Ramsey, Gary and Gayle. Now checks IDE
;         connection via hardware.
; 302-304 Added DraCo support.
;  305    A4000 also has Ramsey chip, but no Gary chip! (I guess!)
;  309    Now should be 100% HW  i ndependent, if needed (DraCo!) 
;  313    Added display for Akiko.
;  328    Really fixed GetAddressBits and moved all VMEM critical code
;         into CODE_C hunk.
;  331    Real support for DraCo... It wouldn't have worked...
;  333    Fixed CDTV test.
;  347    Tried to fix 68040/060 MMU code as much as possible.
;  364    A3000 and A4000 have both Ramsey and Gary, A4000 has Ramsey rev $F.
;  371    Few things added/fixed.
;  377    Fixed bad 040/060 MMU test.
;  384    Added very flexible CPU/FPU/MMU support.
;  427    Added support for boards.library and several gfx boards.
;  459    Rewritten MMU disable/enable code.
;  462    Added correct 68060 speed index.
;  466    Added special support for Blizzard boards' MAPROM.
;  471    Doesn't turn off write allocate... Turns on BERR timeout if Gary
;         chip is present.
;  482    Added (hopefully) correct 68040/68060 MMU code.
;  486    Whops! Turned on BERR not DSACK! :-\
;  499    Added some extensive debug stuff...
;  514    Fixed bug in 68040/68060 MMU test code.
;  512    Finally works with 060 (and 040 too :). Fixed to test bit 15 of
;         TC in MMU activity test on 040 and 060.
;  529    Fixed Ramsey&Gary test. Added other graphics systems.
;  535    Now adjusts comparisation CPU automagically.
;  538    Fixed A3000 machine formula to accept any ECS agnus.
;  543    Separated Ramsey and Gary test. Added correct KS 3.2 version
;         information.
;  547    Fixed loads of OldOpenLibrary, lea (LibList,a6), (ThisTask,a6)...
;         Cached SysBase etc.
;  560    Added SetPatch version info.
;  561    Fixed CloseLibrary(0) bug. Crashed on pre-36 kickstarts.
;  562    Added identification for UAE and phase5's PowerUP boards.
;  566    Added proper identification for PowerUP boards.
;  569    Added support for GigaMem (Max Virtmem).
;  578    Fixed "CNOP 0,4 in code" bug.
;  591    Fiddled a bit with 030 MMU code. Fixed UAE detection. Added
;         6 new gfxcards. Added display for sound cards. 7 sound cards
;         detected as of now.
;  596    Added support for CyberGraphX V3.
;  608    Fiddled again with 030 MMU code. This time I found a bug from it :)
;         Also tried to fix Ramsey & Gary code.
;  616    Fixed A3000/A4000 (=Ramsey&Gary) test (hopefully!)
;  619    Hopefully _finally_ fixed 030 MMU test for defective 68030 chips.
;         Thanks to [Angel] for testing!
;  626    Fixed A4000T rom version.
;  631    Really fixed A4000 test. For some reason my AGA test required rev
;         13 Gayle chip to be present. Uh-oh.
;  632    Fixed A1000 ROM version because it can be changed.
;  633    Hopefully fixed UAE detection.
;  644    Defective 68030 MMU test (hopefully) fixed.
;  645    Added Delfina LITE sound card.
;  646    retina.library is bad... Added check for Retina boards. Thanks to
;         Hurtman for the tip.
;  653    Added hardware clock detection. Suggested by Hurtman.
;  654    Removed one A500 board from A2000 expboardslist. Removed GVP kludge.
;  655    Removed two A500/A2000 boards from A500 list. Added one (hopefully)
;         A2000 only board. Thanks to pyksy.
;  656    Finally got ppc.library autodocs&includes. Fixed PowerPC CPU version
;         display.
;  744    13th May 1998: Made the source public in hope someone would continue
;         the development. At least you can find some interesting routines from
;         here. ;)
;  748    Fixed PPC detection, now support for multiple PPC cpus & fixed 604e
;         not to show as '?'. Fixed some minor bugs.
;  753    Fixed pre-SetPatch 060 test.
;  755    Added brand new 0x0 MHz calculation. Should work well with all 0x0
;         systems.
;  760    Fixed some bugs. Added PPL display to ppc processor display. Added
;         revision display for 060. Added Blizzard PPC serial number display.
;  762    Added CyberVision PPC to gfxboard list.
;  772    2nd May 1999: Fixed ppc revision display + now displays busclock MHz
;         instead of PPL number.
;

	IFGT	0

Found this inside ppc.library : =)

                        PowerUP                         
Now you hold it in your hands which took a lot sweat,   
internal Phase5 conflicts and the lack of motivation    
devil made his appearance several times during the      
2 years this project was ...running...                  

...a product which goals were changed several times     
until it was released.                                  

PowerUP/Phase5 project history censored and deleted.    

ppc.library by Ralph Schmidt                            
SW/HW Debugging and food supply by Gerald Carda         
Debugging,Suggestions and mental support by Frank Mariak
Debugging and some examples by Andre Osterhues          

Private Greetings are going to:
Dirk Leschner, Arne Meier, Matthias Scheler and all my  
Innernet-#grapevine friends



 A3000:
 
 CHIPS:
  Denise - 8373 SuperDenise
  Paula  - Standard Paula
  Agnus  - 8372B Agnus for 2 meg CHIP RAM
  Gary   - Fat Gary
  Amber  - De-interlacing chip to provide 31KHz video
  Buster - SuperBuster -07, -09 and -11
  DMAC   - SuperDMAC -02, -04
  Ramsey - Ramsey -04 and -07

                          -===- Amiga 4000/040 -===-

    Processor : Motorola 68040 / 25Mhz
 Custom Chips : (6): Super Gary, Super Ramsey, Super Amber, Lisa, Alice,
                     Paula.
          RAM : 6mb Ram [2mb Chip/ 4mb Fast]


	ENDC
; TODO:
; o Add CGFX4 BlizzardVision PPC to gfxboard list
; o Fix FPU speed calculation and enable it
; o Add WarpOS support
; o Fix bugs...

; BUGS:
; o Crashes on GVP 1230!! (works sometimes) ;-((  *KLUDGEFIXED*
; o No support for:
; Amber / Super Amber	ECS
; Buster		Zorro III DMA Controller
; SuperIO		"Walker project"
; Super Agnus (8375)	2MB chip PLCC A500+
; Portia		A1000
; Daphne		A1000
; 

; Compiling options:

WA_USE_INCLUDES	SET	1	; 0=Use my custom system, 1=Use standard includes
WA_DEBUG	SET	1	; 0=No debug, 1=Enable debug mode




	IFEQ	WA_USE_INCLUDES
	include	"Devpac:Gen.gs"
	ELSE
	include	"exec/memory.i"
	include	"exec/exec_lib.i"
	include	"dos/dos_lib.i"
	include	"libraries/graphics_lib.i"
	IFND	MYMACROS_I
call	MACRO
	jsr (_LVO\1,a6)
	ENDM
	ENDC
	ENDC
	include	"exec/execbase.i"
	include	"libraries/expansion_lib.i"
	include	"libraries/configvars.i"
	include	"libraries/configregs.i"
	include	"dos/dosextens.i"
	include	"graphics/gfxbase.i"
	IFEQ	WA_USE_INCLUDES
	include	"hardware/demo.i"
	ELSE
	include	"hardware/cia.i"
	include	"hardware/custom.i"
	ENDC
	include	"hardware/intbits.i"
	include	"hardware/dmabits.i"
;	include	"libraries/boards.i"
;	include	"libraries/boards_lib.i"


	include	"powerup/ppclib/ppc.i"
_LVOPPCGetInfo	EQU	-$8A

	IFND	_LVOBestCModeIDTagList
_LVOBestCModeIDTagList	EQU	-$3C
	ENDC
	IFND	CYBRBIDTG_MONITORID
CYBRBIDTG_MONITORID	EQU	$80050003
	ENDC


	IFND	ciacra
ciapra	EQU	PRA
ciaprb	EQU	PRB
ciaddra	EQU	DDRA
ciaddrb	EQU	DDRB
ciatalo	EQU	TALO
ciatahi	EQU	TAHI
ciatblo	EQU	TBLO
ciatbhi	EQU	TBHI
ciatodlow	EQU	TODLO
ciatodmid	EQU	TODMID
ciatodhi	EQU	TODHI
ciasdr	EQU	SDR
ciaicr	EQU	ICR
ciacra	EQU	CRA
ciacrb	EQU	CRB
	ENDC
	IFND	CIAB
CIAB	EQU	$BFD000
	ENDC
	IFND	AFB_68060
AFB_68060	EQU	7
AFF_68060	EQU	1<<AFB_68060
	ENDC
_LVOAddICRVector EQU	-$6
_LVORemICRVector EQU	-$C
_LVOAbleICR	EQU	-$12
_LVOSetICR	EQU	-$18

_LVOFreeNVData	EQU	-$24
_LVOGetNVInfo	EQU	-$36

INFINITE	EQU	$7FFFFFFF
MINUS_INFINITE	EQU	$80000000

ID_UNIX_DISK	EQU	('U'<<24)!('N'<<16)!('I'<<8)!(1)


MC68000	EQU	0
MC68010	EQU	1
MC68EC020	EQU	2	24bit ab
MC68020	EQU	3	32bit ab
MC68EC030 	EQU	4	no mmu
MC68030	EQU	5	mmu
MC68EC040 	EQU	6	no mmu, no fpu
MC68LC040 	EQU	7	mmu, no fpu
MC68040	EQU	8	mmu, fpu
MC68EC060 	EQU	9	no mmu, no fpu
MC68LC060 	EQU	10	mmu, no fpu
MC68060	EQU	11	mmu, fpu

;;MPC603e	EQU	12	\
;;MPC604	EQU	13	 } not yet implemented, but supported
;;MPC620	EQU	14	/


MIN020	EQU	MC68EC020
MAX020	EQU	MC68020
MIN030	EQU	MC68EC030
MAX030	EQU	MC68030
MIN040	EQU	MC68EC040
MAX040	EQU	MC68040
MIN060	EQU	MC68EC060
MAX060	EQU	MC68060
MAXCPU	EQU	INFINITE

NOMATH	EQU	0
MC68881	EQU	1
MC68882	EQU	2
MC68040i	EQU	3
MC68060i	EQU	4
MINFPU	EQU	MC68881
MAXFPU	EQU	INFINITE

NOMMU	EQU	0
MC68851	EQU	1
MC68030m	EQU	2
MC68040m	EQU	3
MC68060m	EQU	4
MINMMU	EQU	MC68851
MAXMMU	EQU	INFINITE

DBG	MACRO	*id
	IFNE	WA_DEBUG
	move.l	#\1,-(sp)
	jsr	_dp
	ENDC
	ENDM
	IFNE	WA_DEBUG
_DBUGMAIN	jmp	__MAIN
_dp	bra.b	.exit
	btst	#INTB_INTEN-8,$DFF000+intenar
	beq.b	.exit
	btst	#INTB_PORTS,$DFF000+intenar+1
	beq.b	.exit
	movem.l	d0-a6,-(sp)
	move.l	(4).w,a6		No need...
	clr.l	-(sp)
	move.l	(8*4+7*4+4+4,sp),-(sp)
	move.l	sp,-(sp)
	lea	(LibList,a6),a0		No need...
	lea	(.dosname,pc),a1
	call	FindName
	move.l	d0,a6
	lea	(.fmt,pc),a0
	move.l	a0,d1
	addq.l	#1,-(a0)
	move.l	(a0),-(sp)
	move.l	sp,d2
	call	VPrintf
	call	Output
	move.l	d0,d1
	call	Flush
	moveq	#10,d1
	call	Delay
	lea	(4*4,sp),sp
	movem.l	(sp)+,d0-a6
.exit	move.l	(sp)+,(sp)
	rts
	CNOP	0,4
.cnt	dc.l	0
.fmt	dc.b	'DEBUG %ld: %4s',10,0
.dosname	dc.b	'dos.library',0

	SECTION	DREALMAIN,CODE
	ENDC
__MAIN

	IFGT	0
	lea	(.init,pc),a0
	lea	(.rout,pc),a1
	lea	(.cleanup,pc),a2
	jsr	TimeRoutine
	rts

.init	move.l	(4).w,a6
	call	Disable
	rts
.rout	move.l	#$1000,d0
.loop	subq.l	#1,d0
	bne.b	.loop
	rts
.cleanup	move.l	(4).w,a6
	call	Enable
	rts
	ENDC

;	include	"Source:WBStartUp.ASM"

; WBStartUp code

startupcode	move.l	(4).w,a6
	move.l	d0,d2
	move.l	a0,a2
	sub.l	a1,a1
	jsr	(-$126,a6)	;FindTask
	move.l	d0,a4

	tst.l	($AC,a4)	; pr_CLI
	bne.s	.main

	lea	($5C,a4),a0	; pr_MsgPort
	jsr	(-$180,a6)	;WaitPort
	lea	($5C,a4),a0	; pr_MsgPort
	jsr	(-$174,a6)	;GetMsg
	move.l	d0,-(sp)
	sub.l	a0,a0
	bsr.b	.main
	move.l	d0,d2

	move.l	(4).w,a6
	jsr	(-$84,a6)	;Forbid
	move.l	(sp)+,a1
	jsr	(-$17A,a6)	;ReplyMsg

	move.l	d2,d0
	rts

.main	move.l	d2,d0
	move.l	a2,a0
	; a6=execbase
	; a4=thistask (FindTask()'d! :)


MAINMAIN	clr.b	-1(a0,d0.l)
	move.l	a0,_Args
	move.l	a4,_ThisTask
	lea	(ExecBase00,pc),a0
	move.l	a6,(a0)
	lea	(__MAIN-4,pc),a0
.eloop	move.l	(a0),d0
	beq.b	.edone
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	a6,(4,a0)
	bra.b	.eloop
.edone
	tst.l	(pr_CLI,a4)
	seq	WBMode
	cmp.w	#36,(LIB_VERSION,a6)
	shi	NewKick

	IFNE	WA_DEBUG
	cmp.w	#37,(LIB_VERSION,a6)
	blo.b	.db_exit
	tst.b	WBMode
	bne.b	.db_exit
	move.l	_Args,a0
	tst.b	(a0)
	beq.b	.db_exit
	move.w	#$4E71,_dp		Enable debug stuff!
	call	CacheClearU
.db_exit
	ENDC

	lea	(DosName,pc),a1
	moveq	#0,d0
	call	OpenLibrary
	move.l	d0,_DosBase
	beq.b	.fail
	move.l	d0,a5

	exg	a5,a6
	call	Output
	tst.b	WBMode
	bpl.b	.cli
	lea	(ConsoleName,pc),a0
	tst.b	NewKick
	bpl.b	.is_old
	lea	(NewConsoleName-ConsoleName,a0),a0
.is_old	move.l	a0,d1
	move.l	#MODE_READWRITE,d2
	call	Open
.cli	move.l	d0,OutputFH
	exg	a5,a6
	bne.b	.gotfh
.fail	moveq	#RETURN_FAIL,d0		<- Things are badly wrong!
	rts
.gotfh

 IFGT 0
                        Agnus    PCMCIA  Akiko   AT-IDE    NVRAM  Ramsey&Gary
            KS:     Denise    Chip   A690ID  Proc   StockMHz   UNI/01   A26x0
>A1000   1.1-1.3      O Older  ¼/½          01??      7
>A500old 1.2-2.x,3.1  O  Old   ½            01234     7
 A500    1.2-2.x,3.1  O  Fat   ½-2          01234     7
 A500+   2.x,3.1      E Super  1-2          01234     7
>CDTV    1.3,2.x,3.1? O ?Fat?  1   (x) x    01234     7
>A600    2.05,3.1     E Fatter 1/2  x       0  3    x 7
>A1200*  3.0,3.1      A  AGA   1/2  x         2346p x 14
>A1400   3.0,3.1      A  AGA   1/2  x         2??   x 25/28
>CD³²    3.1          A  AGA   2          x   23    x 14     x
 A2000   1.2-2.x,3.1  O  Fat   ½/1          012346p   7
 A2000+  1.2-2.x,3.1  E  Fat   ½/1          012346p   7
>A2500   1.2-2.x,3.1  O  Fat   ½/1            23      25                  x
>A3000   1.3/2.x,3.1  E Ftr/Sp 1/2             346p   16/25/30         x
>A3000UX UNIX         E Ftr/Sp 1/2             346p   25        x      x
>A4000   3.0,3.1      A  AGA   2               346p x '30/25           x
 A4000T* 3.1          A  AGA   2                46p x '40/25           x
XWalker* 3.2          A  AGA   1/2             3  p x 'EC30/40
>DraCo   AmigaOS      -   -     -                6?   50

* Amiga 3000 has always MMU and math co-processor. (?)
* Blizzard turbos can have Kickstart ROM ReKicked 100% transparently, so
  any kickstart version goes!
* Amiga 3000 Tower has a HD floppy drive by default?
* Amiga 4000 Tower has 68040 @ 25 MHz or 68060 @ 50 MHz, AmigaOS 3.1 and
  SCSI-II controller (built in, not A4091?)
X Walker has a SuperIO chip.
* Draco has Altais gfx card. (see rs:identify.library.rs)


 Check PCMCIA: Find 'card.resource'    600/1200/(570?)
 Check CDTV: Find 'cdtv.device'
 Check A690ID: FindResident 'A690ID'   570  (A500 CD-ROM/CDTV expansion)
 Check AT-IDE: Find interrupt 'AT-IDE' 600/1200/4000
 Check Akiko: Test GfxBase.ChunkyToPlanarPtr CD³² [OR HW emul card]
 Check NVRAM: Test Nonvolatile/GetNVInfo() maxstorage
 Check UNIX: Find any bootable UNI/01 partition
 Check A3000: Ramsey-Chip rev < $F  (that is $D)
 Check A4000: Ramsey-Chip rev >= $F
 Check A2500: Match ConfigDev for A2620/A2630 turbo card
 Check DraCo: Find 'draco.resource'
 Check UAE: FindName(execbase.intrlist,'UAE filesystem')

 ROM:
                                                      || 256 KB
     30: 1000old with KS1.0                           \/
     31: 1000 with KS 1.1 ntsc
     32: 1000 with KS 1.1 pal
  33 34: All but  1200, 4000, CD³², 500+, 600
     35: Beta, not in chip                            ||
     36: Early 3000                                   \/ 512 KB
     37: All but 1000[old], 1200, 4000, CD³²
     38: Not in chip
     39: A1200, A1400, A4000
     40: All but A1000[old]
     41: Not in chip
     42: Not in chip
X    43: Walker (AmigaOS 3.2)                        || 1024 KB
                                                     \/

    - Agnus Hardware Stats -

                        MODEL   VIDEO    CHIPRAM         CHIP TYPE
        Agnus           8361    NTSC       512k     A1000 Subsystem DIP
        Agnus           8361    NTSC       512k     A1000 Subsystem DIP
        Fat Agnus       8370    NTSC       512k     DIP
        Fat Agnus       8370    NTSC       512k     PLCC
        Fat Agnus       8371    PAL        512k     DIP
        Fat Agnus       8371    PAL        512k     PLCC
        Fat Agnus       8372    NTSC/PAL   512k     PLCC
        Fatter Agnus    8372a   NTSC/PAL  1024k     PLCC
        Super Agnus     8372b   NTSC/PAL  2048k     PLCC A3000
        Super Agnus     8375    NTSC/PAL  2048k     PLCC A500+
        Alice                   NTSC/PAL  2048k     PLCC A4000/A1200


  Question: Why doesn't SCSI work on the A4000?
    Answer: It does. But because of a bug in early versions of the Zorro-III
            DMA controller (the "Buster" chip), DMA SCSI controllers didn't
            work properly. This problem can be fixed (by replacing the early
            revision 9 Buster with a revision 11 version) or avoided
            altogether (by using a SCSI controller that doesn't use the
            Zorro-III bus, like the one built into the Warp Engine
            accelerator).

 ENDC

	movem.l	a4/a5,-(sp)
	bsr.b	__Main
	movem.l	(sp)+,a4/a5
	move.l	d0,-(sp)

	lea	(CursorOn,pc),a0
	bsr	Printf

	tst.b	WBMode
	bpl.b	.cli_noclose

	move.l	a5,a6

	tst.b	NewKick
	bmi.b	.close_up

	lea	(PressReturn,pc),a0
	bsr	Printf

	subq.l	#4,sp
	move.l	OutputFH,d1
	move.l	sp,d2
	moveq	#1,d3
	call	Read
	addq.l	#4,sp

.close_up	move.l	OutputFH,d1
	call	Close
.cli_noclose
	move.l	(ExecBase00,pc),a6
	move.l	_DosBase,a1
	call	CloseLibrary

	move.l	(sp)+,d0
	rts


_error	moveq	#RETURN_ERROR,d0
	rts

__Main
	DBG	'bgma'

	move.l	(4).w,a6		Use (4).w
	bsr	GetDraCo

	DBG	'gdra'


	bsr	ExtAttnFlags
	move.w	d0,_AttnFlags

	DBG	'gatf'

	jsr	CacheClearU		Clear caches (now ExecBaseXX are valid)

	DBG	'cacc'

	lea	(_GfxName,pc),a1
	moveq	#0,d0
	call	OpenLibrary
	move.l	d0,_GfxBase
	beq	_error
	move.l	d0,a1
	call	CloseLibrary
	lea	(ExpName,pc),a1
	moveq	#0,d0
	call	OpenLibrary
	move.l	d0,_ExpBase
	beq	_error
	move.l	d0,a1
	call	CloseLibrary

	lea	(sStart,pc),a0
	bsr	Printf

	DBG	'seva'

	st	RamseyRev
	move.w	_AttnFlags,d0
	bsr	GetRamsey

;	move.w	#15,d0			debug

	beq.b	.no_ramsey
	move.w	d0,RamseyRev
	cmp.w	#15,d0
	slo	A3000ID
	shs	A4000ID
.no_ramsey
	DBG	'gram'

	st	GaryRev
	move.w	_AttnFlags,d0
	bsr	GetGary

;	move.w	#0,d0			debug
;	moveq	#1,d1

	beq.b	.no_gary
	move.w	d0,GaryRev
	call	Disable
	move.b	$00DE0000,_wasDSACK
	bpl.b	.is_DSACK
	bclr	#7,$00DE0000		Set DSACK mode...
.is_DSACK	call	Enable
.no_gary
	tst.b	A3000ID			A3000 must have both!
	beq.b	.no_a30gry
	tst.w	RamseyRev
	bpl.b	.no_a30gry
	clr.b	A3000ID
.no_a30gry

	DBG	'ggry'

	lea	(sMMUna,pc),a0
	move.l	a0,MMU
	lea	(sNullStr,pc),a0
	move.l	a0,MMUStatus
	btst	#AFB_68030,_AttnFlags+1
	beq.b	.lowpros
	st	_EC
.lowpros	jsr	GetMMU
	move.l	d0,_MMUID
	beq.b	.nommu			is 'EC' model
	lea	(sNotActiveStr,pc),a0
	tst.l	d1
	beq.b	.msetoff
	lea	(sRunningStr,pc),a0
.msetoff	move.l	a0,MMUStatus
	lea	(MMUTable,pc),a0
	lea	MMU,a1
	subq.l	#1,d0
	bsr	PutWStrPtr
	clr.l	EC
	clr.l	_EC
.nommu
	DBG	'gmmu'

	bsr	GetGayle
	move.w	d0,GayleRev
	cmp.w	#13,d0
	seq	AGAGayleID
	bsr	GetPaula
	move.w	d0,PaulaRev

	DBG	'ggay'

	bsr	GetGfxChip
	move.b	d0,GfxChipID+3
	move.w	d1,GfxChipRev
	lea	(GfxChipTable,pc),a0
	lea	GfxChip,a1
	bsr	PutWStrPtr
	lea	GChipRevBuffer,a2
	move.l	a2,GfxChipRev_ptr
	lea	(sRev,pc),a0
	lea	GfxChipRev,a1
	move.w	(a1),d0
	bmi.b	.is_OCS
	bsr	Sprintf
.is_OCS
	DBG	'ggcp'

	bsr	GetAnimChip
	move.b	d0,AnimChipID+3
	lea	(AnimChipTable,pc),a0
	lea	AnimChip,a1
	bsr	PutWStrPtr

	DBG	'gacp'

	bsr	GetGfxLibEmul
	move.l	d0,GfxLibEmul
	move.w	d1,BandWidth
	lea	(GfxLibEmulTable,pc),a0
	lea	GfxLibEmul_ptr,a1
	bsr	PutWStrPtr
	lea	DBWBuffer,a2
	move.l	a2,BandWidth_ptr
	cmp.w	#2,GfxLibEmul+2		AGA?
	bne.b	.not_aga
	lea	(sDBWFmt,pc),a0
	lea	BandWidth,a1
	bsr	Sprintf
.not_aga
	DBG	'ggbe'

	jsr	GetCPU

	DBG	'gcpu'

	jsr	GetProcInfo

	DBG	'gpin'

	move.l	_100kHz,d0
	divu.w	#10,d0
	swap	d0
	move.l	d0,MHz
	move.l	CPUID,d0
	lea	(CPUTable,pc),a0
	lea	CPU,a1
	bsr	PutWStrPtr


	bsr	GetMisc

	DBG	'gmsc'

	tst.b	CardSlotID
	bne.b	.has_slot
	bsr	GetCardSlot
	move.b	d0,CardSlotID

	DBG	'gcsl'
.has_slot
;	clr.l	CardSlotID		debug

	lea	(sNullStr,pc),a0
	tst.l	UAEID
	beq.b	.nouae
	lea	(sUAE,pc),a0
.nouae	move.l	a0,AfterMG_ptr

	lea	(sNA,pc),a0
	tst.l	HWClockID
	beq.b	.nohwclock
	lea	(sClockFound,pc),a0
.nohwclock	move.l	a0,HWClock_ptr


	tst.b	ATIDEID
	bne.b	.has_ATIDE
	bsr	GetATIDE
	move.b	d0,ATIDEID

	DBG	'gide'
.has_ATIDE

	lea	(sFna,pc),a2
	move.w	_AttnFlags,d0
	bsr	GetFPU
	move.b	d0,FPUID+3
	beq.b	.nofpu

	IFGT	0
	move.l	FPUCompareTime,-(sp)	dbug
	lsr.l	#8,d0
	lsr.l	#8,d0
	divu.w	#10,d0
	swap	d0
	move.l	d0,-(sp)
	lea	(FPUTable,pc),a0
	move.l	FPUID,d0
	add.l	d0,d0
	add.w	(a0,d0.l),a0
	move.l	a0,-(sp)
	lea	(sFPUFmt,pc),a0
	move.l	sp,a1
	lea	FPUBuffer,a2
	bsr	Sprintf
;;	addq.l	#8,sp
	lea	(3*4,sp),sp		dbug
.nofpu	move.l	a2,FPU_ptr
	ELSE

	lea	(FPUTable,pc),a0
	move.l	FPUID,d0
	add.l	d0,d0
	add.w	(a0,d0.l),a0
	move.l	a0,-(sp)
	lea	(sFPUFmt,pc),a0
	move.l	sp,a1
	lea	FPUBuffer,a2
	bsr	Sprintf
	addq.l	#4,sp
.nofpu	move.l	a2,FPU_ptr
	ENDC

	DBG	'gfpu'


	tst.l	A4000ID
	beq.b	.not_a4000t
	move.b	A4091ID,A4000TID	A4091 is checked in GetMisc subr
.not_a4000t
	bsr	GetGfxBoards
	DBG	'ggbo'

	bsr	GetSndCards
	DBG	'gsca'

	bsr	GetExpBoards
	DBG	'gebo'

	bsr	GetChipMem
	move.l	d0,ChipMemd
	move.l	(ExecBase00,pc),a6
	move.l	(MaxLocMem,a6),d0
	lsr.l	#8,d0			/10
	lsr.l	#2,d0
	move.l	d0,ChipMem

	DBG	'gcme'

	bsr	GetFastMem
	move.l	d0,FastMem

	DBG	'gfme'

	lea	(sNullStr,pc),a0
	move.l	a0,VirtMem_ptr
	bsr	GetVirtMem
	move.l	d0,VirtMem
	beq.b	.novirtmem
	lea	sVirtMemBuf,a2
	move.l	a2,VirtMem_ptr
	lea	(sVirtMemFmt,pc),a0
	lea	VirtMem,a1
	bsr	Sprintf
.novirtmem
	DBG	'gvme'

	move.w	_AttnFlags,d0
	bsr	GetChipRomVer
	move.l	d0,RomVer
	move.l	d1,RomChkSum
	bsr	GetKickStr
	move.l	d0,RomVerS

	DBG	'gcro'

	bsr	GetCRomVer
	move.l	d0,CRomVer
	move.l	d1,CRomChkSum
	bsr	GetKickStr
	move.l	d0,CRomVerS

	DBG	'grom'

	lea	(sNullStr,pc),a2
	move.l	RomVer,d0
	cmp.l	CRomVer,d0
	bne.b	.rekickrom
	move.l	RomChkSum,d0
	cmp.l	CRomChkSum,d0
	beq.b	.rom_is_same
.rekickrom	lea	sROMBuf,a2
	lea	(sReKickROM,pc),a0
	lea	CRomVer,a1
	bsr	Sprintf
.rom_is_same	move.l	a2,ReKickROM_ptr


	bsr	GetWBVersion
	move.l	d0,WBVer
	bsr	GetWBStr
	move.l	d0,WBVerS

	DBG	'gwbv'

	lea	(sNoSetPatch,pc),a0
	move.l	a0,SetPatchVerPtr
	bsr	GetSetPatchVersion
	tst.l	d0
	beq.b	.nosetpatch
	move.l	d0,-(sp)
	lea	sSetPatchBuf,a2
	lea	(sSetPatchVerFmt,pc),a0
	move.l	sp,a1
	bsr	Sprintf
	move.l	a2,SetPatchVerPtr
	addq.l	#4,sp
.nosetpatch
	DBG	'gspv'

	lea	ExpBoardsBuffer,a0
	move.l	a0,ExpBoards_ptr
	bsr	GetBoards

	DBG	'gboa'

	bsr	GetOtherChips

	DBG	'goth'

	bsr	EvaluateFormulas
	move.l	d0,MachineGuess

	DBG	'deva'

	lea	(sRaport,pc),a0
	lea	Params,a1
	bsr	Printf

	DBG	'prnt'

	tst.w	GaryRev
	bmi.b	.nogary
	call	Disable
	tst.b	_wasDSACK
	bpl.b	.was_DSACK
	bset	#7,$00DE0000		Set BERR if it was on originally!
.was_DSACK	call	Enable
.nogary
	moveq	#RETURN_OK,d0
	rts


PutWStrPtr	add.w	d0,d0
	add.w	(a0,d0.w),a0
	move.l	a0,(a1)
	rts


;  IN: a0=buffer
GetBoards	movem.l	d0-a6,-(sp)
	move.l	a0,a4
	move.l	(ExecBase00,pc),a6
	lea	(.boardsname,pc),a1
	moveq	#2,d0
	call	OpenLibrary
	move.l	d0,d7
	beq	.exit

	move.l	d7,a6
	moveq	#0,d0
	jsr	(-36,a6)		call	AllocBoardInfo
	move.l	d0,d6
	beq	.closeboards

	moveq	#-1,d0			Any boards available?
	bsr	FindConfigDev
	beq	.noboards
	lea	(.expansion,pc),a0
.copy	move.b	(a0)+,(a4)+
	bne.b	.copy
	subq.l	#1,a4
	sub.l	a1,a1

.next	move.l	d6,a0
	jsr	(-42,a6)		call	NextBoardInfo
	tst.l	d0
	beq.b	.done

	move.l	d0,-(sp)
	move.l	(16,a0),-(sp)		bi_ExSize
	move.l	(12,a0),-(sp)		bi_ExAddress
	move.l	(32,a0),-(sp)		bi_ProdName
	move.l	(28,a0),-(sp)		bi_ManuName
	move.l	(24,a0),-(sp)		bi_ProdID
	move.l	(20,a0),-(sp)		bi_ManuID
	move.l	sp,a1
	lea	(.boardsfmt,pc),a0
	move.l	a4,a2
	bsr	Sprintf
	lea	(6*4,sp),sp
.findend	tst.b	(a4)+
	bne.b	.findend
	subq.l	#1,a4

	move.l	(sp),a0
	cmp.w	#$2140,(cd_Rom+er_Manufacturer,a0)	Blizzard PPC?
	bne.b	.not_blizppc
	cmp.b	#110,(cd_Rom+er_Product,a0)
	bne.b	.not_blizppc
	cmp.w	#$00F0,(cd_BoardAddr,a0)
	bne.b	.not_blizppc
	lea	(.blizzppc,pc),a0
	pea	$F00010
	move.l	sp,a1
	move.l	a4,a2
	bsr	Sprintf
	addq.l	#4,sp
.blfindend	tst.b	(a4)+
	bne.b	.blfindend
	subq.l	#1,a4

.not_blizppc
	move.l	(sp)+,a1
	bra.b	.next
.done
.noboards
.freebi	move.l	d6,a0
	jsr	(-48,a6)		call	FreeBoardInfo
.closeboards	move.l	d7,a1
	move.l	(ExecBase00,pc),a6
	call	CloseLibrary
.exit	movem.l	(sp)+,d0-a6
	rts

.boardsname	dc.b	'boards.library',0	BOARDSNAME
.expansion	dc.b	'     Expansion board(s):',10,0
.boardsfmt	dc.b	'%s/%s: %s %s (@%s %s)',10,0
.blizzppc	dc.b	'          Blizzard PPC serial number: %7s',10,0
	CNOP	0,4


GetExpBoards	movem.l	d0-d1/a0-a1,-(sp)
	lea	(ExpBoardTable1,pc),a0	If you have A2000 you propably
.loop1	move.l	(a0)+,d0		have some expansion stuff in it!!
	beq.b	.done1
	bsr	FindConfigDev
	sne	A2000EID
	bne.b	.done1
	bra.b	.loop1
.done1
	lea	(ExpBoardTable2,pc),a0	If any A500 expansion is found
.loop2	move.l	(a0)+,d0		A2000ID is cleared.
	beq.b	.done2
	bsr	FindConfigDev
	beq.b	.loop2
	st	A500EID
	clr.b	A2000EID
.done2

	tst.l	A690ID
	beq.b	.no_A500_CDROM
	st	A500EID
	clr.b	A2000EID
.no_A500_CDROM
	movem.l	(sp)+,d0-d1/a0-a1
	rts

;;; ExpBoardTables

EXPBRD	MACRO
	dc.l	($\1<<16)!\2
	ENDM

	CNOP	0,4
ExpBoardTable2
	EXPBRD	202,32	A560 Memory Module
	EXPBRD	3F2,68	MicroBotics VXL RAM*32
	EXPBRD	3F2,69	MicroBotics VXL 68030 turbo
	EXPBRD	420,5	Supra 500 HD/RAM interface
	EXPBRD	420,9	Supra 500XP
	EXPBRD	420,12	Supra 500XP/Wordsync
	EXPBRD	420,13	Supra 500XP/Wordsync
;500/2000!!!	EXPBRD	7E1,10	GVP Series II (A500) memory board
;500/2000!!!	EXPBRD	7E1,11	GVP Series II (A500) SCSI ctrl
	EXPBRD	801,4	BSC Oktagon 500
	EXPBRD	82C,4	BSC Oktagon 500
	EXPBRD	2062,1	Expansion Systems DataFlyer 500 HD Ctrl
	dc.l	0

	CNOP	0,4
ExpBoardTable1
	;Harlequin
	EXPBRD	851,1	Resolver
	EXPBRD	0851,2	Vivid 24
	EXPBRD	07E1,68	Rembrandt
	EXPBRD	0845,2	Visiona
	;OpalVision
	EXPBRD	838,0	FireCracker
	EXPBRD	838,1	FireCracker
	EXPBRD	406,0	Lowell A2410
	EXPBRD	3EC,245	Kronos/C Ltd A2410

	EXPBRD	0891,1	EGS
	EXPBRD	07E1,32	IV24
	;Video Toaster
	EXPBRD	2140,34	CyberVision 64/4MB
	EXPBRD	2140,50	CyberVision 64/3D
	EXPBRD	2140,67	CyberVision 64/3D
	EXPBRD	85E,1	GDA-1
	EXPBRD	86A,1	Horizon
	EXPBRD	86A,2	Blackbox 
	EXPBRD	86A,3	Voyager
	EXPBRD	877,12	Picasso II
	EXPBRD	877,13	Picasso II
	EXPBRD	877,24	Picasso IV
	EXPBRD	4754,16	RetinaZ3
	EXPBRD	4754,19,sAltais
	;RetinaZ2? Domino? Piccolo? PiccoloSD64? RainBowIII? 1600GX?

	EXPBRD	201,1	A2088/A2288
	EXPBRD	201,2	A2286
	EXPBRD	201,103 A2386SX
	EXPBRD	866,1	D. Salamon Golden Gate II BridgeCard

	EXPBRD	2017,7	GoldenGate 80386
	EXPBRD	2017,9	GoldenGate 80486
	;EMC 486SLC

	EXPBRD	200,2	3-State Megamix 2000
	EXPBRD	202,1	A2090(A)
	EXPBRD	202,4	A2090B
	EXPBRD	202,9	A2060
	EXPBRD	202,69	A2232 (prototype)
	EXPBRD	202,70	A2232
	EXPBRD	202,80	A2620 68020 turbo
	EXPBRD	202,81	A2640 68030 turbo
	EXPBRD	202,84	A4091 SCSI/SCSI-II 		???
	EXPBRD	202,112	A2065
	EXPBRD	2F4,105	A2000 68040 turbo
	EXPBRD	2F4,150  ???  68040 turbo
	EXPBRD	3EC,4	Kronos 2000			???
	EXPBRD	3ED,1	A-Squared LIVE!
	EXPBRD	3F2,68	MicroBotics 68030 turbo???
	EXPBRD	3F2,150	MB HardFrame/2000?
	EXPBRD	3F2,158	MB HardFrame/2000?
	EXPBRD	3FF,255	Dual serial port
	EXPBRD	404,57	A2000 68030 turbo
	EXPBRD	404,87	A2000 68030 turbo
	EXPBRD	41D,1	Amerisar Ethernet
	EXPBRD	420,1	Supra 4x4
	EXPBRD	420,3	Supra 2000 DMA
	EXPBRD	420,11	Supra 2400zi internal modem
	EXPBRD	420,16	Supra 2400zi internal modem
	EXPBRD	422,17	Mag40 68040 Turbo
	EXPBRD	6E1,8	GVP Series I HD Ctrl
	EXPBRD	7E1,3	GVP Hard Card 0
	EXPBRD	7E1,8	GVP A3001 Expansion board
;;	EXPBRD	7E1,9	GVP A3001 RAM			500/2000!!!
	EXPBRD	7E1,255	GVP GForce 68040 Turbo
	EXPBRD	7EA,105	68040 turbo???
;;wasina500?	EXPBRD	801,6	BSC Oktagon 2008
;;wasina500?	EXPBRD	801,8	BSC Oktagon 2008
	EXPBRD	801,16	BSC Parallel/Serial
	EXPBRD	801,32	BSC Frame Buffer
	EXPBRD	801,64	BSC ISDN Master
	EXPBRD	802,4	Kronos 2000			???
	EXPBRD	817,1	ICD 2000 SCSI
	EXPBRD	817,4	ICD 2080 Board
	EXPBRD	81D,9	GVP A2000-Ram8/2
	EXPBRD	828,16	Applied LD2000 Modem???
	EXPBRD	82C,5	BSC Memory Master Card
;;wasina500?	EXPBRD	82C,6	BSC Oktagon 2008		???
;;wasina500?	EXPBRD	82C,8	BSC Oktagon 2008
	EXPBRD	82C,18	?
	EXPBRD	82C,64	BSC ISDN Master
	EXPBRD	87B,21	Emplant MAC emu
	EXPBRD	1028,87	Imtromix hurricane 2800
	EXPBRD	2017,7	?
	EXPBRD	2100,1	ReadySoft Amax II+ Mac emu
	EXPBRD	2132,27	?
	EXPBRD	4754,4	Macrosystems Framegrabber?
	EXPBRD	A9AD,17	Reis-ware Scan King
	EXPBRD	819,2	Kupke Golem SCSI II
	dc.l	0
;;;


GetGfxBoards	movem.l	d0-d1/a0-a6,-(sp)
	lea	GfxBoardI,a4
	lea	(sNullStr,pc),a0
	move.l	a0,(a4)
	lea	GfxBoardBuffer+2,a3
	move.l	a3,(GfxBoard-GfxBoardI,a4)
	subq.l	#2,a3

	move.l	(4).w,a6
	cmp.w	#39,(LIB_VERSION,a6)
	blo	.nocgfx
	lea	(.cgfxname,pc),a1
	moveq	#41,d0
	call	OpenLibrary
	tst.l	d0
	beq.b	.nocgfx
	move.l	d0,a6

	clr.l	-(sp)
	pea	(12).w		; Cybervision PPC
	pea	CYBRBIDTG_MONITORID
	move.l	sp,a0
	call	BestCModeIDTagList
	addq.l	#1,d0
	beq.b	.no_b1

	lea	(.cvppc,pc),a0
	bsr	.copy1

.no_b1	move.w	#14,(4+2,sp)	; Inferno
	move.l	sp,a0
	call	BestCModeIDTagList
	addq.l	#1,d0
	beq.b	.no_b2

	lea	(.inferno,pc),a0
	bsr	.copy1

.no_b2	lea	(3*4,sp),sp
	move.l	a6,a1
	move.l	(4).w,a6
	call	CloseLibrary
.nocgfx
	lea	(GfxBoardTable,pc),a2

.loop	movem.l	(a2)+,d0/a0
	tst.l	d0
	beq.b	.done
	bsr	FindConfigDev
	beq.b	.loop
	bsr.b	.copy1
	bra.b	.loop

.done	move.b	#10,(a3)
	movem.l	(sp)+,d0-d1/a0-a6
	rts

.copy1	lea	(sGfxBoards,pc),a1
	move.l	a1,(a4)			Set introducer
	move.b	#'/',(a3)+
	move.b	#' ',(a3)+
.copy	move.b	(a0)+,(a3)+
	bne.b	.copy
	subq.l	#1,a3
	rts

.cgfxname	dc.b	'cybergraphics.library',0
.cvppc	dc.b	'CyberVision PPC',0
.inferno	dc.b	'Inferno',0
	CNOP	0,2


GetSndCards	movem.l	d0-d1/a0-a4,-(sp)
	lea	SndCardI,a4
	lea	(sNullStr,pc),a0
	move.l	a0,(a4)
	lea	SndCardBuffer+1,a3
	move.l	a3,(SndCard-SndCardI,a4)
	lea	(SndCardTable,pc),a2
	lea	(sSndCards,pc),a1
	subq.l	#1,a3

.loop	movem.l	(a2)+,d0/a0
	tst.l	d0
	beq.b	.done
	bsr.b	FindConfigDev
	beq.b	.loop
	move.l	a1,(a4)			Set introducer
	move.b	#'/',(a3)+
.copy	move.b	(a0)+,(a3)+
	bne.b	.copy
	subq.l	#1,a3
	bra.b	.loop

.done	move.b	#10,(a3)
	movem.l	(sp)+,d0-d1/a0-a4
	rts



;  IN: d0=manu<<16+prod
; OUT: d0=ConfigDev if found, else zero, ccs set!
FindConfigDev	movem.l	d1-d2/a0-a1/a6,-(sp)
	move.l	_ExpBase,a6
	sub.l	a0,a0
	moveq	#0,d1
	move.w	d0,d1
	clr.w	d0
	swap	d0
	moveq	#-1,d2
	cmp.w	d2,d0
	bne.b	.ok1
	move.l	d2,d0
.ok1	cmp.w	d2,d1
	bne.b	.ok2
	move.l	d2,d1
.ok2	call	FindConfigDev
	tst.l	d0
	movem.l	(sp)+,d1-d2/a0-a1/a6
	rts


GetOtherChips	movem.l	d0-a6,-(sp)
	lea	ChipsBuffer+2,a2
	move.l	a2,CustomChips

	subq.l	#2,a2
	lea	(sPaula,pc),a0
	lea	PaulaRev,a1
	move.w	(a1),d0
	bmi.b	.nopaula
	bsr.b	.print
.nopaula
	lea	(sRamsey,pc),a0
	lea	RamseyRev,a1
	tst.w	(a1)
	bmi.b	.noramsey
	bsr.b	.print
.noramsey
	lea	(sGary,pc),a0
	lea	GaryRev,a1
	tst.w	(a1)
	bmi.b	.nogary
	bsr.b	.print
.nogary
	lea	(sGayle,pc),a0
	lea	GayleRev,a1
	move.w	(a1),d0
	bmi.b	.nogayle
	bsr.b	.print
.nogayle
	tst.l	AkikoID
	beq.b	.noakiko
	lea	(sAkiko,pc),a0
	bsr.b	.print
.noakiko
	movem.l	(sp)+,d0-a6
	rts

.print	tst.b	(a2)+
	bne.b	.print
	move.b	#',',(-1,a2)
	move.b	#' ',(a2)+
	bra	Sprintf


;  IN: d0=AttnFlags ('030 info available)
; OUT: d0=ramseyrev, if z clear
GetRamsey	movem.l	d6-d7/a5-a6,-(sp)
	moveq	#0,d6
	moveq	#0,d7
	tst.l	NoHW
	bne.b	.no_chip2
	btst	#AFB_68020,d0
	beq.b	.no_chip2

	lea	(.supramsey,pc),a5
	move.l	(ExecBase00,pc),a6
	call	Disable
	call	Supervisor		Ramsey revision:

	cmp.w	#$D,d6
	blo.b	.no_chip		Minimum!
	cmp.w	#$F+5,d6		Maximum! ???
	bhi.b	.no_chip

	moveq	#-1,d7

.no_chip	call	Enable
.no_chip2	move.l	d6,d0
	tst.l	d7			<- Does set ccs
	movem.l	(sp)+,d6-d7/a5-a6	<- Doesn't set ccs!!!
	rts

.supramsey	move.b	$DE0043,d6
;	move.b	#$F,d6			debug
	rte


;  IN: d0=AttnFlags ('030 info available)
; OUT: d0=garyrev, if z clear
GetGary	movem.l	d1-d2/d6-d7/a0/a6,-(sp)
	moveq	#0,d6
	moveq	#0,d7
	tst.l	NoHW
	bne.b	.no_chip2
	btst	#AFB_68020,d0
	beq.b	.no_chip2

	move.l	(ExecBase00,pc),a6
	call	Disable

;	Gary revision:
	lea	$DE1002,a0
	clr.b	(a0)
	jsr	CacheClearU
	cmp.b	#$7F,(a0)
	nop
	bne.b	.no_chip

	clr.b	(a0)
	nop
	moveq	#7,d0
.loop	tst.b	(a0)
	nop
	bpl.b	.skip
	bset	d0,d6
.skip	dbf	d0,.loop

	cmp.w	#$FF,d6
	beq.b	.no_chip		All bits 1 -> No chip!
	cmp.w	#209,d6			Test for Gaylething... :)
	beq.b	.no_chip		(not really needed tho)

	moveq	#-1,d7

.no_chip	call	Enable
.no_chip2	move.l	d6,d0
	tst.l	d7			<- Does set ccs
	movem.l	(sp)+,d1-d2/d6-d7/a0/a6	<- Doesn't set ccs!!!
	rts


;NAME   rev ADDR type chip Description
;---------------------------------------------------------------------------
;POTINP     016   R    P   Pot pin data read
;
;     Bit
;    Number  Name              Function
;
;    07-01   X       Paula 8364 chip revision identification number
;                    (presently all zeroes)

; OUT: d0=paula revision or -1
GetPaula	tst.l	NoHW
	bne.b	.nohw
	IFND	potgor
	move.w	$DFF000+potinp,d0	potgor
	ELSE
	move.w	$DFF000+potgor,d0
	ENDC

	and.w	#%11111110,d0
	lsr.w	#1,d0
	rts

.nohw	moveq	#-1,d0
	rts


; OUT: d0=Gayle revision or -1
GetGayle	movem.l	d1-a6,-(sp)
	tst.l	NoHW
	bne	.no_gayle

	move.l	(ExecBase00,pc),a6

	lea	$DFF000,a0
	lea	$DE1000,a1		Gayle port
	moveq	#0,d1
	call	Disable
	move.w	(intenar,a0),d0
	move.w	#$BFFF,(intena,a1)
	move.w	#$3FFF,d2
	cmp.w	(intenar,a0),d2
	bne.b	.skip1
	move.w	d2,(intena,a1)
	tst.w	(intenar,a0)
	bne.b	.skip1
	moveq	#1,d1
.skip1	move.w	d2,(intena,a0)
	or.w	#$8000,d0
	move.w	d0,(intena,a0)

	call	Enable
	tst.w	d1
	bne.b	.no_gayle

	moveq	#3,d2			Get revision:
	move.b	d1,(a1)
.loop	move.b	(a1),d0
	lsl.b	#1,d0
	addx.b	d1,d1
	dbra	d2,.loop
	moveq	#0,d0
	move.b	d1,d0
.exit	tst.b	d0
	bne.b	.exit2
.no_gayle	moveq	#-1,d0
.exit2	movem.l	(sp)+,d1-a6
	rts


;  IN: d0=version<<16+revision
; OUT: d0=ptr to null terminated kick version string (eg. '2.05',0)
GetKickStr	move.l	d1,-(sp)
	move.w	d0,d1
	swap	d0
	tst.w	d0
	beq.b	.no_rom
	sub.w	#30,d0
	cmp.w	#13,d0
	bls.b	.ok
	moveq	#14,d0
.ok	add.w	d0,d0
	lea	(_ks,pc),a0
	add.w	(a0,d0.w),a0
	cmp.w	#(37-30)*2,d0
	bne.b	.skip
	cmp.w	#175,d1			>37.175<
	bls.b	.skip
	addq.l	#(_sKS_05-_sKS7),a0
.skip	move.l	a0,d0
	move.l	(sp)+,d1
	rts
.no_rom	lea	(_sKNoROM,pc),a0
	bra.b	.skip
_wb	dc.w	_sKS0-_wb,_sKS1-_wb,_sKS2-_wb,_sKS3-_wb,_sKS4-_wb
	dc.w	_sKS5-_wb,_sKS6-_wb,_sKS7_2-_wb,_sKSWB-_wb,_sKS8-_wb
	dc.w	_sKS9-_wb,_sKSA-_wb,_sKSX-_wb
_ks	dc.w	_sKS0-_ks,_sKS1-_ks,_sKS2-_ks,_sKS3-_ks,_sKS4-_ks
	dc.w	_sKS5-_ks,_sKS6-_ks,_sKS7-_ks,_sKSH-_ks,_sKS8-_ks
	dc.w	_sKS9-_ks,_sKSH-_ks,_sKSH-_ks,_sKSA-_ks,_sKSX-_ks
_sKS0	dc.b	'1.0',0
_sKS1	dc.b	'1.1 ntsc',0
_sKS2	dc.b	'1.1 pal',0
_sKS3	dc.b	'1.2',0
_sKS4	dc.b	'1.3',0
_sKS5	dc.b	'1.4 beta',0
_sKS6	dc.b	'2.0 beta',0
_sKS8	dc.b	'3.0',0
_sKS9	dc.b	'3.1',0
_sKSA	dc.b	'3.2',0
_sKSX	dc.b	'unknown',0
_sKS7	dc.b	'2.04',0
_sKS_05	dc.b	'2.05',0
_sKSH	dc.b	'hack',0
_sKS7_2	dc.b	'2.0',0
_sKSWB	dc.b	'2.1',0
_sKNoROM
sNoSetPatch	dc.b	'version information not available',0
	CNOP	0,4


;  IN: d0=version<<16+revision
; OUT: d0=ptr to null terminated WB version string (eg. '2.1',0)
GetWBStr	move.l	d1,-(sp)
	move.w	d0,d1
	swap	d0
	tst.w	d0
	beq.b	.no_wb
	sub.w	#30,d0
	cmp.w	#11,d0
	bls.b	.ok
	moveq	#12,d0
.ok	add.w	d0,d0
	lea	(_wb,pc),a0
	add.w	(a0,d0.w),a0
.done	move.l	a0,d0
	move.l	(sp)+,d1
	rts
.no_wb	lea	(_sKNoROM,pc),a0
	bra.b	.done


ExtAttnFlags	movem.l	d1/d2/a0-a1/a6,-(sp)
	move.l	(4).w,a6		Use (4).w
	move.w	(AttnFlags,a6),d2
	tst.l	NoHW
	bne.b	.nohw
	cmp.w	#37,(LIB_VERSION,a6)
	bhs.b	.test060

	jsr	Test030_040_882
	or.w	d0,d2
;;	bra.b	.xit

.test060	btst	#AFB_68040,d2		You must have 68040 flag
	beq.b	.no060			set to have 68060.
	tst.b	d2			Test #AFB_68060
	bmi.b	.is060			Is already valid!

	jsr	Test060			Test for 68060.
.is060
.no060
.nohw
.xit	move.w	d2,d0
	movem.l	(sp)+,d1/d2/a0-a1/a6
	rts


GetCardSlot	moveq	#0,d0
	move.w	GayleRev,d1
	cmp.w	#13,d1
	bne.b	.no_cardslot
	moveq	#-1,d0
.no_cardslot	rts



GetATIDE	movem.l	d1-a6,-(sp)
	lea	$00DA2000,a4		IDE port
	bsr.b	.TestIDEHW
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

.TestIDEHW	move.l	d0,-(sp)
	move.w	GayleRev,d1
	cmp.w	#13,d1
	bne.b	.nohw

	moveq	#9,d0			Try 10 times:
	move.b	d0,(sp)
.try_again	move.b	(3,sp),($0018,a4)
	move.b	($0010,a4),d1
	move.b	($001C,a4),d0
	move.l	d0,a0
	and.b	#$C0,d0
	beq.b	.has2
	cmp.b	#$C0,d0
	beq.b	.nohw
	tst.b	d0
	bpl.b	.has
	move.l	a0,d0
	eor.b	d1,d0
	and.b	#$FD,d0
	bne.b	.nohw
	moveq	#2,d0
	bra.b	.exit

.has2	btst	#4,(3,sp)
	bne.b	.nohw
	subq.b	#1,(sp)
	bmi.b	.nohw
	bsr.b	WaitVBL
	bra.b	.try_again

.valid	moveq	#1,d0
	bra.b	.exit

.has	moveq	#$12,d0
	move.b	d0,($0010,a4)
	cmp.b	($0010,a4),d0
	bne.b	.nohw
	moveq	#$34,d0
	move.b	d0,($0010,a4)
	cmp.b	($0010,a4),d0
	beq.b	.valid
.nohw	moveq	#0,d0
.exit	addq.w	#4,sp
	rts


WaitVBL	moveq	#1,d0
WaitBlanks	movem.l	d2/a2/a3/a6,-(sp)
	move.l	d0,d2
	lea	(-$0022,sp),sp
	move.l	sp,a2
	move.b	#4,(8,a2)
	clr.b	(9,a2)
	clr.l	(10,a2)
	clr.b	(14,a2)
	move.b	#4,(15,a2)
	suba.l	a1,a1
	call	FindTask
	move.l	d0,($0010,a2)
	lea	($0014,a2),a0
	move.l	a0,(8,a0)
	addq.l	#4,a0
	clr.l	(a0)
	move.l	a0,-(a0)
	lea	(-$0028,sp),sp
	move.l	sp,a3
	lea	(TimerDevName,pc),a0
	move.l	a3,a1
	moveq	#UNIT_VBLANK,d0
	moveq	#0,d1
	call	OpenDevice
	tst.l	d0
	bne.b	.exit
	move.l	a2,(IO+MN_REPLYPORT,a3)
	move.l	a3,a1
	move.w	#TR_ADDREQUEST,(IO_COMMAND,a1)
	clr.l	(IOTV_TIME+EV_HI,a1)
	move.l	d2,(IOTV_TIME+EV_LO,a1)
	call	DoIO
	move.l	a3,a1
	call	CloseDevice
.exit	lea	($004A,sp),sp
	movem.l	(sp)+,d2/a2/a3/a6
	rts


GetDraCo	movem.l	d0-a6,-(sp)
	move.l	(4).w,a6		Use (4).w
	lea	(.DraCoName,pc),a1
	call	OpenResource
	tst.l	d0
;;DEBUG
	beq.b	.nodraco
	st	DraCoID
	st	NoHW
.nodraco	movem.l	(sp)+,d0-a6
	rts

.DraCoName	dc.b	'draco.resource',0
	CNOP	0,4


GetUAE	movem.l	d0-a6,-(sp)
	move.l	(4).w,a6		Use (4).w
	call	Forbid
	move.l	(IVEXTER+IV_DATA,a6),d0
	beq.b	.nouae
	move.l	d0,a0			a0=lh
	lea	(.UAEName,pc),a1
	call	FindName
	tst.l	d0
	beq.b	.nouae
	st	UAEID
.nouae	call	Permit
	movem.l	(sp)+,d0-a6
	rts

.UAEName	dc.b	'UAE filesystem',0
	CNOP	0,4


GetPowerUP	movem.l	d0-a6,-(sp)
	lea	sPowerUPBuf,a0
	move.l	a0,PowerUP_ptr
	clr.b	(a0)

	move.l	(4).w,a6		Use (4).w
	cmp.w	#36,(LIB_VERSION,a6)
	blo	.oldkick

	moveq	#3*4,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	call	AllocVec
	tst.l	d0
	beq	.nomem
	move.l	d0,a5

	lea	(.ppcName,pc),a1
	moveq	#44,d0
	call	OpenLibrary
	tst.l	d0
	beq	.noppc
	move.l	d0,a6

	move.l	#PPCINFOTAG_CPUCOUNT,(a5) Get CPU count
	move.l	a5,a0
	call	PPCGetInfo
	move.l	d0,d7
	beq	.nocpus

	st	PowerUPID

	lea	(sPowerUPFmt0,pc),a0
	move.l	d7,-(sp)
	move.l	sp,a1
	lea	sPowerUPBuf,a2
	bsr	Sprintf
	addq.l	#4,sp
.findend1	tst.b	(a2)+
	bne.b	.findend1
	subq.l	#1,a2

	moveq	#0,d6
.cpu_loop
	moveq	#-1,d5
	move.l	#PPCINFOTAG_CPU,(a5)	Version of the CPU
	move.l	d6,(4,a5)
	move.l	a5,a0
	call	PPCGetInfo
	moveq	#CPU_603,d1		3
	moveq	#CPU_604e,d2		9
	cmp.l	d1,d0
	blo.b	.unknown1
	cmp.l	d2,d0
	bhi.b	.unknown1
	move.l	d0,d5
.unknown1
	moveq	#10,d0
	cmp.w	#45,(LIB_VERSION,a6)
	blo.b	.noppldiv
	move.l	#PPCINFOTAG_CPUPLL,(a5)	PLL Divider of the CPU
	move.l	d6,(4,a5)
	move.l	a5,a0
	call	PPCGetInfo
	move.l	d0,d1
	and.l	#$FFFFFFF0,d1
	bne.b	.noppldiv
	moveq	#10,d0
.noppldiv	move.l	d0,-(sp)

	move.l	#PPCINFOTAG_CPUREV,(a5)	Get CPU revision
	move.l	d6,(4,a5)
	move.l	a5,a0
	call	PPCGetInfo
	lsl.l	#8,d0		; ddccbbaa -> ccbbaa00
	lsr.w	#8,d0		; ccbbaa00 -> ccbb00aa
	move.l	d0,-(sp)

	move.l	#PPCINFOTAG_CPUCLOCK,(a5) Clock of the CPU (Get CPU MHz)
	move.l	d6,(4,a5)
	move.l	a5,a0
	call	PPCGetInfo
	move.l	d0,-(sp)

	pea	(sPPCxx,pc)
	move.l	d5,d0
	bmi.b	.unknown2
	lea	(PowerPCTable,pc),a0
	move.l	sp,a1
	bsr	PutWStrPtr

	move.l	d5,d0
	lea	(PowerPCPLLTable,pc),a0
	add.w	d0,d0
	lea	(12,sp),a1
	add.w	(a0,d0.w),a0
	move.l	(4,sp),d0
	move.l	(a1),d1
	mulu.w	#10,d0
	add.w	d1,d1
	divu.w	0(a0,d1.w),d0
	move.l	d0,(a1)
.unknown2
	lea	(sPowerUPFmt1,pc),a0
	move.l	sp,a1
	;a2=buffer
	bsr	Sprintf
	lea	(4*4,sp),sp
.findend2	tst.b	(a2)+
	bne.b	.findend2
	subq.l	#1,a2

	addq.l	#1,d6
	subq.l	#1,d7
	bne	.cpu_loop

	move.b	#10,(a2)+		LF
	clr.b	(a2)

.nocpus	move.l	a6,a1
	move.l	(4).w,a6		Use (4).w
	call	CloseLibrary
.noppc	move.l	a5,a1
	call	FreeVec
.nomem
.oldkick	movem.l	(sp)+,d0-a6
	rts

.ppcName	dc.b	'ppc.library',0
	CNOP	0,4


GetMisc	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(ExecBase00,pc),a6
	lea	(.CardName,pc),a1
	call	OpenResource
	tst.l	d0
	sne	CardSlotID

	move.l	(IVPORTS,a6),a0
	lea	(.ATIDEName,pc),a1
	bsr	.findnametest
	sne	ATIDEID

	lea	(DeviceList,a6),a0
	lea	(.CDTVDevName,pc),a1
	bsr	.findnametest
	sne	CDTVID

	lea	(.A690IDName,pc),a1
	call	FindResident
	tst.l	d0
	beq.b	.no_A690
	st	A690ID
	clr.b	CDTVID
.no_A690
	lea	(sNullStr,pc),a0
	move.l	a0,C2P
	move.l	_GfxBase,a0
	cmp.w	#40,(LIB_VERSION,a0)
	blo.b	.no40
	tst.l	(gb_ChunkyToPlanarPtr,a0)
	beq.b	.noC2P
	lea	(sHWC2P,pc),a0
	move.l	a0,C2P
	st	C2PID

	lea	(.NonvolName,pc),a1
	moveq	#40,d0
	call	OpenLibrary
	tst.l	d0
	beq.b	.nononvol
	move.l	d0,a6

	moveq	#1,d1			Kill requesters
	call	GetNVInfo
	tst.l	d0
	beq.b	.caseoffailure
	move.l	d0,a0

	move.l	(a0),d0			nvi_MaxStorage
	beq.b	.noNV
	cmp.l	#128*1024,d0		Estimated...
	slo	CD32NVRAMID		It's not an emulator!
.noNV	call	FreeNVData

.caseoffailure	move.l	a6,a1
	move.l	(ExecBase00,pc),a6
	call	CloseLibrary
.nononvol
.noC2P
.no40
	move.l	_DosBase,a1		Find UNI/01 partitions:
	move.l	(dl_Root,a1),a2
	moveq	#DLT_VOLUME,d1

	move.l	(ExecBase00,pc),a6
	call	Forbid

	move.l	(rn_Info,a2),a0
	add.l	a0,a0
	add.l	a0,a0
	move.l	(di_DevInfo,a0),d0
.nextdev	beq.b	.devs_scanned
	lsl.l	#2,d0
	move.l	d0,a0
	cmp.l	(dl_Type,a0),d1		(d1=DLT_VOLUME)
	bne.b	.gnd
	cmp.l	#ID_UNIX_DISK,(dl_DiskType,a0)
	seq	UNIXID
	beq.b	.devs_scanned
.gnd	move.l	(a0),d0			dl_Next
	bra.b	.nextdev

.devs_scanned	call	Permit

	move.l	#$202<<16+80,d0		Try to find 'A2620 68020 Accelerator / RAM Board'
	bsr	FindConfigDev
	sne	A2500ID
	bne.b	.is2500
	move.l	#$202<<16+81,d0		Try to find 'A2630 68030 Accelerator / RAM Board'
	bsr	FindConfigDev
	sne	A2500ID
.is2500

	move.l	#$202<<16+84,d0		Try to find 'CBM A4091 SCSI/SCSI-II HD Controller'
	bsr	FindConfigDev
	sne	A4091ID

	move.l	#$2140<<16!$FFFF,d0	Try to find any 'Phase 5 Digital Products'
	bsr	FindConfigDev
	sne	Phase5ID



	bsr	GetPowerUP
	DBG	'gpup'

	bsr	GetUAE
	DBG	'guae'

	bsr	GetClock
	move.l	d0,HWClockID
	DBG	'gclk'

	movem.l	(sp)+,d0-d7/a0-a6
	rts

.findnametest	call	Disable
	call	FindName
	call	Enable
	tst.l	d0
	rts

.CardName	dc.b	'card.resource',0
.CDTVDevName	dc.b	'cdtv.device',0
.A690IDName	dc.b	'A690ID',0
.ATIDEName	dc.b	'AT-IDE',0
.NonvolName	dc.b	'nonvolatile.library',0
	CNOP	0,4


;  IN: -
; OUT: d0=zero if no clock, nonzero if clock found
GetClock	movem.l	d1-a6,-(sp)
	moveq	#0,d7
	move.l	(ExecBase00,pc),a6
	call	Forbid
	lea	(.battclockres,pc),a1
	call	OpenResource
	tst.l	d0
	beq.b	.nores
	move.l	d0,a6
	jsr	(-12,a6)
	move.l	(ExecBase00,pc),a6
	tst.l	d0
	beq.b	.exit
	bra.b	.found

.nores	lea	$DC0001,a0
	moveq	#0,d2
	moveq	#0,d1
.loop	moveq	#15,d2
	and.b	(a0),d2
	cmp.b	#9,d2
	beq.b	.loop
	addq.b	#1,d2
	bsr.b	.wait
	moveq	#$F,d1
	and.b	(a0),d1
	sub.b	d2,d1
	beq.b	.found
	cmp.b	#1,d1
	bne.b	.exit
.found	moveq	#1,d7
.exit	call	Permit
	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts

.wait	bsr.b	.wait2
	move.l	d0,d1
.wloop	bsr.b	.wait2
	sub.l	d1,d0
	cmp.l	#60,d0
	bne.b	.wloop
	rts
.wait2	moveq	#0,d0
	move.b	$BFEA01,d0
	lsl.w	#8,d0
	move.b	$BFE901,d0
	lsl.l	#8,d0
	move.b	$BFE801,d0
	rts

.battclockres	dc.b	'battclock.resource',0
	CNOP	0,2


GetProcInfo	movem.l	d0-a6,-(sp)
	lea	(sNullStr,pc),a2
	tst.b	_AttnFlags+1
	bpl.b	.no060

	lea	(.getpcr,pc),a5
	call	Supervisor
	lsr.w	#8,d0
	swap	d0			d0.l=rev<<16!id
	move.l	d0,-(sp)

	lea	(sProcInfo060Fmt,pc),a0
	move.l	sp,a1
	lea	sPI060Buffer,a2
	bsr	Sprintf
	move.l	(sp)+,d0

	cmp.w	#%0000010000110000,d0	fix CPUID according to CPU internal info
	bne.b	.not68060

	move.l	#MC68060,CPUID

.not68060	cmp.w	#%0000010000110001,d0
	bne.b	.not68xx060

	move.l	#MC68EC060,CPUID	no FPU, no MMU -> EC060

	tst.l	_MMUID
	beq.b	.nommu
	move.l	#MC68LC060,CPUID	no FPU, MMU -> LC060
.nommu
.not68xx060

.no060	move.l	a2,procinfo_ptr
	movem.l	(sp)+,d0-a6
	rts

.getpcr	or.w	#$700,sr
	dc.w	$4E7A,$0808	movec	pcr,d0
	nop
	rte



GetCPU	jsr	GetAddressBits
	move.l	d0,AddrBits

	DBG	'gabi'

	move.w	_AttnFlags,d0
	bsr	GetMinCPUnum
	move.l	d0,d7

	cmp.b	#MIN020,d7
	bne.b	.not_020
	cmp.w	#32,AddrBits+2
	bne.b	.is_EC020
	st	_EC
	addq.l	#MC68020-MC68EC020,d7
.is_EC020	bra.b	.proc_ok
.not_020
	cmp.b	#MIN030,d7
	bne.b	.not_030
	tst.l	_MMUID
	beq.b	.is_EC030
	addq.l	#MC68030-MC68EC030,d7
.is_EC030	bra.b	.proc_ok
.not_030
	cmp.b	#MIN040,d7
	beq.b	.test_040
	cmp.b	#MIN060,d7
	bne.b	.not_040

.test_040	btst	#AFB_FPU40,_AttnFlags+1
	bne.b	.is_full
	tst.l	_MMUID
	beq.b	.proc_ok
	addq.l	#1,d7
	bra.b	.proc_ok
.is_full	addq.l	#2,d7
;;	bra.b	.proc_ok
.not_040
.proc_ok
	move.l	d7,CPUID

	IFGT	0
	move.l	(4).w,a6
	move.w	_AttnFlags,d0
	btst	#AFB_68030,d0		If 68000, 68010 or 68020 use old one.
	beq.b	.getmhz_old
	cmp.w	#37,(LIB_VERSION,a6)	If V37+ and 68030+ use new one.
	blo.b	.getmhz_old
	bsr	GetMHz
	bra.b	.getmhz_new
	ENDC

.getmhz_old	bsr	GetMHz_old
.getmhz_new	move.l	d0,_100kHz


	lea	(s68000,pc),a0
	moveq	#7,d1
	move.l	CPUCompareTime,d0
	divu.w	#180356/4,d0		68000 @ 7 MHz
	addq.w	#4/2,d0			Add 0.5 for correct rounding!
	lsr.w	#2,d0			/4
	cmp.w	#16,d0
	bls.b	.cmpbaseok

	lea	(s68030,pc),a0
	moveq	#25,d1
	move.l	CPUCompareTime,d0
	divu.w	#1442744/32,d0		68030 @ 25 MHz
	add.w	#32/2,d0		Add 0.5 for correct rounding!
	lsr.w	#5,d0			/32

.cmpbaseok	move.w	d0,Multiplier
	move.l	a0,CmpCPU_ptr
	move.w	d1,CmpCPUMHz

	rts


;  IN: D0.w=attnflags
; OUT: D0.l=procnum
GetMinCPUnum	move.l	d1,-(sp)
	move.l	d0,d1
	moveq	#0,d0
	btst	#AFB_68010,d1
	beq.b	.exit
	moveq	#MC68010,d0
	btst	#AFB_68020,d1
	beq.b	.exit
	moveq	#MIN020,d0
	btst	#AFB_68030,d1
	beq.b	.exit
	moveq	#MIN030,d0
	btst	#AFB_68040,d1
	beq.b	.exit
	moveq	#MIN040,d0
	tst.b	d1			Test #AFB_68060
	bpl.b	.exit
	moveq	#MIN060,d0

.exit	move.l	(sp)+,d1
	rts


	; New MHz calculator

	IFND	_LVOSubTime
_LVOSubTime	EQU	-$30
	ENDC

; OUT: D0=100kHz
GetMHz	movem.l	d1-d7/a0-a6,-(sp)
	moveq	#0,d7	
	move.l	(4).w,a6

	lea	(.utilname,pc),a1
	moveq	#37,d0
	call	OpenLibrary
	move.l	d0,_gcUtilBase
	beq.b	.noutil

	lea	(DeviceList,a6),a0
	lea	(.timername,pc),a1
	call	Forbid
	call	FindName
	call	Permit
	move.l	d0,_gcTimerBase
	beq.b	.notimer

	move.w	_AttnFlags,d0
	bsr	.get
	move.l	d0,d7

.notimer	move.l	_gcUtilBase,a1
	move.l	(4).w,a6
	call	CloseLibrary

.noutil	move.l	d7,d0
	movem.l	(sp)+,d1-d7/a0-a6
	rts

.gfxname	dc.b	'graphics.library',0
.utilname	dc.b	'utility.library',0
.timername	dc.b	'timer.device',0
	CNOP	0,2


;  IN: D0.w=attnflags
; OUT: D0=100kHz<<16+procnum
.get	movem.l	d1-d3/d6-d7,-(sp)
	move.l	d0,d6
	moveq	#0,d7

	bsr	.DoTimer
	move.l	d0,WAIndex
	tst.l	d0
	beq	.gcerror
	tst.l	_gcETicker
	beq	.gcerror
	move.l	CPUID,d1
	add.l	d1,d1
	add.l	d1,d1
	move.l	.gcSpeedTable(pc,d1.l),d2

	move.l	_gcUtilBase,a6
	move.l	#100,d1
	call	UMult32
	move.l	_gcETicker,d1
	call	UDivMod32
	move.l	d0,d1
	beq	.gcerror
	move.l	d2,d0
	call	UDivMod32

	move.l	d0,d7
.gcerror
	move.l	d7,d0
	movem.l	(sp)+,d1-d3/d6-d7
	rts

.gcSpeedTable
	dc.l	($1016BF*100/70938)*5000+5000	000  7.09379 MHz
	dc.l	($1016BF*100/70938)*5000+5000	010  7.09379 MHz
	dc.l	($ADDBB*100/70938)*4000+4000	020 14.18758 MHz
	dc.l	($ADDBB*100/70938)*4000+4000
	dc.l	($ADDBB*100/70938)*4000+4000	030 40.00000 MHz
	dc.l	($ADDBB*100/70938)*4000+4000
	dc.l	($341BF*100/70938)*4000+4000	040 40.00000 MHz
	dc.l	($341BF*100/70938)*4000+4000
	dc.l	($341BF*100/70938)*4000+4000
	dc.l	($116BF*100/70938)*5000+5000	060 50.00000 MHz
	dc.l	($116BF*100/70938)*5000+5000
	dc.l	($116BF*100/70938)*5000+5000


;  IN: d6.w=attnflags
; OUT: D0.l=compare time
.DoTimer	movem.l	d1-d7/a0-a6,-(sp)
	move.l	(4).w,a6

	move.l	_ThisTask,a1
	moveq	#127,d0
	call	SetTaskPri
	move.l	d0,-(sp)

	cmp.w	#4,BandWidth
	beq.b	.is_aga4x
	move.l	_GfxBase,a6
	move.l	(gb_ActiView,a6),-(sp)	save view
	sub.l	a1,a1
	call	LoadView
	call	WaitTOF
	call	WaitTOF
.is_aga4x
	move.l	_GfxBase,a6
	call	WaitBlit		Wait possible blit to finish.

	bsr	.timing2
	move.l	d0,d7

	cmp.w	#4,BandWidth		Restore view, if needed
	beq.b	.is_aga4x2
	move.l	_GfxBase,a6
	move.l	(sp)+,a1
	call	LoadView
	call	WaitTOF
	call	WaitTOF
.is_aga4x2
	move.l	(4).w,a6
	move.l	_ThisTask,a1
	move.l	(sp)+,d0
	call	SetTaskPri

	move.l	d7,d0
	movem.l	(sp)+,d1-d7/a0-a6
	rts


;  IN: d6.w=attnflags
.timing2	move.l	(4).w,a6
	moveq	#MEMF_CHIP,d1			chipmem for 000 and 010
	btst	#AFB_68020,d6
	beq.b	.tgoalloc
	move.l	#MEMF_ANY!MEMF_PUBLIC,d1	any mem for 020
	btst	#AFB_68030,d6
	beq.b	.tgoalloc
	move.l	#MEMF_FAST!MEMF_PUBLIC,d1	fastmem for 030, 040 and 060
.tgoalloc
	move.l	#CODE020SIZE,d0
	call	AllocVec
	tst.l	d0
	beq	.nomem
	move.l	d0,a5
	lea	(.code020,pc),a0
	move.l	a5,a1
	move.l	#CODE020SIZE,d0
	call	CopyMemQuick

	call	Forbid

	move.l	#CACRF_EnableI,d0	Disable all but inst cache for test
	move.l	#~CACRF_WriteAllocate,d1
	call	CacheControl
	move.l	d0,-(sp)		Save prev cache state

	bsr	turnon060caches

	jsr	(a5)

	bsr	restore060caches

	move.l	(4).w,a6		Restore cache state
	move.l	(sp)+,d0
	move.l	#~CACRF_WriteAllocate,d1
	call	CacheControl

	call	Permit

	move.l	a5,a1
	call	FreeVec

	move.l	_gcTimerBase,a6
	move.l	a3,a0
	move.l	a2,a1
	call	SubTime
	move.l	(EV_LO,a3),d0
	rts

.nomem	moveq	#0,d0
	rts

	CNOP	0,8
.code020	tst.l	NoHW			** NO PC REL!
	bne.b	.skiphw1
	lea	$DFF000,a4
	move.w	(intenar,a4),d0
	move.w	#$7FFF,(intena,a4)
	swap	d0
	move.w	(dmaconr,a4),d0
	move.w	#$000F,(dmacon,a4)	Disable audio
	move.w	#$C008,(intena,a4)	Enable INT2 & CIAA int
	or.l	#$80008000,d0
	move.l	d0,-(sp)
.skiphw1
	move.l	_gcTimerBase,a6		** NO PC REL!
	lea	_gcStartE,a2		** NO PC REL!
	lea	_gcEndE,a3		** NO PC REL!
	move.l	#5000000,d4

	move.l	a2,a0
	call	ReadEClock
	bra.b	.loop020
	CNOP	0,8
.loop020	subq.l	#1,d4
	bne.b	.loop020

	move.l	a3,a0
	call	ReadEClock
	add.w	#50,d0
	divu.w	#100,d0
	and.l	#$0FFFF,d0
	move.l	d0,_gcETicker		** NO PC REL!

	tst.l	NoHW			** NO PC REL!
	bne.b	.skiphw2
	move.l	(sp)+,d0
	move.w	#$7FFF,(intena,a4)
	move.w	d0,(dmacon,a4)
	swap	d0
	move.w	d0,(intena,a4)
.skiphw2	rts
CODE020SIZE	EQU	(*-.code020+7)&-8



turnon060caches
	tst.b	_AttnFlags+1		Test #AFB_68060
	bpl.b	.exit
	movem.l	d0-d1/a5-a6,-(sp)
	move.l	(4).w,a6
	lea	(.turnon,pc),a5
	call	Supervisor
	movem.l	(sp)+,d0-d1/a5-a6
.exit	rts	

.turnon	or.w	#$700,sr
	dc.w	$4E7A,$0002	movec	cacr,d0
	dc.w	$4E7A,$1808	movec	pcr,d1
	and.l	#$F8E0E000,d0	mask all 060 used bits
	and.l	#$00000083,d1	ditto
	move.l	d0,_gcoldcacr	store old values
	move.l	d1,_gcoldpcr	for restore
	and.l	#~$D8006000,d0	EDC off, NAD off, DPI off, FOC off, NAI off, FIC off
	or.l	#$20808000,d0	enable store buffer, enable instruction cache, enable branch cache
	or.w	#$1,d1		enable superscalar dispatch
_restorego	or.w	#$700,sr
	dc.w	$4E7B,$0002	movec	d0,cacr
	dc.w	$4E7B,$1808	movec	d1,pcr
	dc.w	$F518,$F4F8,$F4D8
	nop
	rte


restore060caches
	tst.b	_AttnFlags+1		Test #AFB_68060
	bpl.b	.exit
	movem.l	d0-d1/a5-a6,-(sp)
	move.l	(4).w,a6
	lea	(_restorego,pc),a5
	move.l	_gcoldcacr,d0
	move.l	_gcoldpcr,d1
	call	Supervisor
	movem.l	(sp)+,d0-d1/a5-a6
.exit	rts	

	CNOP	0,4
_gcUtilBase	dc.l	0
_gcTimerBase	dc.l	0
_gcStartE	dc.l	0,0
_gcEndE	dc.l	0,0
_gcETicker	dc.l	0
_gcoldcacr	dc.l	0
_gcoldpcr	dc.l	0



; OUT: D0.l=100kHz
GetMHz_old	movem.l	d1-d3/d7/a5-a6,-(sp)
	move.l	(4).w,a6
	moveq	#0,d7

	tst.l	DraCoID
	bne	.draco

	lea	(sNoHW,pc),a0
	tst.l	NoHW
	bne	.printerr

	moveq	#MEMF_CHIP,d1			chipmem for 000, 010, 020 and 030
	btst	#AFB_68040,_AttnFlags+1
	beq.b	.tgoalloc
	move.l	#MEMF_FAST!MEMF_PUBLIC,d1	fastmem for 040 and 060
.tgoalloc
	moveq	#CPUTIMER_SIZEOF,d0
	call	AllocMem
	tst.l	d0
	beq	.exit
	move.l	d0,a5
	move.l	d0,a1
	lea	CPU_chiptiming,a0
	moveq	#CPUTIMER_SIZEOF,d0
	call	CopyMem	

	bsr	InitTimer
	lea	(sNotimer,pc),a0
	move.l	d0,TimerBit
	bmi.b	.printerr
	moveq	#1,d1
	lsl.l	d0,d1
	move.l	d1,TimerMask

	DBG	'itim'

	move.l	a5,a0
	bsr	DoTimer
	move.l	d0,CPUCompareTime
	move.l	d0,WAIndex
	move.l	TimerBit,d0
	bsr	RemTimer

	DBG	'dtim'

	move.l	CPUID,d1
	add.l	d1,d1
	move.w	.SpeedCompareTable(pc,d1.l),d2
	move.w	d2,d3
	lsr.w	#1,d3			\
	ext.l	d3			 > add 0.5 for rounding
	add.l	CPUCompareTime,d3	/
	divu.w	d2,d3
	move.w	d3,d7

	move.l	(4).w,a6
	move.l	a5,a1
	moveq	#CPUTIMER_SIZEOF,d0
	call	FreeMem

.exit	move.l	d7,d0
	movem.l	(sp)+,d1-d3/d7/a5-a6
	rts

.draco	move.l	#500,d7			50.0 MHz
	bra.b	.exit

.printerr	pea	(sCPU,pc)
	move.l	a0,-(sp)
	lea	(sMhzxxxErr,pc),a0
	move.l	sp,a1
	bsr	Printf
	addq.l	#8,sp
	bra.b	.exit

.SpeedCompareTable
	dc.w	2542	000  7.09379 MHz  180355.75 !
	dc.w	2542	010  7.09379 MHz  180355.75 !
	dc.w	5771	020 14.18758 MHz  818761.57 !
	dc.w	5771
	dc.w	5771	030 50.00000 MHz 2885487.07 ! 25.00000 MHz 1443364!
	dc.w	5771
	dc.w	15396	040 40.00000 MHz 6158519.00 !
	dc.w	15396
	dc.w	15396
	dc.w	46187	060 50.00000 MHz 23093284.5 !
	dc.w	46187
	dc.w	46187


;  IN: D0.w=attnflags
; OUT: D0.l=FPUID, 0=n/a, 1=68881, 2=68882, 3=68040, 4=68060
GetMinFPUnum	move.l	d1,-(sp)
	move.w	d0,d1
	moveq	#NOMATH,d0
	btst	#AFB_68040,d1
	beq.b	.no_040FPU
	btst	#AFB_FPU40,d1
	beq.b	.exit
	moveq	#MC68040i,d0
	tst.b	d1			Test #AFB_68060
	bpl.b	.exit
	moveq	#MC68060i,d0
	bra.b	.exit

.no_040FPU	moveq	#0,d0
	btst	#AFB_68882,d1
	beq.b	.no882
	moveq	#MC68882,d0
	bra.b	.exit
.no882	btst	#AFB_68881,d1
	beq.b	.no881
	moveq	#MC68881,d0
	;bra.b	.exit
.no881
.exit	move.l	(sp)+,d1
	rts

;  IN: D0.w=attnflags
; OUT: D0.l=100kHz<<16+FPUID, 0=n/a, 1=68881, 2=68882, 3=68040, 4=68060
GetFPU	movem.l	d1-a6,-(sp)
	bsr	GetMinFPUnum
	move.l	d0,d7
	beq.b	.exit

	tst.l	DraCoID
	bne.b	.draco

	lea	(sNoHW,pc),a0
	tst.l	NoHW
	bne.b	.printerr

	bsr	InitTimer
	lea	(sNotimer,pc),a0
	move.l	d0,TimerBit
	bmi.b	.printerr
	moveq	#1,d1
	lsl.l	d0,d1
	move.l	d1,TimerMask

	DBG	'fiti'

	lea	FPU_chiptiming,a0
;;	bsr	DoTimer
	move.l	d0,FPUCompareTime
	move.l	TimerBit,d0
	bsr	RemTimer

	DBG	'fdti'

	; on 881 8 fadd/fsub take 8*51 cycles
	; on 882 8 fadd fsub (8*56)-(8*17) cycles

	move.l	d7,d1
	add.l	d1,d1
	move.w	.SpeedCompareTable-2(pc,d1.l),d2
	;move.w	d2,d3
	;lsr.w	#1,d3			\
	;ext.l	d3			 > add 0.5 for rounding
	;add.l	FPUCompareTime,d3	/
	move.l	FPUCompareTime,d3
	divu.w	d2,d3
	swap	d7
	move.w	d3,d7
	swap	d7

.exit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts

	; Should use CPU MHz as default instead :)
.draco	or.l	#500<<16,d7		50.0 MHz
	bra.b	.exit

.printerr	pea	(sFPU,pc)
	move.l	a0,-(sp)
	lea	(sMhzxxxErr,pc),a0
	move.l	sp,a1
	bsr	Printf
	addq.l	#8,sp
	bra.b	.exit

.SpeedCompareTable
	dc.w	1126680/16/500	881
	dc.w	173203/500	882 50.00000 MHz  112669
	dc.w	225*8		040 40.00000 MHz  
	dc.w	225*16		060 50.00000 MHz  




;  IN: GfxBase in _GfxBase
; OUT: d0=0=OCS, 1=ECS, 2=AGA, 3=CyberGfx, 4=Picasso96, 5=Probench, 6=EGS, 7=Retina,
;         8=Graffiti, 9=TIGA, 10=Altais
;      d1=bandwidth (1, 2 or 4)
GetGfxLibEmul	move.l	d2,-(sp)

	moveq	#0,d0
	move.w	AnimChipID+2,d1
	subq.w	#5,d1
	bmi.b	.oldtestdone
	moveq	#1,d0
;;	subq.w	#8-4,d1
;;	bmi.b	.oldtestdone
.oldtestdone
	moveq	#1,d1
	move.l	_GfxBase,a0
	cmp.w	#37,(LIB_VERSION,a0)
	blo.b	.xit
	move.b	(gb_ChipRevBits0,a0),d2
	move.b	d2,d1
	moveq	#0,d0 			OCS %10001
	and.b	#GFXF_HR_DENISE|GFXF_AA_LISA|GFXF_AA_ALICE,d1 %0xxx0
	beq.b	.done
	moveq	#2,d0  			AGA %11111
	cmp.b	#GFXF_HR_DENISE|GFXF_AA_LISA|GFXF_AA_ALICE,d1
	beq.b	.done
	moveq	#1,d0			ECS %10011
;;	cmp.b	#GFXF_HR_DENISE,d1
;;	beq.b	.done
.done
	moveq	#0,d1
	move.b	(gb_MemType,a0),d1
	and.b	#3,d1
	addq.l	#1,d1
	cmp.b	#3,d1
	bne.b	.xit
	subq.l	#1,d1
.xit
	bsr.b	.getgfxg

	move.l	(sp)+,d2
	tst.l	d0
	rts


; OUT: d0=0=OCS, 1=ECS, 2=AGA, 3=CyberGfx, 4=Picasso96, 5=Probench, 6=EGS, 7=Retina,
;         8=Graffiti, 9=TIGA, 10=Altais

; DosBase in _DosBase, ThisTask in _ThisTask

.getgfxg	tst.b	DraCoID
	beq.b	.not_altais
	moveq	#10,d0
	rts
.not_altais	movem.l	d0-a6,-(sp)
	move.l	(ExecBase00,pc),a6

	lea	(.picassortg,pc),a1
	lea	(LibList,a6),a0
	call	FindName
	tst.l	d0
	beq.b	.notp96
	move.l	_DosBase,a6
	lea	(.pic962,pc),a0
	move.l	a0,d1
	moveq	#ACCESS_READ,d2
	call	Lock
	move.l	d0,d1
	beq.b	.notp96
	call	UnLock

	lea	(.picasso96api,pc),a1
	moveq	#0,d0
	call	OpenLibrary
	tst.l	d0
	beq.b	.notp96
	move.l	d0,a1
	call	CloseLibrary

	moveq	#4,d7
	bra	.exit
.notp96
	lea	(.cybergfx,pc),a1
	lea	(LibList,a6),a0
	call	FindName
;	moveq	#0,d0
;	call	OpenLibrary
	tst.l	d0
	beq.b	.notgg
;	move.l	d0,a1
;	call	CloseLibrary
	move.l	_ThisTask,a3
	lea	(pr_WindowPtr,a3),a3
	move.l	(a3),d3
	moveq	#-1,d0
	move.l	d0,(a3)
	move.l	_DosBase,a6
	lea	(.cybergfx3,pc),a0
	move.l	a0,d1
	moveq	#ACCESS_READ,d2
	call	Lock
	move.l	d0,d1
	bne.b	.isgg
	lea	(.cybergfx2,pc),a0
	move.l	a0,d1
	call	Lock
	move.l	d0,d1
	beq.b	.notgg2
.isgg	call	UnLock
	move.l	d3,(a3)
	moveq	#3,d7
	bra.b	.exit
.notgg2	move.l	d3,(a3)
.notgg
	move.l	(ExecBase00,pc),a6

	lea	(.retina,pc),a1
	lea	(LibList,a6),a0
	call	FindName
	tst.l	d0
	beq.b	.not_retina
	moveq	#7,d7
	move.l	#$4754<<16+6,d0		Try to find Retina Z2
	bsr	FindConfigDev
	bne.b	.exit
	move.l	#$4754<<16+16,d0	Try to find Retina Z3
	bsr	FindConfigDev
	bne.b	.exit
.not_retina
	lea	(.egs,pc),a1
	moveq	#6,d7
	bsr.b	.test
	lea	(.graffiti,pc),a1
	moveq	#8,d7
	bsr.b	.test
	lea	(.tiga,pc),a1
	moveq	#9,d7
	bsr.b	.test
	lea	(.probench,pc),a1
	moveq	#5,d7
	bsr.b	.test

	moveq	#0,d7
.exit	tst.l	d7
	beq.b	.none
	move.l	d7,(sp)
.none	movem.l	(sp)+,d0-a6
	rts

.test
;	moveq	#0,d0
;	call	OpenLibrary
	lea	(LibList,a6),a0
	call	FindName
	tst.l	d0
	beq.b	.texit
;	move.l	d0,a1
;	call	CloseLibrary
	move.l	#.exit,(sp)
.texit	rts

.picassortg	dc.b	'rtg.library',0
.pic962	dc.b	'DEVS:Picasso96Settings',0
.picasso96api	dc.b	'Picasso96API.library',0
.cybergfx	dc.b	'cybergraphics.library',0
.cybergfx2	dc.b	'ENVARC:CyberGraphics',0
.cybergfx3	dc.b	'ENVARC:CyberGraphX',0
.egs	dc.b	'egs.library',0
.retina	dc.b	'retina.library',0
.graffiti	dc.b	'graffiti.library',0
.tiga	dc.b	'gfx.library',0
.probench	dc.b	'hrgblitter.library',0
	CNOP	0,4


; OUT: D0.l=size of virtual memory in KB
GetVirtMem	movem.l	d1/a0-a1/a6,-(sp)
	move.l	(ExecBase00,pc),a6
	lea	(.vmemname,pc),a1
	moveq	#1,d0
	call	OpenLibrary
	tst.l	d0
	beq.b	.novmem
	move.l	d0,a6
	moveq	#1,d0			VMEMF_VIRTUAL
	move.l	#MEMF_TOTAL,d1
	jsr	(-$2A,a6)		VMAvailMem
	move.l	d0,-(sp)
	move.l	a6,a1
	move.l	(ExecBase00,pc),a6
	call	CloseLibrary
	move.l	(sp)+,d0
.novmem	movem.l	(sp)+,d1/a0-a1/a6
	beq.b	.getit
	movem.l	d1-d2,-(sp)
	move.l	d0,d1
	swap	d1
	and.l	#$0FFFF,d1
	divu.w	#1024,d1
	swap	d1
	clr.w	d1
	move.l	d1,d2
	lsl.l	#8,d2
	lsl.l	#2,d2
	sub.l	d2,d0
	divu.w	#1024,d0
	and.l	#$0FFFF,d0
	add.l	d1,d0
	movem.l	(sp)+,d1-d2
	rts

.getit	move.l	#(MEMF_PUBLIC!MEMF_CHIP!MEMF_LOCAL!MEMF_24BITDMA!MEMF_KICK)<<16+(MEMF_ANY),d0
	bra.b	GetMem

.vmemname	dc.b	'vmem.library',0
	CNOP	0,4

; OUT: D0.l=size of fast memory in KB
GetFastMem	move.l	#(MEMF_PUBLIC!MEMF_CHIP!MEMF_FAST)<<16+(MEMF_PUBLIC!MEMF_FAST),d0
	bra.b	GetMem

; OUT: D0.l=size of chip memory in KB
GetChipMem	move.l	#(MEMF_PUBLIC!MEMF_CHIP!MEMF_FAST)<<16+(MEMF_PUBLIC!MEMF_CHIP),d0
;	bra.b	GetMem

;  IN: d0=mask, d1=req
; OUT: D0.l=total size of memory with matching 'req' after masking req with 'mask'
GetMem	movem.l	d1-d3/a0/a6,-(sp)
	move.w	d0,d3
	swap	d0
	move.w	d0,d2
	and.w	d2,d3
	move.l	(ExecBase00,pc),a6
	call	Forbid

	move.l	(MemList,a6),a0
	moveq	#0,d0
.loop	move.l	(a0),d1
	beq.b	.done
	move.w	(MH_ATTRIBUTES,a0),d1
	and.w	d2,d1
	cmp.w	d3,d1
	bne.b	.nomatch
	move.l	(MH_UPPER,a0),d1
	sub.l	(MH_LOWER,a0),d1
	subq.l	#1,d1
	lsr.l	#8,d1
	lsr.l	#6,d1
	addq.l	#1,d1
	lsl.l	#4,d1
	add.l	d1,d0
.nomatch	move.l	(a0),a0
	bra.b	.loop
.done
	call	Permit
	movem.l	(sp)+,d1-d3/a0/a6
	rts


; OUT: D0=version<<16+revision, or null if wblib
GetWBVersion	movem.l	d1-a6,-(sp)
	moveq	#0,d7
	move.l	(ExecBase00,pc),a6
	lea	(.versionname,pc),a1
	moveq	#0,d0
	call	OpenLibrary
	tst.l	d0
	beq.b	.exit
	move.l	d0,a1
	move.l	(LIB_VERSION,a1),d7
	call	CloseLibrary
.exit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts
.versionname	dc.b	'version.library',0
	CNOP	0,4


	STRUCTURE prvSetPatchSemaphore,0
	STRUCT	prvsps_Sem,SS_SIZE
	STRUCT	prvsps_Private,MLH_SIZE
	UWORD	prvsps_Version
	UWORD	prvsps_Revision
	; Don't touch
GetSetPatchVersion
	movem.l	d1-a6,-(sp)
	moveq	#0,d7
	move.l	(ExecBase00,pc),a6
	cmp.w	#36,(LIB_VERSION,a6)
	blo.b	.exit
	lea	(.semaname,pc),a1
	call	Forbid
	call	FindSemaphore
	call	Permit
	tst.l	d0
	beq.b	.exit
	move.l	d0,a0
	move.l	(prvsps_Version,a0),d7
.exit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts
.semaname	dc.b	'« SetPatch »',0
	CNOP	0,4

; OUT: D0=version<<16+revision
;      d1=chksum
GetCRomVer	movem.l	d2-d3/a0-a1/a6,-(sp)
	move.l	(ExecBase00,pc),a6

	move.l	(LIB_IDSTRING,a6),d0
	and.w	#~3,d0
	move.l	d0,a0
	move.l	#$11104EF9,d0
	move.l	#$FFF8FFFF,d1
	moveq	#-1,d3

	move.l	a0,a1
.find	move.l	-(a0),d2
	and.l	d1,d2
	cmp.l	d2,d0
	dbeq	d3,.find
	addq.w	#1,d3
	bne.b	.addrok
	move.l	a1,d0
	clr.w	d0			   Commodore does it this way...
	move.l	d0,a0
.addrok
;;	lea	($1000).w,a1
;;	move.l	(a1),(a1)		<- Fake access (NOT enforcer hit, though)
	move.l	(12,a0),d3

	move.l	#256*1024,d0
	cmp.w	#$1111,(a0)
	beq.b	.rom256k
	add.l	d0,d0
.rom256k	jsr	ROMReSum
	move.l	d0,d1

	move.l	d3,d0
	movem.l	(sp)+,d2-d3/a0-a1/a6
	rts


;  IN: D0.w=attnflags
; OUT: D0=version<<16+revision, zero if no "real" KS rom available
;      d1=chksum, zero if no "real" KS rom available
GetChipRomVer	movem.l	d2-d7/a0-a6,-(sp)
	move.l	(ExecBase00,pc),a6

	jsr	getromver_novmem

	move.l	d6,d1
	move.l	d7,d0
	movem.l	(sp)+,d2-d7/a0-a6
	rts


; OUT: D0=chipid, -1=unknown
GetAnimChip	movem.l	d1-d7/a0-a6,-(sp)
	moveq	#-1,d7
	tst.l	NoHW
	bne.b	.xit

	moveq	#1,d7
	move.w	$DFF004,d0
	and.w	#$7F00,d0
	lsr.w	#8,d0
	bclr	#4,d0
	beq.b	.skip
	moveq	#0,d7
.skip
	cmp.b	#$20,d0
	beq.b	.sa4
	cmp.b	#$21,d0
	beq.b	.sa6
	cmp.b	#$22,d0
	beq.b	.sa8
	cmp.b	#$23,d0
	beq.b	.saA

	tst.b	d0
	bne.b	.unknown
	bsr.b	.subr
	bra.b	.xit

.saA	addq.b	#2,d7
.sa8	addq.b	#2,d7
.sa6	addq.b	#2,d7
.sa4	addq.b	#4,d7

.xit	move.l	d7,d0
	movem.l	(sp)+,d1-d7/a0-a6
	rts

.unknown	moveq	#-1,d7
	bra.b	.xit

.subr	move.l	(ExecBase00,pc),a6	Test for 8361/8367 Agnus:
	call	Disable
	moveq	#32-1,d6		Multicheck: 32 times
	move.l	_GfxBase,a6
	lea	$DFF000,a5		Loads of preloads:
	lea	(bltsize,a5),a4
	lea	(dmaconr,a5),a3
	moveq	#$41,d4			Shortest possible blit
	call	OwnBlitter
	move.w	(a3),d5			Save dmacon
	move.w	#DMAF_BLITHOG,(dmacon,a5) <- No nasty blitter, please!
.blitloop	call	WaitBlit		Do it right, but only here! :-O
	move.w	#$0E00,(bltcon0,a5)	Dummy blit, no dest
	bra.b	.blitcnop
	CNOP	0,4			Align to longword
.blitcnop	move.w	d4,(a4)			/ Fetched in   \
	move.w	(a3),d0			\ one longword /
	btst	#DMAB_BLTDONE,d0	<- _Very_ old agnus
	beq.b	.old_agnus		   get this wrong!!!
	dbf	d6,.blitloop
	addq.b	#2,d7
.old_agnus	or.w	#$8000,d5		Restore dmacon
	move.w	d5,(dmacon,a5)
	call	WaitBlit		Wait blit to finish, if any
	call	DisownBlitter
	move.l	(ExecBase00,pc),a6
	call	Enable
	rts


;  \/  Now this should work with OCS *much* better!?  \/

; OUT: D0=chipid, 0=OCS denise, 1=ECS denise, 2=AGA Lisa, 3=AAA Lisa, 4=Unknown
;      d1.w=revision number, or -1 if OCS
GetGfxChip	movem.l	d2-d3/d7/a0/a5/a6,-(sp)
	moveq	#-1,d1
	moveq	#4,d0
	tst.l	NoHW
	bne.b	.exit
	lea	$DFF000,a5
	move.l	(ExecBase00,pc),a6
	call	Disable
	moveq	#0,d7
	lea	($7C,a5),a0		Preload denise/lisa ID hw addr
	move.w	#$FF,d3			Preload 'and' value

	moveq	#1-1,d0			!! These two just disable the
	bsr	HWWait			!! annoying flick effect...
	move.w	(dmaconr,a5),d1		Save old dmacon
	or.w	#DMAF_SETCLR,d1
	move.w	#$3FF,(dmacon,a5)	Disable all dma
	move.w	(a0),d0			!! OCS denise gives value $FFFF 
					;! when all dma is off (hmm?)
	move.w	d1,(dmacon,a5)		Enable dma again
	not.w	d0			!! Well, my old trusty A500 does!!
	beq.b	.OCS			!! (CAN'T BE SURE ABOUT THIS)

	move.w	(a0),d0		 	Get ID
	and.w	d3,d0
	moveq	#128-1,d2		Check 128 times (try to notice old denise random)
.loop	move.w	(a0),d1			Get ID again
	and.w	d3,d1
	cmp.b	d0,d1			Same value?
	bne.b	.OCS			Not the same value, then OCS Denise
	dbf	d2,.loop
	cmp.b	#$FC,d0
	beq.b	.ECS
	or.b	#%11110000,d0		Mask AGA revision
	cmp.b	#%11111000,d0		Bit 3=AGA
	beq.b	.AGA
	cmp.b	#%11110000,d0		Bit 3=0 => AAA
	beq.b	.AAA
	addq.l	#1,d7			4 is Unknown
.AAA	addq.l	#1,d7			3 is AAA
.AGA	addq.l	#1,d7			2 is AGA
.ECS	addq.l	#1,d7			1 is ECS
.OCS	move.l	d7,d0			0 is OCS

	call	Enable

	tst.b	d0
	beq.b	.skip_OCS
	and.w	#%11110000,d1
	lsr.b	#4,d1
	neg.b	d1
	add.b	#$F,d1

.exit	movem.l	(sp)+,d2-d3/d7/a0/a5/a6
	rts

.skip_OCS	moveq	#-1,d1
	bra.b	.exit


;  IN: A0=FmtString, A1=Array, a2=Buffer
; OUT: Formatted text
Sprintf	movem.l	a0-a3/a6/d0-d1,-(sp)
	move.l	a2,a3
	lea	(.putchar,pc),a2
	move.l	(ExecBase00,pc),a6
	call	RawDoFmt
	movem.l	(sp)+,a0-a3/a6/d0-d1
	rts
.putchar	move.b	d0,(a3)+
	rts


;  IN: A0=FmtString, A1=Array (may be 0)
; OUT: Printed text
Printf	movem.l	a0-a3/a6/d0-d3,-(sp)
	lea	pf_Data,a3
	move.l	a5,(a3)+
	clr.l	(a3)+
	lea	(.newchar,pc),a2
	move.l	(ExecBase00,pc),a6
	call	RawDoFmt
	move.l	a5,a6
	move.l	OutputFH,d1
	move.l	a3,d2
	move.l	(-4,a3),d3
	call	Write
	movem.l	(sp)+,a0-a3/a6/d0-d3
	rts
.newchar	movem.l	d0-d3/a0-a1/a3/a6,-(sp)
	move.l	a3,d2				for Write()
	move.l	-(a3),d1
	move.b	d0,4(a3,d1.l)
	addq.b	#1,d1
	move.l	d1,(a3)
	bne.b	.dont_print
	move.l	-(a3),a6
	move.l	OutputFH,d1
	moveq	#64,d3
	lsl.w	#2,d3
	call	Write
.dont_print	movem.l	(sp)+,d0-d3/a0-a1/a3/a6
	rts


; a0=timer routine (should be in chipmem)
; OUT: D0.l=compare time
DoTimer	movem.l	d1-a6,-(sp)
	move.l	a0,a5
	lea	$DFF000,a4
	move.l	(ExecBase00,pc),a6

	move.l	_ThisTask,a1
	moveq	#127,d0
	call	SetTaskPri
	move.l	d0,-(sp)

	cmp.w	#4,BandWidth
	beq.b	.is_aga4x
	move.l	a6,-(sp)
	move.l	_GfxBase,a6
	move.l	(gb_ActiView,a6),d6	save view
	sub.l	a1,a1
	call	LoadView
	moveq	#3-1,d0
	bsr	HWWait
	move.l	(sp)+,a6
.is_aga4x
	move.l	a6,-(sp)
	move.l	_GfxBase,a6
	call	WaitBlit		Wait possible blit to finish.
	move.l	(sp)+,a6

	jsr	ChipTiming2
	move.l	d0,d7

	cmp.w	#4,BandWidth		Restore view, if needed
	beq.b	.is_aga4x2
	move.l	a6,-(sp)
	move.l	_GfxBase,a6
	move.l	d6,a1
	call	LoadView
	moveq	#3-1,d0
	bsr	HWWait
;;	move.l	(gb_copinit,a6),(cop1lc,a4)	Kick copper into life
	move.l	(sp)+,a6
.is_aga4x2
	move.l	_ThisTask,a1
	move.l	(sp)+,d0
	call	SetTaskPri

	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts



HWWait	movem.l	d0-d2/a0,-(sp)
	tst.l	NoHW
	bne.b	.nohw
	lea	$DFF006,a0
	moveq	#-1,d2
.wait1	move.b	(a0),d1
	cmp.b	d2,d1
	bne.b	.wait1
.wait2	move.b	(a0),d1
	cmp.b	d2,d1
	beq.b	.wait2
	dbf	d0,.wait1
.exit	movem.l	(sp)+,d0-d2/a0
	rts

.nohw	addq.l	#1,d0
	bsr	WaitBlanks		Will break Forbid() or Disable()
	bra.b	.exit


; OUT: d0=iCRBit (now result is LONG negative if failed to get cia)
InitTimer	movem.l	d1/d7/a0-a1/a5-a6,-(sp)
	move.l	(ExecBase00,pc),a6
	moveq	#-1,d7			for .noresource
	lea	(_CiabName,pc),a1
	call	OpenResource
	move.l	d0,CiabResource
	beq.b	.noresource
	move.l	d0,a5

	moveq	#IS_SIZE,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1	No virtmem please!
	call	AllocMem
	move.l	d0,_CiaInterrupt
	beq.b	.nomem

	move.l	d0,a1
	addq.l	#LN_TYPE,a1
	move.w	#NT_INTERRUPT<<8+127,(a1)+
	lea	(CiaIntName,pc),a0
	move.l	a0,(a1)+
	lea	CiaIntData,a0
	move.l	a0,(a1)+
	lea	CiaIntCode,a0
	move.l	a0,(a1)+

	moveq	#1,d7
.allocloop	move.l	d7,d0
 	move.l	_CiaInterrupt,a1
	exg	a5,a6
	call	AddICRVector
	exg	a5,a6
	tst.l	d0
	beq.b	.ciaok
	dbf	d7,.allocloop
.ciaok
	tst.w	d7
	bpl.b	.gottimer
	move.l	_CiaInterrupt,a1
	clr.l	_CiaInterrupt
	moveq	#IS_SIZE,d0
	call	FreeMem
.gottimer
.nomem
.noresource	move.w	d7,d0
	ext.l	d0
	movem.l	(sp)+,d1/d7/a0-a1/a5-a6
	rts

;  IN: d0=iCRBit
RemTimer	movem.l	d0-d1/a0-a1/a6,-(sp)
	tst.l	d0
	bmi.b	.exit
	move.l	CiabResource,d1
	beq.b	.xit
	move.l	d1,a6
	move.l	_CiaInterrupt,a1
	call	RemICRVector
	move.l	(ExecBase00,pc),a6
	move.l	_CiaInterrupt,a1
	clr.l	_CiaInterrupt
	moveq	#IS_SIZE,d0
	call	FreeMem	
.exit	clr.l	CiabResource
.xit	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

EvaluateFormulas
;	move.l	#MC68060,CPUID		debug
;	clr.l	CardSlotID
;	st	A4000ID

	movem.l	d1-d7/a0-a6,-(sp)
	move.l	sp,EvalSpSave
	moveq.l	#0,d6			param array
	lea	(Formulas,pc),a1
.get_next	move.l	(a1)+,a0
;	beq.b	_eval_error		<- n_e_v_e_r happens!!
;	move.l	d0,a0
	move.l	a1,-(sp)
	bsr.b	_EvaluateFormula
	move.l	(sp)+,a1
	tst.l	d0
	beq.b	.get_next
	move.l	(a0),d0
	cmp.l	#32,d0
	bhs.b	_eval_exit
	bset	d0,d6
	bra.b	.get_next
_eval_exit
_eval_error
;;	move.l	d6,WAIndex		db
	move.l	EvalSpSave,sp
;	tst.l	d0			disabled - zero not possible!
;	bne.b	.ok
;	lea	(sNullStr,pc),a0
;	move.l	a0,d0
;.ok
	movem.l	(sp)+,d1-d7/a0-a6
	rts
_eval_error2	lea	(sEvalErr,pc),a0
	move.l	a0,d0
	bra.b	_eval_error

; A1=parameter array
_EvaluateFormula2
	move.l	a0,-(sp)
	move.l	a1,a0
	bsr.b	_EvaluateFormula
	move.l	(sp)+,a0
	rts

; A0=parameter array
_EvaluateFormula
	moveq	#0,d0			orig result=0
	moveq	#0,d4			op-mode (AND)
	moveq	#0,d7			skipmode=OFF
.get_next_com	move.l	(a0)+,d1
	lea	(OperatorTable-8,pc),a1
.get_next_op	addq.l	#8,a1
	move.l	(a1)+,d2
	beq.b	_eval_error2
	cmp.l	d1,d2
	bne.b	.get_next_op
	move.l	(4,a1),a2
	movem.l	(a0),d1-d3
	add.l	(a1),a0
	cmpa.w	#0,a2
	beq.b	.evaluated
	tst.b	d7			handle skip-mode
	bne.b	.get_next_com		<< fixed!
	tst.l	(a1)			handle first parameter
	beq.b	.not_addr_arg
	move.l	d1,a1
	cmp.l	#_EvaluateFormula2,a2	special handle for jump command
	beq.b	.not_addr_arg	
	cmpa.w	#32,a1
	bhs.b	.std_addr_arg
	btst	d1,d6			test entry in param array
	sne	d1
	ext.w	d1
	ext.l	d1			d1.l=0/-1
	bra.b	.not_addr_arg
.std_addr_arg	move.l	(a1),d1
.not_addr_arg	moveq	#0,d0
	movem.l	d4-d7/a1-a6,-(sp)
	jsr	(a2)
	movem.l	(sp)+,d4-d7/a1-a6
	tst.l	d0
	beq.b	.d0zero
	moveq	#-1,d0			ensure d0=-1 on true-condition	
.d0zero	cmp.b	d4,d0
	bne.b	.no_cond_satisfied
	moveq	#-1,d7
.no_cond_satisfied
	bra	.get_next_com
.evaluated	rts

_EqualTo0	tst.l	d1
	seq	d0
	rts

_NotEqualTo0	tst.l	d1
	sne	d0
	rts

_Equal	cmp.l	d1,d2
	seq	d0
	rts

_InsideBorders	cmp.l	d2,d1
	blt.b	.no_inside
	cmp.l	d3,d1
	sle	d0
.no_inside	rts

_OutsideBorders	cmp.l	d2,d1
	blt.b	.is_outside
	cmp.l	d3,d1
	sle	d0
.is_outside	not.b	d0
	rts

_NotEqual	cmp.l	d1,d2
	sne	d0
	rts

_SetAndMode	moveq	#0,d4			AND-mode
	moveq	#-1,d0			result
	rts

_SetOrMode	moveq	#-1,d4			OR-mode
	moveq	#0,d0			result
	rts

OperatorTable	dc.l	'&',0,_SetAndMode
	dc.l	'!',0,_SetOrMode
	dc.l	'(',0,_EvaluateFormula
	dc.l	'->',4,_EvaluateFormula2
	dc.l	'=0',4,_EqualTo0
	dc.l	'<>0',4,_NotEqualTo0
	dc.l	'=',8,_Equal
	dc.l	'<>',8,_NotEqual
	dc.l	'<x<',12,_InsideBorders		the edges are included
	dc.l	'out',12,_OutsideBorders	the edges aren't included
	dc.l	')',0,0
	dc.l	'|',0,0
	dc.l	0

_bitn	SET	0
BIT	MACRO
\1	EQU	_bitn
_bitn	SET	_bitn+1
	ENDM

; Define toggle-array bits
	BIT	_ISAGA

Formulas	dc.l	calculateAGA

	dc.l	calculateDraCo
	dc.l	calculateCD32
	dc.l	calculateCDTV
	dc.l	calculateA1400
	dc.l	calculateA1200
;X	dc.l	calculateWalker
	dc.l	calculateA4000T
	dc.l	calculateA4000
	dc.l	calculateA600
	dc.l	calculateA1000
	dc.l	calculateA3000
	dc.l	calculateA30UX
	dc.l	calculateA3000T
	dc.l	calculate2500
	dc.l	calculate500o
	dc.l	calculateA500e
	dc.l	calculateA2000e
	dc.l	calculateA500pe
	dc.l	calculateA2000pe
	dc.l	calculateA500p
	dc.l	calculateA2000p
	dc.l	calculateA500
	dc.l	calculateA2000
	dc.l	calculateAAA

;	dc.l	calculateA1200		debug move! (ought to be before Walker)

	dc.l	calc_default		<- ALWAYS exits
;	dc.l	0			<- Not needed!!

calculateAGA	dc.l	'&','=',GfxChipID,2,'<x<',AnimChipID,8,$B,'|',_ISAGA
calculateDraCo	dc.l	'&','<>0',DraCoID,'|',sDraCo
calculateCD32	dc.l	'&','<>0',C2PID,'<>0',_ISAGA,'<>0',CD32NVRAMID
	dc.l	'<x<',RomVer,40<<16,INFINITE,'<x<',CPUID,MIN020,MAXCPU,'|',sCD32
calculateCDTV	dc.l	'&','<x<',ChipMem,1024,2048,'<>0',CDTVID,'<x<',CPUID,0,MAX040,'|',sCDTV
calculateA1400	dc.l	'&','<x<',CPUID,MIN020,MAX020,'<x<',_100kHz,240,260,'=',ChipMem,2048
	dc.l	'<>0',_ISAGA,'<>0',CardSlotID
	dc.l	'<x<',RomVer,39<<16,INFINITE,'|',sAmiga1400
calculateA1200	dc.l	'&','<>0',_ISAGA,'<>0',CardSlotID,'<x<',CPUID,MIN020,MAXCPU
	dc.l	'<x<',RomVer,30<<16,INFINITE,'<x<',ChipMem,1024,2048,'|',sAmiga1200
;??			     ^^
;XcalculateWalker	dc.l	'&','<>0',_ISAGA,'<x<',RomVer,41<<16,INFINITE,'=0',CardSlotID
;??					      ^^
;X	dc.l	'=',CPUID,MC68EC030,'=',_100kHz,400,'<x<',ChipMem,1024,2048,'|',sWalker
calculateA4000T	dc.l	'&','<>0',_ISAGA,'<x<',RomVer,40<<16,INFINITE,'=0',CardSlotID
;??					      ^^
	dc.l	'<x<',CPUID,MAX040,MAXCPU,'=',ChipMem,2048,'<>0',A4000TID,'|',sAmiga4000T
calculateA4000	dc.l	'&','<>0',_ISAGA,'<x<',RomVer,39<<16,INFINITE,'=0',CardSlotID
	dc.l	'<x<',CPUID,MIN030,MAXCPU,'=',ChipMem,2048,'<>0',A4000ID,'|',sAmiga4000
calculateA600	dc.l	'&','=',GfxChipID,1,'<x<',AnimChipID,6,7
	dc.l	'<x<',RomVer,37<<16+175+1,INFINITE,'<x<',ChipMem,1024,2048
	dc.l	'<>0',CardSlotID,'|',sAmiga600
calculateA1000	dc.l	'&','=',GfxChipID,0,'<x<',AnimChipID,0,1
	dc.l	'<x<',RomVer,30<<16,INFINITE,'<x<',ChipMem,256,512,'|',sAmiga1000
calculateA3000	dc.l	'&','<x<',RomVer,35<<16,INFINITE,'=',GfxChipID,1
	dc.l	'<x<',AnimChipID,4,7,'<x<',ChipMem,1024,2048
	dc.l	'<x<',CPUID,MIN030,MAXCPU,'<>0',A3000ID,'|',sAmiga3000
calculateA30UX	dc.l	'&','<>0',UNIXID,'<x<',RomVer,35<<16,INFINITE,'=',GfxChipID,1
	dc.l	'<x<',AnimChipID,4,7,'<x<',ChipMem,1024,2048
	dc.l	'<x<',CPUID,MIN030,MAXCPU,'<>0',A3000ID,'|',sAmiga3000UX
calculateA3000T	dc.l	'&','<x<',RomVer,35<<16,INFINITE,'=',GfxChipID,1
	dc.l	'<x<',AnimChipID,4,7,'<x<',ChipMem,1024,2048
	dc.l	'<x<',CPUID,MIN030,MAXCPU,'<>0',A4000ID,'|',sAmiga3000T
calculate2500	dc.l	'&','<>0',A2500ID,'<x<',RomVer,33<<16,INFINITE,'=',GfxChipID,0
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,512,1024,'<x<',CPUID,MIN020,MAX030
	dc.l	'<x<',_100kHz,240,260,'|',sAmiga2500
calculate500o	dc.l	'&','<x<',RomVer,33<<16,INFINITE,'=',GfxChipID,0
	dc.l	'<x<',AnimChipID,2,3,'=',ChipMem,512,'|',sAmiga500old

calculateA500e	dc.l	'&','<>0',A500EID,'<x<',RomVer,33<<16,INFINITE,'=',GfxChipID,0
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,512,2048,'<x<',CPUID,0,MAX040
	dc.l	'|',sAmiga500e
calculateA2000e	dc.l	'&','<>0',A2000EID,'<x<',RomVer,33<<16,INFINITE,'=',GfxChipID,0
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,512,1024,'<x<',CPUID,0,MAXCPU
	dc.l	'|',sAmiga2000e
calculateA500pe	dc.l	'&','<>0',A500EID,'<x<',RomVer,37<<16,INFINITE,'=',GfxChipID,1
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,1024,2048,'<x<',CPUID,0,MAX040
	dc.l	'|',sAmiga500Pluse
calculateA2000pe
	dc.l	'&','<>0',A2000EID,'<x<',RomVer,37<<16,INFINITE,'=',GfxChipID,1
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,1024,2048,'<x<',CPUID,0,MAXCPU
	dc.l	'|',sAmiga2000Pluse
calculateA500p	dc.l	'&','=0',A500EID,'<x<',RomVer,37<<16,INFINITE,'=',GfxChipID,1
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,1024,2048,'<x<',CPUID,0,MAX040
	dc.l	'|',sAmiga500Plus
calculateA2000p	dc.l	'&','=0',A2000EID,'<x<',RomVer,37<<16,INFINITE,'=',GfxChipID,1
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,1024,2048,'<x<',CPUID,0,MAXCPU
	dc.l	'|',sAmiga2000Plus
calculateA500	dc.l	'&','=0',A500EID,'<x<',RomVer,33<<16,INFINITE,'=',GfxChipID,0
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,512,2048,'<x<',CPUID,0,MAX040
	dc.l	'|',sAmiga500
calculateA2000	dc.l	'&','=0',A2000EID,'<x<',RomVer,33<<16,INFINITE,'=',GfxChipID,0
	dc.l	'<x<',AnimChipID,4,5,'<x<',ChipMem,512,1024,'<x<',CPUID,0,MAXCPU
	dc.l	'|',sAmiga2000

calculateAAA	dc.l	'=',GfxChipID,3,'|',sAmigaAAA
calc_default	dc.l	'<>0',calc_default,'|',sDefault


GfxChipTable
.s	dc.w	sDenise-.s,sECSDenise-.s,sAGALisa-.s,sAAALisa-.s,sUnknown-.s

	dc.w	sUnknown-AnimChipTable
AnimChipTable
.s	dc.w	sA0-.s,sA1-.s,sA2-.s,sA3-.s,sA4-.s,sA5-.s,sA6-.s,sA7-.s
	dc.w	sA8-.s,sA9-.s,sAA-.s,sAB-.s

CPUTable
.s	dc.w	s68000-.s,s68010-.s,s68EC020-.s,s68020-.s,s68EC030-.s
	dc.w	s68030-.s,s68EC040-.s,s68LC040-.s,s68040-.s
	dc.w	s68EC060-.s,s68LC060-.s,s68060-.s
;;	dc.w	sMPC603e-.s,sMPC604-.s,sMPC620-.s

FPUTable
.s	dc.w	sFna-.s,s68881-.s,s68882-.s,s68040f-.s,s68060f-.s

MMUTable
.s	dc.w	s68851-.s,s68030m-.s,s68040m-.s,s68060m-.s

GfxLibEmulTable
.s	dc.w	sOCS-.s,sECS-.s,sAGA-.s,sCyberGfxg-.s,sPicasso96g-.s,sProBenchg-.s
	dc.w	sEGSg-.s,sRetinag-.s,sGraffitig-.s,sTIGAg-.s,sAltaisg-.s

PowerPCTable
.s	dc.w	sPPCxx-.s,sPPCxx-.s,sPPCxx-.s
	dc.w	sPPC603-.s,sPPC604-.s,sPPC602-.s,sPPC603e-.s,sPPC603p-.s
	dc.w	sPPCxx-.s
	dc.w	sPPC604e-.s

PowerPCPLLTable
.s	dc.w	pllxx-.s,pllxx-.s,pllxx-.s
	dc.w	pll603-.s,pll604-.s,pll602-.s,pll603e-.s,pll603p-.s
	dc.w	pllxx-.s
	dc.w	pll604e-.s

pllxx
pll603
pll604
pll602
pll603e
pll603p
pll604e
	dc.w	10	; 0000
	dc.w	10	; 0001
	dc.w	70	; 0010
	dc.w	10	; 0011 PLL bypass
	dc.w	20	; 0100
	dc.w	65	; 0101
	dc.w	25	; 0110
	dc.w	45	; 0111
	dc.w	30	; 1000
	dc.w	55	; 1001
	dc.w	40	; 1010
	dc.w	50	; 1011
	dc.w	15	; 1100
	dc.w	60	; 1101
	dc.w	35	; 1110
	dc.w	10	; 1111


DosName	dc.b	'dos.library',0
ExpName	dc.b	'expansion.library',0
_GfxName	dc.b	'graphics.library',0
_CiabName	dc.b	'ciab.resource',0
CiaIntName	dc.b	'WhichAmiga CIA interrupt',0
TimerDevName	dc.b	'timer.device',0
ConsoleName	dc.b	'CON:10/10/620/246/ WhichAmiga  Copyright © 1995-1999 PitPlane Productions',0
NewConsoleName	dc.b	'CON:10/10/620/246/WhichAmiga  Copyright © 1995-1999 PitPlane Productions/CLOSE/AUTO/WAIT',0
PressReturn	dc.b	10,$9B,'0 pPress <RETURN> to close window.',$9B,'30;40m',0
sNoHW	dc.b	'No Amiga custom hardware available',0
sNotimer	dc.b	'Severe trouble! No free CIA timer available',10
sMhzxxxErr	dc.b	'%s!',10
	dc.b	'Unable to calculate %s clock frequency.',10,0
sCPU	dc.b	'CPU',0
sFPU	dc.b	'FPU',0
CursorOn	dc.b	$9B,' p',0

	dc.b	'$VER:'
sStart	dc.b	'WhichAmiga 1.3.3 (2.5.99)',10
	dc.b	$9B,'0 p'
	dc.b	'Written by Harry "Piru" Sintonen. Copyright © 1995-1999 PitPlane Productions.',10,10
	dc.b	'Evaluating system...',10,0

;;sRaport	dc.b	'Central Processing Unit: %s %d.%d MHz  (%dx %s %dMHz WAIndex: %ld)',10
sRaport	dc.b	'Central Processing Unit: %s %d.%d MHz%s',10
	dc.b	'%s'
	dc.b	'    Floating Point Unit: %s',10
	dc.b	' Memory Management Unit: %s %s',10
	dc.b	'   Custom graphics chip: %s%s',10
	dc.b	'  Custom animation chip: %s',10
	dc.b	'   Other custom chip(s): %s',10
	dc.b	'        Graphics system: %s%s',10
	dc.b	'%s%s'
	dc.b	'%s'
	dc.b	'%s%s'
	dc.b	'         Hardware Clock: %s',10
	dc.b	' Max. Chipmem available: %ld K',10
	dc.b	' Max. Fastmem available: %ld K',10
	dc.b	'%s'
	dc.b	'       ROM chip version: %d.%d (Kickstart %s)',10
	dc.b	'%s'
	dc.b	'      Workbench version: %d.%d (Workbench %s)',10
	dc.b	'       SetPatch version: %s',10
	dc.b	'%s'
	dc.b	10
	dc.b	' Your computer %s%s.',10
	dc.b	0

sRev	dc.b	' (rev %d)',0
sReKickROM	dc.b	'  ReKicked ROM, version: %d.%d (Kickstart %s)',10,0
sHWC2P	dc.b	'  Chunky-to-planar conv: available',10,0
sGfxBoards	dc.b	'      Graphics board(s): ',0
sSndCards	dc.b	'           Soundcard(s): ',0

;sFPUFmt	dc.b	'%s %d.%d MHz  (%ld)',0
sFPUFmt	dc.b	'%s',0

sVirtMemFmt	dc.b	' Max. Virtmem available: %ld K',10,0

sDBWFmt	dc.b	'  display bandwidth: %dx',0

sPowerUPFmt0	dc.b	'%2ld PowerUP Processor(s):',0
sPowerUPFmt1	dc.b	' PPC %s %ld MHz (rev %d.%d), %ld MHz busclock',0

sProcInfo060Fmt	dc.b	' (rev %d)',0

sSetPatchVerFmt	dc.b	'%d.%d',0

sOCS	dc.b	'Amiga OCS',0
sECS	dc.b	'Amiga ECS',0
sAGA	dc.b	'Amiga AGA',0
sCyberGfxg	dc.b	'CyberGraphX',0
sPicasso96g	dc.b	'Picasso96',0
sProBenchg	dc.b	'ProBench',0
sEGSg	dc.b	'EGS',0
sRetinag	dc.b	'Retina',0
sGraffitig	dc.b	'Graffiti',0
sTIGAg	dc.b	'TIGA',0
sAltaisg	dc.b	'Altais',0

sDenise	dc.b	'OCS Denise 8362',0
sECSDenise	dc.b	'ECS Denise 8373',0
sAGALisa	dc.b	'AGA Lisa 4203',0
sAAALisa	dc.b	'AAA Lisa?',0

sA0	dc.b	'OCS NTSC Agnus 8361',0			10
sA1	dc.b	'OCS PAL Agnus 8367',0			00
sA2	dc.b	'OCS NTSC Fat Agnus 8370',0		10
sA3	dc.b	'OCS PAL Fat Agnus 8371',0		00
sA4	dc.b	'ECS NTSC Fatter Agnus 8372a, 1MB',0	30
sA5	dc.b	'ECS PAL Fatter Agnus 8372a, 1MB',0	20
sA6	dc.b	'ECS NTSC Super Agnus 8372b, 2MB',0	31
sA7	dc.b	'ECS PAL Super Agnus 8372b, 2MB',0	21
sA8	dc.b	'AGA NTSC Alice 8374, thru rev 2',0	32
sA9	dc.b	'AGA PAL Alice 8374, thru rev 2',0	22
sAA	dc.b	'AGA NTSC Alice 8374, rev 3-4',0	33
sAB	dc.b	'AGA PAL Alice 8374, rev 3-4',0		23
sAxx	dc.b	'ECS Super Agnus 8375, 2MB',0		??
sUnknown	dc.b	'Unknown',0

s68000	dc.b	'MC68000',0
s68010	dc.b	'MC68010',0
s68EC020	dc.b	'MC68EC020',0
s68020	dc.b	'MC68020',0
s68EC030	dc.b	'MC68EC030',0
s68030	dc.b	'MC68030',0
s68EC040	dc.b	'MC68EC040',0
s68LC040	dc.b	'MC68LC040',0
s68040	dc.b	'MC68040',0
s68EC060	dc.b	'MC68EC060',0
s68LC060	dc.b	'MC68LC060',0
s68060	dc.b	'MC68060',0
;;sMPC603e	dc.b	'MPC603e',0
;;sMPC604	dc.b	'MPC604',0
;;sMPC620	dc.b	'MPC620',0

s68881	dc.b	'MC68881',0
s68882	dc.b	'MC68882',0
s68040f	dc.b	'68040fpu',0
s68060f	dc.b	'68060fpu',0

s68851	dc.b	'MC68851',0
s68030m	dc.b	'68030mmu',0
s68040m	dc.b	'68040mmu',0
s68060m	dc.b	'68060mmu',0

sPaula	dc.b	'Paula 8364 (rev %d)',0
sRamsey	dc.b	'Ramsey (rev %d)',0
sGary	dc.b	'Gary (rev %d)',0
sGayle	dc.b	'Gayle (rev %d)',0
sAkiko	dc.b	'Akiko C2P',0
sSuperIO	dc.b	'SuperIO (rev %d)',0
sBuster	dc.b	'Buster (rev %d)',0

sRunningStr	dc.b	'running',0
sNotActiveStr	dc.b	'not active',0

sPPC603	dc.b	'603',0
sPPC604	dc.b	'604',0
sPPC602	dc.b	'602',0
sPPC603e	dc.b	'603e',0
sPPC603p	dc.b	'603p',0
sPPC604e	dc.b	'604e',0
sPPCxx	dc.b	'???',0

sFna
sMMUna
sNA
sGfxEmulna	dc.b	'not available',0
sNullStr	EQU	*-1
sClockFound	dc.b	'clock found',0

sEvalErr	dc.b	'ok, but evaluating code didn''t work! ;)',0

sUAE	dc.b	', run by UAE Amiga Emulator',0
sAmiga1000	dc.b	'is an Amiga 1000',0
sAmiga500old	dc.b	'is an old Amiga 500',0
sAmiga500	dc.b	'probably is an Amiga 500',0
sAmiga500e	dc.b	'is an expanded Amiga 500',0
sAmiga500Plus	dc.b	'probably is an Amiga 500+',0
sAmiga500Pluse	dc.b	'is an expanded Amiga 500+',0
sAmiga600	dc.b	'is an Amiga 600',0
sAmiga1200	dc.b	'is an Amiga 1200',0
sAmiga1400	dc.b	'is an Amiga 1400',0
sAmiga2000	dc.b	'probably is an Amiga 2000',0
sAmiga2000e	dc.b	'is an expanded Amiga 2000',0
sAmiga2000Plus	dc.b	'probably is an Amiga 2000+',0
sAmiga2000Pluse	dc.b	'is an expanded Amiga 2000+',0
sAmiga2500	dc.b	'is an Amiga 2500',0
sAmiga3000	dc.b	'is an Amiga 3000',0
sAmiga3000UX	dc.b	'is an Amiga 3000UX',0
sAmiga3000T	dc.b	'is an Amiga 3000 Tower',0
sAmiga4000	dc.b	'is an Amiga 4000',0
sAmiga4000T	dc.b	'probably is an Amiga 4000 Tower',0
sCD32	dc.b	'is an Amiga CD³²',0
sCDTV	dc.b	'is an Amiga CDTV',0
;XsWalker	dc.b	'is Amiga Techologies'' Walker',0
sDraCo	dc.b	'is MacroSystems'' DraCo (Amiga-clone)',0
sAmigaAAA	dc.b	'probably is a new AAA Amiga (portable? PowerAmiga?)',0
sDefault	dc.b	'is some Amiga or compatible',0


GFXBRD	MACRO
	dc.l	(($\1)<<16)!\2,\3
	ENDM

;	$140C	2	'US Interface Ltd. Magic graphics',0
;	$140C	130	'US Interface Ltd. Magic graphics (Prototype)',0

	CNOP	0,4
GfxBoardTable
	GFXBRD	07E1,32,sIV24
	GFXBRD	06E1,32,sIV24
	GFXBRD	0891,2,sEGS
	GFXBRD	0838,0,sIF24		NTSC
	GFXBRD	0838,1,sIF24		PAL
	GFXBRD	0851,1,sResolver
	GFXBRD	0851,2,sVivid24
	GFXBRD	086A,3,sVoyager
	GFXBRD	086A,2,sBlackbox
	GFXBRD	086A,1,sHorizon
	GFXBRD	085E,1,sGDA
	GFXBRD	0406,0,sA2410
	GFXBRD	03EC,245,sA2410kronos
	GFXBRD	0845,2,sVisiona
	GFXBRD	0845,4,sMerlin
	GFXBRD	2140,34,sCyberVision
	GFXBRD	07E1,68,sRembrandt
	GFXBRD	0872,2,sDomino
	GFXBRD	0893,5,sPiccolo		(actually Piccolo Memory)
	GFXBRD	0893,11,sPiccoloSD64
	GFXBRD	0877,12,sPicassoII
	GFXBRD	0877,13,sPicassoII
	GFXBRD	4754,6,sRetinaZ2
	GFXBRD	4754,16,sRetinaZ3
	GFXBRD	0861,33,sRainbowIII
	GFXBRD	0877,24,sPicassoIV
	GFXBRD	2140,50,sCyberVision3D
	GFXBRD	2140,67,sCyberVision3D
	GFXBRD	4754,19,sAltais
	GFXBRD	041D,20,s1600GX

;	GFXBRD	2140,13,sIV24		db
;	GFXBRD	2140,13,sEGS
;	GFXBRD	2140,13,sResolver	Testing 1.2.3...
;	GFXBRD	2140,13,sA2410
	dc.l	0

sA2410	dc.b	'Lowell A2410',0
sA2410kronos	dc.b	'Kronos/C Ltd A2410',0
sIV24	dc.b	'Impact Vision 24',0
sEGS	dc.b	'EGS Spectrum',0
sIF24	dc.b	'FireCracker 24',0
sResolver	dc.b	'Resolver',0
sVivid24	dc.b	'Vivid 24',0
sGDA	dc.b	'GDA-1',0
sHorizon	dc.b	'Horizon',0
sBlackbox	dc.b	'Blackbox',0
sVoyager	dc.b	'Voyager',0
sVisiona	dc.b	'Visiona',0
sMerlin	dc.b	'Merlin',0
sCyberVision	dc.b	'CyberVision 64',0
sRembrandt	dc.b	'Rembrandt',0
sDomino	dc.b	'Domino',0
sPiccolo	dc.b	'Piccolo',0
sPiccoloSD64	dc.b	'PiccoloSD-64',0
sPicassoII	dc.b	'Picasso II',0
sRetinaZ2	dc.b	'Retina Z2',0
sRetinaZ3	dc.b	'Retina Z3',0
sRainbowIII	dc.b	'Rainbow III',0
sAltais	dc.b	'Altais Card',0
s1600GX	dc.b	'1600-GX',0
sCyberVision3D	dc.b	'CyberVision 64/3D',0
sPicassoIV	dc.b	'Picasso IV',0
	CNOP	0,4


SNDCRD	MACRO
	dc.l	(($\1)<<16)!\2,\3
	ENDM

	CNOP	0,4
SndCardTable
	SNDCRD	0840,191,sWavetools
	SNDCRD	38A5,0,sDelfina
	SNDCRD	4231,1,sPrelude
	SNDCRD	4754,3,sMaestro
	SNDCRD	4754,5,sMaestroPro
	SNDCRD	4754,12,sToccata
	SNDCRD	4754,13,sToccataPro
	SNDCRD	38A5,1,sDelfinaLITE

;	SNDCRD	2140,13,sDelfina	db
;	SNDCRD	2140,13,sMaestroPro
	dc.l	0

sWavetools	dc.b	'Wavetools',0
sDelfina	dc.b	'Delfina DSP',0
sPrelude	dc.b	'Prelude',0
sMaestro	dc.b	'Maestro',0
sMaestroPro	dc.b	'MaestroPro',0
sToccata	dc.b	'Toccata',0
sToccataPro	dc.b	'ToccataPro',0
sDelfinaLITE	dc.b	'Delfina LITE',0

	CNOP	0,4
ExecBase00	dc.l	'EXEC'


	CNOP	0,4
;;	SECTION	BSS,BSS

;;ExecBase01	ds.l	1

Params
CPU	ds.l	1
MHz	ds.l	1
procinfo_ptr	ds.l	1
;Multiplier	ds.w	1
;CmpCPU_ptr	ds.l	1
;CmpCPUMHz	ds.w	1
;WAIndex	ds.l	1
PowerUP_ptr	ds.l	1
FPU_ptr	ds.l	1
MMU	ds.l	1
MMUStatus	ds.l	1
GfxChip	ds.l	1
GfxChipRev_ptr	ds.l	1
AnimChip	ds.l	1
CustomChips	ds.l	1
GfxLibEmul_ptr	ds.l	1
BandWidth_ptr	ds.l	1
GfxBoardI	ds.l	1
GfxBoard	ds.l	1
C2P	ds.l	1
SndCardI	ds.l	1
SndCard	ds.l	1
HWClock_ptr	ds.l	1
ChipMemd	ds.l	1
FastMem	ds.l	1
VirtMem_ptr	ds.l	1
RomVer	ds.l	1
RomVerS	ds.l	1
ReKickROM_ptr	ds.l	1
WBVer	ds.l	1
WBVerS	ds.l	1
SetPatchVerPtr	ds.l	1
ExpBoards_ptr	ds.l	1
MachineGuess	ds.l	1
AfterMG_ptr	ds.l	1

CPUCompareTime	ds.l	1
FPUCompareTime	ds.l	1
CPUID	ds.l	1
EC	ds.l	1
_EC	ds.l	1
GfxLibEmul	ds.l	1
CRomVer	ds.l	1			\
CRomVerS	ds.l	1			/
CRomChkSum	ds.l	1
RomChkSum	ds.l	1
;RamseyGaryRev
RamseyRev	ds.w	1
GaryRev	ds.w	1
GfxChipRev	ds.w	1
	ds.w	1
GfxChipID	ds.l	1
AnimChipID	ds.l	1
FPUID	ds.l	1
CardSlotID	ds.l	1
DraCoID	ds.l	1
PowerUPID	ds.l	1
UAEID	ds.l	1
GayleRev	ds.w	1
PaulaRev	ds.w	1
AGAGayleID	ds.l	1
A690ID	ds.l	1
CDTVID	ds.l	1
ATIDEID	ds.l	1
C2PID
AkikoID	ds.l	1
CD32NVRAMID	ds.l	1
UNIXID	ds.l	1
A500EID	ds.l	1
A2000EID	ds.l	1
A3000ID	ds.l	1
A4000ID	ds.l	1
A4091ID	ds.l	1
Phase5ID	ds.l	1
A4000TID	ds.l	1
A2500ID	ds.l	1
_100kHz	ds.l	1
HWClockID	ds.l	1
VirtMem	ds.l	1
AddrBits	ds.l	1
BandWidth	ds.w	1
	ds.w	1	Align

_ThisTask	ds.l	1
_Args	ds.l	1
_DosBase	ds.l	1
_ExpBase	ds.l	1
_wasDSACK	ds.l	1
_CiaInterrupt	ds.l	1
NewKick	ds.l	1
WBMode	ds.l	1
OutputFH	ds.l	1
EvalSpSave	ds.l	1
ChipMem	ds.l	1
; disabled this x thing:
Multiplier	ds.w	1
CmpCPU_ptr	ds.l	1
CmpCPUMHz	ds.w	1
WAIndex	ds.l	1

pf_Data	ds.l	1	dosbase
	ds.l	1	cnt
	ds.b	256	text-buffer

FPUBuffer	ds.b	32
GfxBoardBuffer	ds.b	256
SndCardBuffer	ds.b	256
sVirtMemBuf	ds.b	80
sROMBuf	ds.b	80
ChipsBuffer	ds.b	80+2
GChipRevBuffer	ds.b	20
DBWBuffer	ds.b	32
ExpBoardsBuffer	ds.b	(10+10+6+4+48+48)*20
sPowerUPBuf	ds.b	80*8
sSetPatchBuf	ds.b	16
sPI060Buffer	ds.b	32


	SECTION	CODE_C,CODE_C		Virtmem sensitive parts:

ExecBase02	dc.l	'EXEC'


	include	"utility/utility_lib.i"
	IFND	_LVOReadEClock
_LVOReadEClock	EQU	-$3C
	ENDC
	CNOP	0,4
;  IN: a0=init_routine, a1=time_routine, a2=cleanup_routine
; OUT: d0=microseconds time_routine took to execute, -1 for error
;NOTE: init_time_routine may change cache settings, loadview(0) etc.
;      do NOT change a5!
TimeRoutine
	STRUCTURE mytimerstuff,0
	APTR	mts_execbase
	APTR	mts_timerbase
	APTR	mts_utilitybase
	STRUCT	mts_beg_eclockval,EV_SIZE
	STRUCT	mts_end_eclockval,EV_SIZE
	;
	APTR	mts_init_routine
	APTR	mts_time_routine
	APTR	mts_cleanup_routine
	ULONG	mts_eclockfreq
	;
	APTR	mts_ciabbase
	ULONG	mts_timerbit
	ULONG	mts_timermask
	UWORD	mts_oldAbleICRmask
	UWORD	mts_oldSetICRmask
	APTR	mts_ciabcrx
	APTR	mts_ciabtxlo
	STRUCT	mts_IS,IS_SIZE
	ALIGNLONG
	STRUCT	mts_icode,8
	LABEL	mts_fullrounds
	ULONG	mts_idata
	ULONG	mts_idata_add
	LABEL	mts_SIZEOF


	movem.l	d1-a6,-(sp)
	moveq	#-1,d7
	move.l	(4).w,a6
	cmp.w	#36,(LIB_VERSION,a6)
	shs	d6

	move.l	a0,d2
	move.l	a1,d3
	move.l	a2,d4
	move.l	#mts_SIZEOF,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1	No virtmem please!
	call	AllocMem
	tst.l	d0
	beq	.exit
	move.l	d0,a5
	move.l	a6,(mts_execbase,a5)
	move.l	d2,(mts_init_routine,a5)
	move.l	d3,(mts_time_routine,a5)
	move.l	d4,(mts_cleanup_routine,a5)

	tst.b	d6
	beq.b	.nov36a
	lea	(DeviceList,a6),a0
	lea	(.timername,pc),a1
	call	Forbid
	call	FindName
	call	Permit
	move.l	d0,(mts_timerbase,a5)
	beq	.free
	bra	.got_timerbase
.nov36a
	move.l	#709379,(mts_eclockfreq,a5)
	cmp.b	#50,(PowerSupplyFrequency,a6)
	beq.b	.was_pal
	move.l	#715909,(mts_eclockfreq,a5)
	cmp.b	#60,(PowerSupplyFrequency,a6)
	bne	.free
.was_pal
	lea	(.ciabname,pc),a1
	call	OpenResource
	move.l	d0,(mts_ciabbase,a5)
	beq	.free

	lea	(mts_IS+LN_TYPE,a5),a1
	move.w	#NT_INTERRUPT<<8+127,(a1)+
	lea	(.ciaintname,pc),a0
	move.l	a0,(a1)+
	lea	(mts_idata,a5),a0
	move.l	a0,(a1)+
	lea	(mts_icode,a5),a0
	move.l	a0,(a1)+
	move.l	#$2029<<16!mts_idata_add-mts_idata,(a0)+ ;move.l (mts_idata_add-mts_idata,a1),d0
	move.l	#$D1914E75,(a0)				 ;add.l d0,(a1); rts
	move.l	#$10000,(mts_idata_add,a5)
	bsr	.cacheclear

	call	Disable
	move.l	(mts_ciabbase,a5),a6
	moveq	#1,d2
.allocloop	move.l	d2,d0
 	lea	(mts_IS,a5),a1
	call	AddICRVector
	tst.l	d0
	beq.b	.ciaok
	dbf	d2,.allocloop
	bra.b	.no_timer
.ciaok	move.w	d2,d0
	move.l	d2,(mts_timerbit,a5)
	moveq	#1,d0
	lsl.l	d2,d0
	move.l	d0,(mts_timermask,a5)
	call	SetICR			Clear timer interrupt
	or.w	#$80,d0
	move.w	d0,(mts_oldSetICRmask,a5)
	move.l	(mts_timermask,a5),d0	Disable timer interrupt
	call	AbleICR
	or.w	#$80,d0
	move.w	d0,(mts_oldAbleICRmask,a5)
.no_timer	move.l	(mts_execbase,a5),a6
	call	Enable
	tst.w	d2
	bmi	.free
	move.l	(mts_timerbit,a5),d0
	lsl.l	#8,d0
	lea	CIAB+ciacra,a0
	add.w	d0,a0
	move.l	a0,(mts_ciabcrx,a5)
	add.w	d0,d0
	lea	CIAB+ciatalo,a0
	add.w	d0,a0
	move.l	a0,(mts_ciabtxlo,a5)
	move.l	(mts_ciabcrx,a5),a0	Stop timer, set continuos mode, count 02 pulses
	clr.b	(a0)
	move.l	(mts_ciabtxlo,a5),a0	Set timeout (counter)
	st	(a0)
	st	($100,a0)
	move.l	(mts_ciabbase,a5),a6
	move.l	(mts_timermask,a5),d0
	or.w	#$80,d0			Enable timer interrupt
	call	AbleICR

	move.l	(mts_init_routine,a5),d0
	beq.b	.noinita
	move.l	d0,a0
	jsr	(a0)
.noinita	movem.l	d0-d1/a0-a1,-(sp)

	move.l	(mts_ciabcrx,a5),a0	set OUTMODE(?), RUNODE=cont, LOAD counter, START
	move.b	#%00010101,(a0)

	movem.l	(sp)+,d0-d1/a0-a1
	move.l	(mts_time_routine,a5),a0
	jsr	(a0)

	move.l	(mts_ciabcrx,a5),a0	Stop timer.
	clr.b	(a0)

	move.l	(mts_cleanup_routine,a5),d0
	beq.b	.nocleana
	move.l	d0,a0
	jsr	(a0)
.nocleana
	; stopped
	moveq	#0,d1
	move.l	(mts_ciabtxlo,a5),a0	Get timer counter
	move.l	#$FFFF,d0
	move.b	($100,a0),d1
	lsl.l	#8,d1
	move.b	(a0),d1
	sub.l	d1,d0			d0=count
	add.l	(mts_fullrounds,a5),d0	Add full timer rounds (rounds*$10000)
	move.l	d0,d2

	move.l	(mts_execbase,a5),a6
	call	Disable
	move.l	(mts_ciabbase,a5),a6
	move.l	(mts_timermask,a5),d0	Clear timer interrupt
	call	SetICR
	move.l	(mts_timermask,a5),d0	Disable timer interrupt
	call	AbleICR
	move.w	(mts_oldSetICRmask,a5),d0
	call	SetICR			Set orig timer interrupt
	move.w	(mts_oldAbleICRmask,a5),d0
	call	AbleICR			Enable orig interrupt
	lea	(mts_IS,a5),a1
	call	RemICRVector
	move.l	(mts_execbase,a5),a6
	call	Enable

	;d2=EV_LO

.free	move.l	(mts_execbase,a5),a6
	move.l	a5,a1
	move.l	#mts_SIZEOF,d0
	call	FreeMem

.exit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts


.cacheclear	move.w	(AttnFlags,a6),d0
	btst	#AFB_68020,d0
	beq.b	.cc_nocache
	move.l	a5,a0
	lea	(.cc_cachec,pc),a5
	jmp	(_LVOSupervisor,a6)
.cc_nocache	rts
.cc_cachec	move.l	a0,a5
	btst	#AFB_68040,d0
	bne.b	.cc_040p
	movec	cacr,d0
	or.w	#CACRF_ClearI!CACRF_ClearD,d0
	movec	d0,cacr
	rte
.cc_040p	dc.w	$F478		; CPUSHA BC	flush the data into memory
	nop
	rte


.got_timerbase	lea	(.utilityname,pc),a1
	moveq	#36,d0
	call	OpenLibrary
	move.l	d0,(mts_utilitybase,a5)
	beq	.free

	move.l	(mts_init_routine,a5),d0
	beq.b	.noinitb
	move.l	d0,a0
	jsr	(a0)
.noinitb	movem.l	d0-d1/a0-a1/a6,-(sp)

	move.l	(mts_timerbase,a5),a6
	lea	(mts_beg_eclockval,a5),a0
	call	ReadEClock

	movem.l	(sp)+,d0-d1/a0-a1/a6
	move.l	(mts_time_routine,a5),a0
	jsr	(a0)

	move.l	(mts_timerbase,a5),a6
	lea	(mts_end_eclockval,a5),a0
	call	ReadEClock
	move.l	d0,(mts_eclockfreq,a5)

	move.l	(mts_cleanup_routine,a5),d0
	beq.b	.nocleanb
	move.l	d0,a0
	jsr	(a0)
.nocleanb
	move.l	(mts_end_eclockval+EV_HI,a5),d0
	cmp.l	(mts_beg_eclockval+EV_HI,a5),d0
	bne.b	.closeu

	;efreqmul=2000
	;evalmul=1000000/efreqmul
	;micros=eval*evalmul/efreq*efreqmul

efreqmul	EQU	2000
evalmul	EQU	1000000/efreqmul

	move.l	(mts_utilitybase,a5),a6

	move.l	(mts_eclockfreq,a5),d0
	move.l	#efreqmul,d1
	call	UMult32
	move.l	d0,d2			efreq*efreqmul
	beq.b	.closeu

	move.l	(mts_end_eclockval+EV_LO,a5),d0
	sub.l	(mts_beg_eclockval+EV_LO,a5),d0
	IFGT	0
	move.l	#evalmul,d1
	call	UMult32			eval*evalmul

	move.l	d2,d1
	call	UDivMod32
	;d0=micros=eval*evalmul/efreq*efreqmul
	ENDC
	move.l	d0,d7

.closeu	move.l	(mts_execbase,a5),a6
	move.l	(mts_utilitybase,a5),a1
	call	CloseLibrary
	bra	.free


.timername	dc.b	'timer.device',0
.utilityname	dc.b	'utility.library',0
.ciabname	dc.b	'ciab.resource',0
.ciaintname	dc.b	'TimeRoutine cia-b interrupt',0
	CNOP	0,4


; Test 68030, 68040 and 68882 WITHOUT system (for KS1.x use)
;  IN: d2=attnflags, a6=execbase
; OUT: d0=updated attnflags
Test030_040_882	move.l	a5,-(sp)
	lea	(.sv,pc),a5
	call	Supervisor
	move.l	(sp)+,a5
	rts

.sv	moveq	#0,d0
	btst	#AFB_68020,d2
	beq.b	.not68020
	movec	cacr,d1
	move.l	d1,-(sp)
	or.w	#CACRF_WriteAllocate,d1
	movec	d1,cacr
	movec	cacr,d1
	btst	#CACRB_WriteAllocate,d1
	beq.b	.not68030
	bset	#AFB_68030,d0
.not68030	move.l	(sp)+,d1
	movec	d1,cacr

	movec	cacr,d1
	move.l	d1,-(sp)
	or.w	#CACRF_EnableI!CACRF_ClearI!CACRF_ClearD!CACRF_WriteAllocate,d1
	movec	d1,cacr
	movec	cacr,d1
	btst	#CACRB_EnableI,d1
	bne.b	.not68040
	or.b	#AFF_68040!AFF_68030,d0
.not68040	move.l	(sp)+,d1
	or.w	#CACRF_ClearI!CACRF_ClearD!CACRF_WriteAllocate,d1
	movec	d1,cacr
.not68020
	btst	#AFB_68881,d2
	beq.b	.no882

	moveq	#0,d1
	dc.w	$F201,$9000
	dc.w	$F201,$B000

	dc.w	$F327
	dc.w	$0C2F,$0018,$0001		cmp.b	#$18,(1,sp)
	beq.b	.flushstack
	bset	#AFB_68882,d0
.flushstack	dc.w	$F35F
.no882	nop				sync pipelines
	rte




	IFGT	0

 >> Information taken from '68060 Upgrade Software Guide' <<

2) Inststructions supported by the 68040 but not by the 68060 directly that
   can hurt performance:

 o divx.l (64bit divide)
 o mulx.l (64bit multiply)
 o fdbcc
 o fscc
 o movep
 o There are other instructions that are not supported or have to
   be emulated but these aren't relevant for user applications.
	ENDC

Test060	move.l	a5,-(sp)
	lea	(.test060,pc),a5
	call	Disable			No others playing around, please.
	call	Supervisor		Ramsey revision:
	call	Enable
	move.l	(sp)+,a5
	rts

.test060	movec	vbr,a0			Hijack illegal instr. trap
	move.l	($10,a0),-(sp)
	move.l	($2C,a0),-(sp)
	move.l	a0,-(sp)
	lea	(.illegal,pc),a1
	move.l	a1,($10,a0)
	move.l	a1,($2C,a0)
	bsr	_flush040

	moveq	#0,d0

	dc.w	$4E7A,$0008		movec	BUSCR,d0
	dc.w	$4E7A,$0808		movec	PCR,d0

	nop
	nop
	moveq	#1,d0
.exit_illegal
	move.l	(sp)+,a0		Restore illegal instr. trap
	move.l	(sp)+,($2C,a0)
	move.l	(sp)+,($10,a0)
	move.l	d0,-(sp)
	bsr	_flush040
	move.l	(sp)+,d0
	beq.b	.no060

	or.w	#AFF_68060,d2
.no060	nop
	rte

	CNOP	0,4
.illegal	lea	(.exit_illegal,pc),a0
	move.l	a0,(2,sp)
	nop				sync pipelines
	rte



CacheClearU	moveq	#0,d1
CacheControl	movem.l	d1-d2/a0/a1/a5/a6,-(sp)
	move.l	(4).w,a6		Use (4).w!!!
	or.w	#CACRF_ClearI!CACRF_ClearD!CACRF_WriteAllocate,d0
	or.w	#CACRF_ClearI!CACRF_ClearD!CACRF_WriteAllocate,d1
	cmp.w	#37,(LIB_VERSION,a6)
	blo.b	.oldkick
	call	CacheControl
	bra.b	.xit

.oldkick	btst	#AFB_68020,_AttnFlags+1
	beq.b	.xit
	lea	(.sv,pc),a5
	call	Supervisor
.xit	movem.l	(sp)+,d1-d2/a0/a1/a5/a6
	rts

.sv	movec	cacr,d2
	move.l	d2,-(sp)
	and.l	d1,d0
	not.l	d1
	and.l	d1,d2
	or.l	d2,d0
	movec	d0,cacr
	move.l	(sp)+,d0
	nop				sync pipelines
	rte


;  IN: (extended attnflags field, MMU routines available)
; OUT: d0=24 or 32
GetAddressBits	movem.l	d1-a6,-(sp)
	moveq	#32,d7

	tst.l	DraCoID			DraCo has 32bit 68060!
	bne.b	.xit

	lea	(_getaddrbits,pc),a0
	moveq	#1,d0
	bsr	RunNoMMU
.xit	move.l	d7,d0
	movem.l	(sp)+,d1-a6
	rts

_getvbr	sub.l	a0,a0
	btst	#AFB_68010,_AttnFlags+1
	beq.b	.novbr
	movec	vbr,a0
.novbr	rts

_getaddrbits	bsr.b	_getvbr
	move.l	($08,a0),-(sp)		Save Access Fault vector
	move.l	a0,-(sp)		Save VBR
	lea	(.busfailure,pc),a1	Set new Access Fault vector:
	move.l	a1,($08,a0)

	lea	AddrChipData,a0		16 byte chip buffer
	move.l	#$BADCAFFE,d1
	move.l	#$DEADBABE,d2
	move.l	#'lOVE',d3
	move.l	#'8biT',d4

	move.w	#256-1-1,d5
	movem.l	d1-d4,(a0)
	move.l	a0,a1
.loop	add.l	#$1000000,a1

	moveq	#4-1,d0
	move.l	a0,a2
	move.l	a1,a3
.compare	cmpm.l	(a2)+,(a3)+
	dbne	d0,.compare
	tst.w	d0
	dbpl	d5,.loop

	tst.w	d5
	bpl.b	.exit			Is 32bit

	exg	d1,d4
	exg	d2,d3
	movem.l	d1-d4,(a0)
	movem.l	(a1),d5-d6/a4-a5
	movem.l	d1-d4,(a1)

	moveq	#4-1,d0
	move.l	a0,a2
	move.l	a1,a3
.compare2	cmpm.l	(a2)+,(a3)+
	dbne	d0,.compare2

	movem.l	d5-d6/a4-a5,(a1)

	tst.w	d0
	bmi.b	.exit			Isn't 24bit

	moveq	#24,d7

.exit
.busfproceed	move.l	(sp)+,a0		Restore VBR
	move.l	(sp)+,($08,a0)		Restore Access Fault vector
.xit	move.l	d7,d0
	rts

	CNOP	0,4
.busfailure	bclr	#0,(10,sp)
	beq.b	.bf_exit
	moveq	#32,d7			If CPU can generate bus failure then it's 32bit
	lea	(.busfproceed,pc),a0
	move.l	a0,(2,sp)
.bf_exit	nop				sync pipelines
	rte


	CNOP	0,4
GetVbr	move.l	a5,-(sp)
	sub.l	a0,a0
	btst	#AFB_68010,_AttnFlags+1
	beq.b	.novbr
	lea	(.getvbr,pc),a5
	call	Supervisor
.novbr	move.l	(sp)+,a5
	rts
.getvbr	movec	vbr,a0
	nop				sync pipelines
	rte


	CNOP	0,4
ChipTiming2	bsr	Disable

	IFGT	0
	tst.l	NoHW
	bne.b	.nohw1
	move.w	(dmaconr,a4),d0
	and.w	#$000F,d0		only audio dma please...
	or.w	#$8000,d0		set
	move.w	#$000F,(dmacon,a4)	Disable audio dma
	move.l	d0,-(sp)
.nohw1
	ENDC

	move.l	#CACRF_EnableI,d0	Disable all but inst cache for test
	move.l	#~CACRF_WriteAllocate,d1 WAS: -1
	bsr	CacheControl
	move.l	d0,-(sp)		Save prev cache state

	jsr	turnon060caches

	move.l	TimerBit,d0
	lsl.l	#8,d0
	lea	CIAB+ciacra,a2
	add.w	d0,a2
	add.w	d0,d0
	lea	CIAB+ciatalo,a3
	add.w	d0,a3

	move.l	CiabResource,a6
	move.l	TimerMask,d0		Clear timer interrupts
	call	SetICR
	moveq	#$7F,d0			Disable all timer interrupts
	call	AbleICR
	move.l	d0,-(sp)
	clr.b	(a2)			Stop timer, set continuos mode, count 02 pulses
	st	(a3)			Set timeout
	st	($100,a3)
	move.l	TimerMask,d0
	or.w	#1<<7,d0		Enable timer interrupt
	call	AbleICR

	move.l	(ExecBase02,pc),a6
	bsr	ChipTiming
	move.l	d0,d7

	move.l	CiabResource,a6
	moveq	#$7F,d0			Disable all timer interrupts
	call	AbleICR
	move.l	(sp)+,d0		Restore old timer interrupts
	or.w	#1<<7,d0
	call	AbleICR

	jsr	restore060caches

	move.l	(ExecBase02,pc),a6	Restore cache state
	move.l	(sp)+,d0
	moveq	#-1,d1
	bsr	CacheControl

	IFGT	0
	tst.l	NoHW
	bne.b	.nohw2
	move.l	(sp)+,d0
	move.w	d0,(dmacon,a4)		Enable audio dma
.nohw2
	ENDC

	bsr	Enable
	move.l	d7,d0
	rts

Disable	tst.l	NoHW
	bne.b	.nohw
	jmp	(_LVODisable,a6)
.nohw	jmp	(_LVOForbid,a6)

Enable	tst.l	NoHW
	bne.b	.nohw
	jmp	(_LVOEnable,a6)
.nohw	jmp	(_LVOPermit,a6)


	CNOP	0,4
ChipTiming	tst.l	NoHW
	bne.b	.nohw1

	move.w	(intenar,a4),d7
	move.w	#$7FFF,(intena,a4)	Disable all interrupts
	or.w	#$8000,d7		set
	move.w	#$E000,(intena,a4)	Enable level6 ints

	bsr	GetVbr			Set new level 6 int
	lea	($60+6*4,a0),a0
	move.l	(a0),-(sp)
	move.l	a0,-(sp)		Can be done 'cause we're in a disabled state!!
	lea	(Level6Trap,pc),a1	Otherwise should get vbr again on restore.
	move.l	a1,(a0)
.nohw1

	move.l	a5,a0
	moveq	#0,d0			No disable!
	bsr	RunNoMMU

	tst.l	NoHW
	bne.b	.nohw2

	move.l	(sp)+,a0		Restore old level 6 int
	move.l	(sp)+,(a0)

	move.w	#$7FFF,(intena,a4)	Disable all ints
	move.w	d7,(intena,a4)		Enable interrupts
.nohw2

	lea	CiaIntData,a0
	move.l	(a0),d0
	clr.l	(a0)
	not.l	d0
	rts


	CNOP	0,8
Level6Trap	movem.l	d0-d1/a0-a1,-(sp)
	move.b	CIAB+ciaicr,d0
	move.b	TimerBit+3,d1
	btst	d1,d0
	beq.b	.xit_argh
	lea	CiaIntData,a1
	bsr.b	CiaIntCode
.xit_argh	move.w	#INTF_EXTER,$DFF000+intreq
	movem.l	(sp)+,d0-d1/a0-a1
	nop				sync pipelines
	rte


	CNOP	0,8
CiaIntCode	subq.l	#1,(a1)			more loops to do?
	bne.b	.skip
	move.l	d4,(a1)			store result
	moveq	#1,d4			exit loop
.skip	rts


; Loop to time CPU:

	CNOP	0,8
CPU_chiptiming	addq.l	#5,CiaIntData		Number of loops
	moveq	#-1,d4			Init counter
	move.b	#%00010101,(a2)		Start timer
	bra.b	.loop
	CNOP	0,8
.loop	subq.l	#1,d4			Main timing loop
	bne.b	.loop
	clr.b	(a2)			Stop timer
	rts

CPUTIMER_SIZEOF	EQU	(*-CPU_chiptiming+7)&-8

; Loop to time FPU:

	CNOP	0,8
FPU_chiptiming	addq.l	#3,CiaIntData		Number of loops
	moveq	#-1,d4			Init counter
	fmove.x	#0.000000001,fp0
	fmove.x	fp0,fp1

	move.b	#%00010101,(a2)		Start timer
	bra.b	.loop

	CNOP	0,8
.loop	fadd.x	fp1,fp0			Main timing loop
	fsub.x	fp1,fp0
	subq.l	#1,d4
	bne.b	.loop
	clr.b	(a2)			Stop timer
	rts



	CNOP	0,4
getromver_novmem
	lea	(.novirtmempart,pc),a0
	moveq	#1,d0
	bra	RunNoMMU
;;	bsr	RunNoMMU
;;	rts

.novirtmempart
	lea	$1000000,a0
	tst.l	Phase5ID
	beq.b	.nophaserom
	lea	$0B80000,a1
	moveq	#8,d0
	swap	d0
	cmp.l	(-$14,a1),d0
	bne.b	.nophaserom
	neg.l	d0
	move.l	(a1,d0.l),d0
	and.l	#$FFF8FFFF,d0
	cmp.l	#$11104EF9,d0
	bne.b	.nophaserom
	move.l	a1,a0
.nophaserom
	move.l	(-$14,a0),d0
	move.l	d0,d1
	and.l	#$0003FFFF,d1
	bne.b	.no_rom
	cmp.l	#$00100000,d0
	bhi.b	.no_rom
	sub.l	d0,a0
	move.l	(a0),d1
	and.l	#$FFF8FFFF,d1
	cmp.l	#$11104EF9,d1
	bne.b	.no_rom
	move.l	(12,a0),d7

	bsr.b	ROMReSum
	move.l	d0,d6
.exit	rts
.no_rom	moveq	#0,d7
	moveq	#0,d6
	bra.b	.exit


;  IN: d0=rom size, a0=rom start
; OUT: d0=chksum
ROMReSum	move.l	d0,d1
	lsr.l	#3,d1
	move.l	-$18(a0,d0.l),d0
	not.l	d0
.loop	add.l	(a0)+,d0
	bcc.b	.skip1
	addq.l	#1,d0
.skip1	add.l	(a0)+,d0
	bcc.b	.skip2
	addq.l	#1,d0
.skip2	subq.l	#1,d1
	bne.b	.loop
	not.l	d0
	rts


	CNOP	0,4
; a0=code to run without MMU, d0=disable flag
; Code should be in Chip memory (in case of VMM or similar)
RunNoMMU	movem.l	d0/a5/a6,-(sp)
	move.l	(ExecBase02,pc),a6	Use (4).w??
	lea	(.super,pc),a5
	DBG	'RNM1'
	tst.l	d0
	beq.b	.nodis
	call	Disable
.nodis	tst.l	NoHW
	bne.b	.nohw1
	subq.l	#4,sp
	move.w	$DFF000+dmaconr,(sp)
	move.w	#$000F,$DFF000+dmacon
	or.w	#$8000,(sp)
.nohw1	call	Supervisor
	tst.l	NoHW
	bne.b	.nohw2
	move.w	(sp),$DFF000+dmacon
	addq.l	#4,sp
.nohw2	tst.l	(sp)+
	beq.b	.noen
	call	Enable
.noen	movem.l	(sp)+,a5/a6
	DBG	'RNM2'
	tst.l	d0
	rts

	CNOP	0,4
.super
;;	or.w	#$700,sr
	tst.l	_MMUID
	beq.b	.nommua
	btst	#AFB_68040,_AttnFlags+1
	beq	.is030a
	bsr	_flush040
	move.l	d0,-(sp)
	movec	TC,d0
	move.l	d0,-(sp)
	movec	URP,d0
	move.l	d0,-(sp)
	movec	SRP,d0
	move.l	d0,-(sp)
	movec	DTT1,d0
	move.l	d0,-(sp)
	movec	DTT0,d0
	move.l	d0,-(sp)
	movec	ITT1,d0
	move.l	d0,-(sp)
	movec	ITT0,d0
	move.l	d0,-(sp)
	move.l	#$00FFC000,d0
	movec	d0,ITT0
	movec	d0,ITT1
	movec	d0,DTT1
	move.l	#$0000C040,d0
	movec	d0,DTT0
	move.l	#$00030000,d0
	movec	d0,URP
	movec	d0,SRP
	moveq	#0,d0
	movec	d0,TC
	bsr	_flush040
	move.l	(7*4,sp),d0
.nommua	jsr	(a0)
	tst.l	_MMUID
	beq.b	.nommub
	btst	#AFB_68040,_AttnFlags+1
	beq.b	.is030b
	bsr	_flush040
	move.l	d0,-(sp)
	move.l	(1*4,sp),d0
	movec	d0,ITT0
	move.l	(2*4,sp),d0
	movec	d0,ITT1
	move.l	(3*4,sp),d0
	movec	d0,DTT0
	move.l	(4*4,sp),d0
	movec	d0,DTT1
	move.l	(5*4,sp),d0
	movec	d0,SRP
	move.l	(6*4,sp),d0
	movec	d0,URP
	bsr	_flush040
	move.l	(7*4,sp),d0
	movec	d0,TC
	move.l	(sp)+,d0
	lea	(7*4,sp),sp
.nommub2	addq.l	#4,sp
.nommub	nop				sync pipelines
	rte

.is030a	clr.l	-(sp)
	pmove.l	tc,(sp)
	move.l	(sp),-(sp)
	bclr	#7,(sp)
	pmove.l	(sp),tc
	addq.l	#4,sp
	bra.b	.nommua

.is030b	pmove.l	(sp),tc
	bra.b	.nommub2


_flush040	dc.w	$F518		; PFLUSHA	flush the address translation cache
	dc.w	$F4F8		; CPUSHA BC	flush the caches into memory
	dc.w	$F4D8		; INVA	BC	invalidate the data and inst caches
	rts


	CNOP	0,4
; OUT: d0=0 no mmu, d0=1 68851 mmu, d0=2 68030 MMU, d0=3 68040 MMU, d0=4 68060 MMU
;      d1=mmu activity status, valid if d0>0
GetMMU
; Must be called from user state!!
;  OUT: d0=success if working MMU exists, null otherwise
;       d0=0 for no MMU
;          4 for 68060 or 68LC060 internal MMU
;          3 for 68040 or 68LC040 internal MMU
;          2 for 68030 internal MMU
;          1 for 68020 + 68851 MMU
;       d1=mmu activity status, valid if d0>0
TestForMMU	movem.l	d2-a6,-(sp)
	moveq	#0,d7

	move.l	(ExecBase02,pc),a6
	move.w	_AttnFlags,d0
	btst	#AFB_68020,d0		No MMU below 68020!
	beq.b	.exit
	cmp.w	#37,(LIB_VERSION,a6)
	blo.b	.oldtest
	lea	(.test040plus,pc),a5
	moveq	#MC68060m,d6
	tst.b	d0			Test #AFB_68060
	bmi.b	.test
	subq.l	#1,d6
	btst	#AFB_68040,d0
	bne.b	.test
.otcont	lea	(.test020plus,pc),a5
	subq.l	#1,d6
	btst	#AFB_68030,d0
	bne.b	.test
	subq.l	#1,d6
.test
	DBG	'MMU1'
	jsr	(a5)
	DBG	'MMU2'

.exit	move.l	d7,d0
	beq.b	.fail
	move.l	d6,d0
.fail	movem.l	(sp)+,d2-a6
	rts

.oldtest	moveq	#MC68030m+1,d6
	bra.b	.otcont

.test040plus	lea	(.gogo040,pc),a5
	call	Disable
	call	Supervisor
	jmp	(_LVOEnable,a6)
.gogo040	or.w	#$700,sr		Disable interrupts.
	movec	vbr,a0			Get VBR
	move.l	($10,a0),-(sp)		Save Illegal Instruction vector
	move.l	($2C,a0),-(sp)		Save F-Line Emul vector
	move.l	a0,-(sp)		Save VBR

	lea	(.illegal040,pc),a1
	move.l	a1,($10,a0)
	move.l	a1,($2C,a0)
	bsr	_flush040

	moveq	#0,d0			IMPORTANT!
	moveq	#-1,d7
	movec	tc,d0			$4e7a0003	Test some "common" MMU regs:
	movec	urp,d1			$4e7a1806	Test 040/060 MMU only reg!!
	movec	srp,d1			$4e7a1807
.exit040	nop
	nop
	; d0=mmu TC (or null)

	moveq	#0,d1
	tst.l	d7
	beq.b	.gm4_nommu
	btst	#15,d0			Bit 15: On/Off!!
	beq.b	.gm4_nommu
	moveq	#1,d1
.gm4_nommu
	move.l	(sp)+,a0
	move.l	(sp)+,($2C,a0)		Restore F-Line Emul vector
	move.l	(sp)+,($10,a0)		Restore Illegal Instruction vector
	bsr	_flush040
	nop				sync pipelines
	rte

	CNOP	0,4
.illegal040	moveq	#0,d7
	lea	(.exit040,pc),a0
	move.l	a0,(2,sp)
	bsr	_flush040
	nop				sync pipelines
	rte


.simpletest	call	Disable
	lea	(.gogos020,pc),a5
	call	Supervisor
	jmp	(_LVOEnable,a6)

.gogos020	or.w	#$700,sr		Disable interrupts.

	movec	vbr,a0			Get VBR
	move.l	($10,a0),-(sp)		Save Illegal Instruction vector
	move.l	($2C,a0),-(sp)		Save F-Line Emul vector
	move.l	a0,-(sp)		Save VBR

	lea	(.mmuinstfailures,pc),a1
	move.l	a1,($10,a0)
	move.l	a1,($2C,a0)

	bsr	_flush020

	moveq	#-1,d7
	clr.l	-(sp)
	pmove.l	tc,(sp)
.exitsupers	move.l	(sp)+,d5

	moveq	#0,d1
	tst.l	d7
	beq.b	.gm2_nommus
	tst.l	d5			Bit 31: On/Off!!
	bpl.b	.gm2_nommus
	moveq	#1,d1
.gm2_nommus
	move.l	(sp)+,a0		Restore VBR
	move.l	(sp)+,($2C,a0)		Restore F-Line Emul vector
	move.l	(sp)+,($10,a0)		Restore Illegal Instruction vector
	bsr	_flush020
	rte

.mmuinstfailures
	lea	(.exitsupers,pc),a0	Invalid mmu instruction!
	moveq	#0,d7
	move.l	a0,(2,sp)
	rte



.test020plus
;;GVP's	move.l	#$07E1<<16!$FFFF,d0	Try to find any 'Great Valley Products' board
;;works	jsr	FindConfigDev
;;now??	bne.b	.simpletest		If found test MMU with simple code (following one crashes!)

	lea	$D0000000,a2
	move.w	#$10000000/(512*1024)-1-1,d2
.tloop	move.l	a2,a1
	call	TypeOfMem
	tst.l	d0
	bne	.simpletest
	add.l	#512*1024,a2
	dbf	d2,.tloop

	move.l	#((1<<8)+.TTable1End-.TTable1),d0
	moveq	#MEMF_PUBLIC,d1
	call	AllocMem
	tst.l	d0
	beq	.simpletest
	move.l	d0,a4

	add.l	#(1<<7)-1,d0
	and.w	#-(1<<7),d0
	move.l	d0,a2
	lea	(.TTable1,pc),a0
	move.l	a2,a1
	moveq	#(.TTable1End-.TTable1),d0
	call	CopyMem			Used to use CopyMemQuick... Is it KS1.3+?

	call	Disable
	lea	(.gogo020,pc),a5
	call	Supervisor
	call	Enable

	movem.l	d0-d1,-(sp)
	move.l	#((1<<8)+.TTable1End-.TTable1),d0
	move.l	a4,a1
	call	FreeMem
	movem.l	(sp)+,d0-d1
	rts

.gogo020	or.w	#$700,sr		Disable interrupts.
	moveq	#0,d5			IMPORTANT!

	move.l	#$D0000000,d0		Test for our usage of area $D0000000:
	move.l	#$F0000000,d1
	move.l	sp,d2			SSP uses $D0000000?
	and.l	d1,d2
	cmp.l	d0,d2
	beq	.exitall
	move.l	#.test020plus,d2	PC?
	and.l	d1,d2
	cmp.l	d0,d2
	beq	.exitall

	movec	vbr,a0			Get VBR
	move.l	($08,a0),-(sp)		Save Access Fault vector
	move.l	($10,a0),-(sp)		Save Illegal Instruction vector
	move.l	($2C,a0),-(sp)		Save F-Line Emul vector
	move.l	($E0,a0),-(sp)		Save MMU Config Error vector
	move.l	($E4,a0),-(sp)		Save MMU Illegal Operation Error vector
	move.l	($E8,a0),-(sp)		Save MMU Access Level Violation Error vector
	move.l	a0,-(sp)		Save VBR

	subq.l	#8,sp

	lea	(.mmufailure_es,pc),a1	Set new vectors:
	move.l	a1,($08,a0)
	move.l	a1,($10,a0)
	move.l	a1,($2C,a0)
	move.l	a1,($E0,a0)
	move.l	a1,($E4,a0)
	move.l	a1,($E8,a0)

	bsr	_flush020

	pmove.l	tc,(sp)			Save tc:
	moveq	#-1,d7
	move.l	(sp),d5
	bmi	.exitsuper		MMU in use!
	moveq	#0,d7

	dc.w	$F017,$4E00		pmove.q	crp,(sp)
	move.l	(sp),d3			Save crp:
	move.l	(4,sp),d4

	lea	(.mmufailure,pc),a1
	move.l	a1,($08,a0)
	move.l	a1,($10,a0)
	move.l	a1,($2C,a0)
	move.l	a1,($E0,a0)
	move.l	a1,($E4,a0)
	move.l	a1,($E8,a0)

	bsr	_flush020

	clr.l	(sp)			Clear translation control register
	pmove.l	(sp),tc
	nop

	move.l	#$80000002,(sp)		Set our crp: (was: 202)
	move.l	a2,(4,sp)
	dc.w	$F017,$4C00		pmove.q (sp),crp

	move.l	#$80D04780,(sp)		Enable mmu mapping:
	pmove.l	(sp),tc

	bsr	_flush020

	clr.b	(.TTableD-.TTable1,a2)	Make it map to address 0.
	bsr	_flush020

	lea	(.chipaddr,pc),a3	Test memory mapping a bit... :)
	move.l	a3,d0			(This should _finally_ catch
	or.l	#$D0000000,d0		nonfunctional 030 MMU)
	move.l	d0,a1
	move.l	#'MMUt',d0
	move.l	d0,(a3)
	nop
	cmp.l	(a1),d0
	bne.b	.remove
	not.l	d0			Test write mapping:
	move.l	(a1),-(sp)
	move.l	d0,(a1)
	nop
	move.l	(a3),d1
	move.l	(sp)+,(a1)
	cmp.l	d1,d0
	bne.b	.remove
	clr.l	(a3)
	nop
	tst.l	(a1)
	bne.b	.remove


	;move.l	sp,$200.w		debug

	move.l	#$D0000060,(.TTableD-.TTable1,a2) Make it invalid
	bsr	_flush020
	nop				Sync pipelines
	move.l	a0,a1
	lea	$DFFFFFFC,a0		Test memory (in)validity:
	dc.w	$F010,$9C15		ptestw	#5,(a0),#7
	dc.w	$F017,$6200		pmove.w	mmusr,(sp)
	move.w	(sp),d0
	btst	#10,d0
	beq.b	.remove			Memory isn't invalid!!

	lea	(.busfailure,pc),a2
	move.l	a2,($08,a1)

	bsr	_flush020

	move.l	(a0),d0			Cause bus failure.
.busfproceed
.remove
.restoremmu	clr.l	(sp)			Disable mapping:
	pmove.l	(sp),tc
	nop

	move.l	d3,(sp)			Restore crp:
	move.l	d4,(4,sp)
	dc.w	$F017,$4C00		pmove.q (sp),crp

	move.l	d5,(sp)			Restore tc:
	pmove.l	(sp),tc

	;move.l	#'rest',($200).w	debug
	;move.l	d5,($204).w

.exitsuper	addq.l	#8,sp

	moveq	#0,d1
	tst.l	d7
	beq.b	.gm2_nommu
	tst.l	d5			Bit 31: On/Off!!
	bpl.b	.gm2_nommu
	moveq	#1,d1
.gm2_nommu
	move.l	(sp)+,a0		Restore VBR
	move.l	(sp)+,($E8,a0)		Restore MMU Access Level Violation Error vector
	move.l	(sp)+,($E4,a0)		Restore MMU Illegal Operation vector
	move.l	(sp)+,($E0,a0)		Restore MMU Config Error vector
	move.l	(sp)+,($2C,a0)		Restore F-Line Emul vector
	move.l	(sp)+,($10,a0)		Restore Illegal Instruction vector
	move.l	(sp)+,($08,a0)		Restore Access Fault vector
.exitall	bsr	_flush020
	rte

.mmufailure	lea	(.restoremmu,pc),a0	Invalid mmu table!?
.exitrt	moveq	#0,d7
.exitrt2	move.l	a0,(2,sp)
.be_exitrte	rte

.mmufailure_es	lea	(.exitsuper,pc),a0	Invalid mmu instruction!
	bra.b	.exitrt

.busfailure	bclr	#0,(10,sp)
	beq.b	.be_exitrte
	moveq	#-1,d7
	lea	(.busfproceed,pc),a0
	bra.b	.exitrt2


; Pagesize is 8K (=1<<%1101)
; Initial shift is 0 (%0000)
; TIA is 4 (%0100)  [$10000000<<4=$100000000]
; TIB is 7 (%0111)  [$00200000<<7=$10000000]
; TIC is 8 (%1000)  [$00002000<<8=$00200000]
; TID is 0 (%0000)
;  TC = $80D04780
; CRP = $80000002 TranslationTable

	CNOP	0,4
.TTable1	dc.l	$00000061,$10000061,$20000061,$30000061
	dc.l	$40000061,$50000061,$60000061,$70000061
	dc.l	$80000061,$90000061,$A0000061,$B0000061
	dc.l	$C0000061
.TTableD	dc.l	$D0000061
	dc.l	$E0000061,$F0000061
.TTable1End
.chipaddr	dc.l	0

_flush020	move.l	d0,-(sp)
	movec	cacr,d0
	or.w	#CACRF_ClearI!CACRF_ClearD,d0
	movec	d0,cacr
	move.l	(sp)+,d0
	rts



	CNOP	0,4
;;	SECTION	BSS_C,BSS_C	Our megademo uses great chip-buffers :-)

;;ExecBase03	ds.l	1

NoHW	ds.l	1
_MMUID	ds.l	1
TimerBit	ds.l	1
TimerMask	ds.l	1
CiabResource	ds.l	1
CiaIntData	ds.l	1
_GfxBase	ds.l	1
	ds.l	0	Align
_AttnFlags	ds.w	1

AddrChipData	ds.l	4	16 bytes

	END
