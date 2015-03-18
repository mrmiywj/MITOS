
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 c0 19 10 f0 	movl   $0xf01019c0,(%esp)
f0100055:	e8 6f 09 00 00       	call   f01009c9 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 24 07 00 00       	call   f01007ab <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 19 10 f0 	movl   $0xf01019dc,(%esp)
f0100092:	e8 32 09 00 00       	call   f01009c9 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 52 14 00 00       	call   f0101517 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a0 04 00 00       	call   f010056a <cons_init>

	cprintf("3250 decimal is %o octal!\n", 3250);
f01000ca:	c7 44 24 04 b2 0c 00 	movl   $0xcb2,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 19 10 f0 	movl   $0xf01019f7,(%esp)
f01000d9:	e8 eb 08 00 00       	call   f01009c9 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 5a 07 00 00       	call   f0100850 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 12 1a 10 f0 	movl   $0xf0101a12,(%esp)
f010012c:	e8 98 08 00 00       	call   f01009c9 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 59 08 00 00       	call   f0100996 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100144:	e8 80 08 00 00       	call   f01009c9 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 fb 06 00 00       	call   f0100850 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 2a 1a 10 f0 	movl   $0xf0101a2a,(%esp)
f0100176:	e8 4e 08 00 00       	call   f01009c9 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 0c 08 00 00       	call   f0100996 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100191:	e8 33 08 00 00       	call   f01009c9 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a a0 1a 10 f0 	movzbl -0xfefe560(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 80 1a 10 f0 	mov    -0xfefe580(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 44 1a 10 f0 	movl   $0xf0101a44,(%esp)
f01002e9:	e8 db 06 00 00       	call   f01009c9 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 0c                	jmp    f0100331 <cons_putc+0x28>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	89 ca                	mov    %ecx,%edx
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 ca                	mov    %ecx,%edx
f010032d:	ec                   	in     (%dx),%al
f010032e:	89 ca                	mov    %ecx,%edx
f0100330:	ec                   	in     (%dx),%al
f0100331:	89 f2                	mov    %esi,%edx
f0100333:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100334:	a8 20                	test   $0x20,%al
f0100336:	75 05                	jne    f010033d <cons_putc+0x34>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100338:	83 eb 01             	sub    $0x1,%ebx
f010033b:	75 e8                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010033d:	89 f8                	mov    %edi,%eax
f010033f:	0f b6 c0             	movzbl %al,%eax
f0100342:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100345:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034a:	ee                   	out    %al,(%dx)
f010034b:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100350:	be 79 03 00 00       	mov    $0x379,%esi
f0100355:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035a:	eb 0c                	jmp    f0100368 <cons_putc+0x5f>
f010035c:	89 ca                	mov    %ecx,%edx
f010035e:	ec                   	in     (%dx),%al
f010035f:	89 ca                	mov    %ecx,%edx
f0100361:	ec                   	in     (%dx),%al
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ec                   	in     (%dx),%al
f0100365:	89 ca                	mov    %ecx,%edx
f0100367:	ec                   	in     (%dx),%al
f0100368:	89 f2                	mov    %esi,%edx
f010036a:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010036b:	84 c0                	test   %al,%al
f010036d:	78 05                	js     f0100374 <cons_putc+0x6b>
f010036f:	83 eb 01             	sub    $0x1,%ebx
f0100372:	75 e8                	jne    f010035c <cons_putc+0x53>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100374:	ba 78 03 00 00       	mov    $0x378,%edx
f0100379:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037d:	ee                   	out    %al,(%dx)
f010037e:	b2 7a                	mov    $0x7a,%dl
f0100380:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100385:	ee                   	out    %al,(%dx)
f0100386:	b8 08 00 00 00       	mov    $0x8,%eax
f010038b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038c:	89 fa                	mov    %edi,%edx
f010038e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100394:	89 f8                	mov    %edi,%eax
f0100396:	80 cc 07             	or     $0x7,%ah
f0100399:	85 d2                	test   %edx,%edx
f010039b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039e:	89 f8                	mov    %edi,%eax
f01003a0:	0f b6 c0             	movzbl %al,%eax
f01003a3:	83 f8 09             	cmp    $0x9,%eax
f01003a6:	74 75                	je     f010041d <cons_putc+0x114>
f01003a8:	83 f8 09             	cmp    $0x9,%eax
f01003ab:	7f 0a                	jg     f01003b7 <cons_putc+0xae>
f01003ad:	83 f8 08             	cmp    $0x8,%eax
f01003b0:	74 15                	je     f01003c7 <cons_putc+0xbe>
f01003b2:	e9 9a 00 00 00       	jmp    f0100451 <cons_putc+0x148>
f01003b7:	83 f8 0a             	cmp    $0xa,%eax
f01003ba:	74 3b                	je     f01003f7 <cons_putc+0xee>
f01003bc:	83 f8 0d             	cmp    $0xd,%eax
f01003bf:	90                   	nop
f01003c0:	74 3d                	je     f01003ff <cons_putc+0xf6>
f01003c2:	e9 8a 00 00 00       	jmp    f0100451 <cons_putc+0x148>
	case '\b':
		if (crt_pos > 0) {
f01003c7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ce:	66 85 c0             	test   %ax,%ax
f01003d1:	0f 84 e5 00 00 00    	je     f01004bc <cons_putc+0x1b3>
			crt_pos--;
f01003d7:	83 e8 01             	sub    $0x1,%eax
f01003da:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e0:	0f b7 c0             	movzwl %ax,%eax
f01003e3:	66 81 e7 00 ff       	and    $0xff00,%di
f01003e8:	83 cf 20             	or     $0x20,%edi
f01003eb:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003f1:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003f5:	eb 78                	jmp    f010046f <cons_putc+0x166>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003f7:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003fe:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003ff:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100406:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010040c:	c1 e8 16             	shr    $0x16,%eax
f010040f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100412:	c1 e0 04             	shl    $0x4,%eax
f0100415:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f010041b:	eb 52                	jmp    f010046f <cons_putc+0x166>
		break;
	case '\t':
		cons_putc(' ');
f010041d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100422:	e8 e2 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100427:	b8 20 00 00 00       	mov    $0x20,%eax
f010042c:	e8 d8 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100431:	b8 20 00 00 00       	mov    $0x20,%eax
f0100436:	e8 ce fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100440:	e8 c4 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100445:	b8 20 00 00 00       	mov    $0x20,%eax
f010044a:	e8 ba fe ff ff       	call   f0100309 <cons_putc>
f010044f:	eb 1e                	jmp    f010046f <cons_putc+0x166>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100451:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100458:	8d 50 01             	lea    0x1(%eax),%edx
f010045b:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100462:	0f b7 c0             	movzwl %ax,%eax
f0100465:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f010046b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010046f:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100476:	cf 07 
f0100478:	76 42                	jbe    f01004bc <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047a:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f010047f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100486:	00 
f0100487:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010048d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100491:	89 04 24             	mov    %eax,(%esp)
f0100494:	e8 cb 10 00 00       	call   f0101564 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100499:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a4:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004aa:	83 c0 01             	add    $0x1,%eax
f01004ad:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b2:	75 f0                	jne    f01004a4 <cons_putc+0x19b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b4:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004bb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004bc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004c7:	89 ca                	mov    %ecx,%edx
f01004c9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004ca:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004d1:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d4:	89 d8                	mov    %ebx,%eax
f01004d6:	66 c1 e8 08          	shr    $0x8,%ax
f01004da:	89 f2                	mov    %esi,%edx
f01004dc:	ee                   	out    %al,(%dx)
f01004dd:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e2:	89 ca                	mov    %ecx,%edx
f01004e4:	ee                   	out    %al,(%dx)
f01004e5:	89 d8                	mov    %ebx,%eax
f01004e7:	89 f2                	mov    %esi,%edx
f01004e9:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ea:	83 c4 1c             	add    $0x1c,%esp
f01004ed:	5b                   	pop    %ebx
f01004ee:	5e                   	pop    %esi
f01004ef:	5f                   	pop    %edi
f01004f0:	5d                   	pop    %ebp
f01004f1:	c3                   	ret    

f01004f2 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f2:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004f9:	74 11                	je     f010050c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100501:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f0100506:	e8 b1 fc ff ff       	call   f01001bc <cons_intr>
}
f010050b:	c9                   	leave  
f010050c:	f3 c3                	repz ret 

f010050e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010050e:	55                   	push   %ebp
f010050f:	89 e5                	mov    %esp,%ebp
f0100511:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100514:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f0100519:	e8 9e fc ff ff       	call   f01001bc <cons_intr>
}
f010051e:	c9                   	leave  
f010051f:	c3                   	ret    

f0100520 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100520:	55                   	push   %ebp
f0100521:	89 e5                	mov    %esp,%ebp
f0100523:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100526:	e8 c7 ff ff ff       	call   f01004f2 <serial_intr>
	kbd_intr();
f010052b:	e8 de ff ff ff       	call   f010050e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100530:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100535:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f010053b:	74 26                	je     f0100563 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010053d:	8d 50 01             	lea    0x1(%eax),%edx
f0100540:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100546:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010054d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010054f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100555:	75 11                	jne    f0100568 <cons_getc+0x48>
			cons.rpos = 0;
f0100557:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f010055e:	00 00 00 
f0100561:	eb 05                	jmp    f0100568 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100563:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100568:	c9                   	leave  
f0100569:	c3                   	ret    

f010056a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056a:	55                   	push   %ebp
f010056b:	89 e5                	mov    %esp,%ebp
f010056d:	57                   	push   %edi
f010056e:	56                   	push   %esi
f010056f:	53                   	push   %ebx
f0100570:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100573:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100581:	5a a5 
	if (*cp != 0xA55A) {
f0100583:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058e:	74 11                	je     f01005a1 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100590:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100597:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059a:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010059f:	eb 16                	jmp    f01005b7 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a1:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a8:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005af:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b2:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b7:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005bd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c2:	89 ca                	mov    %ecx,%edx
f01005c4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c5:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c8:	89 da                	mov    %ebx,%edx
f01005ca:	ec                   	in     (%dx),%al
f01005cb:	0f b6 f0             	movzbl %al,%esi
f01005ce:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d6:	89 ca                	mov    %ecx,%edx
f01005d8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d9:	89 da                	mov    %ebx,%edx
f01005db:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005dc:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e2:	0f b6 d8             	movzbl %al,%ebx
f01005e5:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e7:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ee:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01005f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f8:	ee                   	out    %al,(%dx)
f01005f9:	b2 fb                	mov    $0xfb,%dl
f01005fb:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100600:	ee                   	out    %al,(%dx)
f0100601:	b2 f8                	mov    $0xf8,%dl
f0100603:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100608:	ee                   	out    %al,(%dx)
f0100609:	b2 f9                	mov    $0xf9,%dl
f010060b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	b2 fb                	mov    $0xfb,%dl
f0100613:	b8 03 00 00 00       	mov    $0x3,%eax
f0100618:	ee                   	out    %al,(%dx)
f0100619:	b2 fc                	mov    $0xfc,%dl
f010061b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100620:	ee                   	out    %al,(%dx)
f0100621:	b2 f9                	mov    $0xf9,%dl
f0100623:	b8 01 00 00 00       	mov    $0x1,%eax
f0100628:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100629:	b2 fd                	mov    $0xfd,%dl
f010062b:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062c:	3c ff                	cmp    $0xff,%al
f010062e:	0f 95 c1             	setne  %cl
f0100631:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100637:	b2 fa                	mov    $0xfa,%dl
f0100639:	ec                   	in     (%dx),%al
f010063a:	b2 f8                	mov    $0xf8,%dl
f010063c:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063d:	84 c9                	test   %cl,%cl
f010063f:	75 0c                	jne    f010064d <cons_init+0xe3>
		cprintf("Serial port does not exist!\n");
f0100641:	c7 04 24 50 1a 10 f0 	movl   $0xf0101a50,(%esp)
f0100648:	e8 7c 03 00 00       	call   f01009c9 <cprintf>
}
f010064d:	83 c4 1c             	add    $0x1c,%esp
f0100650:	5b                   	pop    %ebx
f0100651:	5e                   	pop    %esi
f0100652:	5f                   	pop    %edi
f0100653:	5d                   	pop    %ebp
f0100654:	c3                   	ret    

f0100655 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010065b:	8b 45 08             	mov    0x8(%ebp),%eax
f010065e:	e8 a6 fc ff ff       	call   f0100309 <cons_putc>
}
f0100663:	c9                   	leave  
f0100664:	c3                   	ret    

f0100665 <getchar>:

int
getchar(void)
{
f0100665:	55                   	push   %ebp
f0100666:	89 e5                	mov    %esp,%ebp
f0100668:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010066b:	e8 b0 fe ff ff       	call   f0100520 <cons_getc>
f0100670:	85 c0                	test   %eax,%eax
f0100672:	74 f7                	je     f010066b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100674:	c9                   	leave  
f0100675:	c3                   	ret    

f0100676 <iscons>:

int
iscons(int fdnum)
{
f0100676:	55                   	push   %ebp
f0100677:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100679:	b8 01 00 00 00       	mov    $0x1,%eax
f010067e:	5d                   	pop    %ebp
f010067f:	c3                   	ret    

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
    int i;

    for (i = 0; i < NCOMMANDS; i++)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 a0 1c 10 	movl   $0xf0101ca0,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 be 1c 10 	movl   $0xf0101cbe,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f010069d:	e8 27 03 00 00       	call   f01009c9 <cprintf>
f01006a2:	c7 44 24 08 58 1d 10 	movl   $0xf0101d58,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 cc 1c 10 	movl   $0xf0101ccc,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006b9:	e8 0b 03 00 00       	call   f01009c9 <cprintf>
f01006be:	c7 44 24 08 58 1d 10 	movl   $0xf0101d58,0x8(%esp)
f01006c5:	f0 
f01006c6:	c7 44 24 04 d5 1c 10 	movl   $0xf0101cd5,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006d5:	e8 ef 02 00 00       	call   f01009c9 <cprintf>
    return 0;
}
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	c9                   	leave  
f01006e0:	c3                   	ret    

f01006e1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e1:	55                   	push   %ebp
f01006e2:	89 e5                	mov    %esp,%ebp
f01006e4:	83 ec 18             	sub    $0x18,%esp
    extern char _start[], entry[], etext[], edata[], end[];

    cprintf("Special kernel symbols:\n");
f01006e7:	c7 04 24 df 1c 10 f0 	movl   $0xf0101cdf,(%esp)
f01006ee:	e8 d6 02 00 00       	call   f01009c9 <cprintf>
    cprintf("  _start                  %08x (phys)\n", _start);
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006fa:	00 
f01006fb:	c7 04 24 80 1d 10 f0 	movl   $0xf0101d80,(%esp)
f0100702:	e8 c2 02 00 00       	call   f01009c9 <cprintf>
    cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100707:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 a8 1d 10 f0 	movl   $0xf0101da8,(%esp)
f010071e:	e8 a6 02 00 00       	call   f01009c9 <cprintf>
    cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	c7 44 24 08 a7 19 10 	movl   $0x1019a7,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 a7 19 10 	movl   $0xf01019a7,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 cc 1d 10 f0 	movl   $0xf0101dcc,(%esp)
f010073a:	e8 8a 02 00 00       	call   f01009c9 <cprintf>
    cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 f0 1d 10 f0 	movl   $0xf0101df0,(%esp)
f0100756:	e8 6e 02 00 00       	call   f01009c9 <cprintf>
    cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100762:	00 
f0100763:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010076a:	f0 
f010076b:	c7 04 24 14 1e 10 f0 	movl   $0xf0101e14,(%esp)
f0100772:	e8 52 02 00 00       	call   f01009c9 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
        ROUNDUP(end - entry, 1024) / 1024);
f0100777:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010077c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100781:	25 00 fc ff ff       	and    $0xfffffc00,%eax
    cprintf("  _start                  %08x (phys)\n", _start);
    cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
    cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
    cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
    cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
    cprintf("Kernel executable memory footprint: %dKB\n",
f0100786:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010078c:	85 c0                	test   %eax,%eax
f010078e:	0f 48 c2             	cmovs  %edx,%eax
f0100791:	c1 f8 0a             	sar    $0xa,%eax
f0100794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100798:	c7 04 24 38 1e 10 f0 	movl   $0xf0101e38,(%esp)
f010079f:	e8 25 02 00 00       	call   f01009c9 <cprintf>
        ROUNDUP(end - entry, 1024) / 1024);
    return 0;
}
f01007a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a9:	c9                   	leave  
f01007aa:	c3                   	ret    

f01007ab <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
f01007ae:	56                   	push   %esi
f01007af:	53                   	push   %ebx
f01007b0:	83 ec 40             	sub    $0x40,%esp
    uint32_t *ebp;
    struct Eipdebuginfo info;
    cprintf("Stack backtrac:\n");
f01007b3:	c7 04 24 f8 1c 10 f0 	movl   $0xf0101cf8,(%esp)
f01007ba:	e8 0a 02 00 00       	call   f01009c9 <cprintf>

    ebp = (uint32_t *)read_ebp();
f01007bf:	89 eb                	mov    %ebp,%ebx

    while(ebp){
        cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", 
                &ebp[0], ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
        debuginfo_eip(ebp[1], &info);
f01007c1:	8d 75 e0             	lea    -0x20(%ebp),%esi
    struct Eipdebuginfo info;
    cprintf("Stack backtrac:\n");

    ebp = (uint32_t *)read_ebp();

    while(ebp){
f01007c4:	eb 7a                	jmp    f0100840 <mon_backtrace+0x95>
        cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", 
f01007c6:	8b 43 18             	mov    0x18(%ebx),%eax
f01007c9:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007cd:	8b 43 14             	mov    0x14(%ebx),%eax
f01007d0:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007d4:	8b 43 10             	mov    0x10(%ebx),%eax
f01007d7:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007db:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007de:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007e2:	8b 43 08             	mov    0x8(%ebx),%eax
f01007e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007e9:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ec:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007f4:	c7 04 24 64 1e 10 f0 	movl   $0xf0101e64,(%esp)
f01007fb:	e8 c9 01 00 00       	call   f01009c9 <cprintf>
                &ebp[0], ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
        debuginfo_eip(ebp[1], &info);
f0100800:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100804:	8b 43 04             	mov    0x4(%ebx),%eax
f0100807:	89 04 24             	mov    %eax,(%esp)
f010080a:	e8 b1 02 00 00       	call   f0100ac0 <debuginfo_eip>
            cprintf("\t%s:%u: %.*s+%u\n", 
f010080f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100812:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100816:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100819:	89 44 24 10          	mov    %eax,0x10(%esp)
f010081d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100820:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100824:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100827:	89 44 24 08          	mov    %eax,0x8(%esp)
f010082b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010082e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100832:	c7 04 24 09 1d 10 f0 	movl   $0xf0101d09,(%esp)
f0100839:	e8 8b 01 00 00       	call   f01009c9 <cprintf>
                info.eip_file,
                info.eip_line,
                info.eip_fn_namelen,
                info.eip_fn_name,
                info.eip_fn_addr);
        ebp = (uint32_t *)ebp[0];
f010083e:	8b 1b                	mov    (%ebx),%ebx
    struct Eipdebuginfo info;
    cprintf("Stack backtrac:\n");

    ebp = (uint32_t *)read_ebp();

    while(ebp){
f0100840:	85 db                	test   %ebx,%ebx
f0100842:	75 82                	jne    f01007c6 <mon_backtrace+0x1b>
                info.eip_fn_name,
                info.eip_fn_addr);
        ebp = (uint32_t *)ebp[0];
    }
    return 0;
}
f0100844:	b8 00 00 00 00       	mov    $0x0,%eax
f0100849:	83 c4 40             	add    $0x40,%esp
f010084c:	5b                   	pop    %ebx
f010084d:	5e                   	pop    %esi
f010084e:	5d                   	pop    %ebp
f010084f:	c3                   	ret    

f0100850 <monitor>:
    return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100850:	55                   	push   %ebp
f0100851:	89 e5                	mov    %esp,%ebp
f0100853:	57                   	push   %edi
f0100854:	56                   	push   %esi
f0100855:	53                   	push   %ebx
f0100856:	83 ec 5c             	sub    $0x5c,%esp
    char *buf;

    cprintf("Welcome to the JOS kernel monitor!\n");
f0100859:	c7 04 24 98 1e 10 f0 	movl   $0xf0101e98,(%esp)
f0100860:	e8 64 01 00 00       	call   f01009c9 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
f0100865:	c7 04 24 bc 1e 10 f0 	movl   $0xf0101ebc,(%esp)
f010086c:	e8 58 01 00 00       	call   f01009c9 <cprintf>


    while (1) {
        buf = readline("K> ");
f0100871:	c7 04 24 1a 1d 10 f0 	movl   $0xf0101d1a,(%esp)
f0100878:	e8 43 0a 00 00       	call   f01012c0 <readline>
f010087d:	89 c3                	mov    %eax,%ebx
        if (buf != NULL)
f010087f:	85 c0                	test   %eax,%eax
f0100881:	74 ee                	je     f0100871 <monitor+0x21>
    char *argv[MAXARGS];
    int i;

    // Parse the command buffer into whitespace-separated arguments
    argc = 0;
    argv[argc] = 0;
f0100883:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
    int argc;
    char *argv[MAXARGS];
    int i;

    // Parse the command buffer into whitespace-separated arguments
    argc = 0;
f010088a:	be 00 00 00 00       	mov    $0x0,%esi
f010088f:	eb 0a                	jmp    f010089b <monitor+0x4b>
    argv[argc] = 0;
    while (1) {
        // gobble whitespace
        while (*buf && strchr(WHITESPACE, *buf))
            *buf++ = 0;
f0100891:	c6 03 00             	movb   $0x0,(%ebx)
f0100894:	89 f7                	mov    %esi,%edi
f0100896:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100899:	89 fe                	mov    %edi,%esi
    // Parse the command buffer into whitespace-separated arguments
    argc = 0;
    argv[argc] = 0;
    while (1) {
        // gobble whitespace
        while (*buf && strchr(WHITESPACE, *buf))
f010089b:	0f b6 03             	movzbl (%ebx),%eax
f010089e:	84 c0                	test   %al,%al
f01008a0:	74 63                	je     f0100905 <monitor+0xb5>
f01008a2:	0f be c0             	movsbl %al,%eax
f01008a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a9:	c7 04 24 1e 1d 10 f0 	movl   $0xf0101d1e,(%esp)
f01008b0:	e8 25 0c 00 00       	call   f01014da <strchr>
f01008b5:	85 c0                	test   %eax,%eax
f01008b7:	75 d8                	jne    f0100891 <monitor+0x41>
            *buf++ = 0;
        if (*buf == 0)
f01008b9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008bc:	74 47                	je     f0100905 <monitor+0xb5>
            break;

        // save and scan past next arg
        if (argc == MAXARGS-1) {
f01008be:	83 fe 0f             	cmp    $0xf,%esi
f01008c1:	75 16                	jne    f01008d9 <monitor+0x89>
            cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008c3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ca:	00 
f01008cb:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01008d2:	e8 f2 00 00 00       	call   f01009c9 <cprintf>
f01008d7:	eb 98                	jmp    f0100871 <monitor+0x21>
            return 0;
        }
        argv[argc++] = buf;
f01008d9:	8d 7e 01             	lea    0x1(%esi),%edi
f01008dc:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008e0:	eb 03                	jmp    f01008e5 <monitor+0x95>
        while (*buf && !strchr(WHITESPACE, *buf))
            buf++;
f01008e2:	83 c3 01             	add    $0x1,%ebx
        if (argc == MAXARGS-1) {
            cprintf("Too many arguments (max %d)\n", MAXARGS);
            return 0;
        }
        argv[argc++] = buf;
        while (*buf && !strchr(WHITESPACE, *buf))
f01008e5:	0f b6 03             	movzbl (%ebx),%eax
f01008e8:	84 c0                	test   %al,%al
f01008ea:	74 ad                	je     f0100899 <monitor+0x49>
f01008ec:	0f be c0             	movsbl %al,%eax
f01008ef:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f3:	c7 04 24 1e 1d 10 f0 	movl   $0xf0101d1e,(%esp)
f01008fa:	e8 db 0b 00 00       	call   f01014da <strchr>
f01008ff:	85 c0                	test   %eax,%eax
f0100901:	74 df                	je     f01008e2 <monitor+0x92>
f0100903:	eb 94                	jmp    f0100899 <monitor+0x49>
            buf++;
    }
    argv[argc] = 0;
f0100905:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010090c:	00 

    // Lookup and invoke the command
    if (argc == 0)
f010090d:	85 f6                	test   %esi,%esi
f010090f:	0f 84 5c ff ff ff    	je     f0100871 <monitor+0x21>
f0100915:	bb 00 00 00 00       	mov    $0x0,%ebx
f010091a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
        return 0;
    for (i = 0; i < NCOMMANDS; i++) {
        if (strcmp(argv[0], commands[i].name) == 0)
f010091d:	8b 04 85 00 1f 10 f0 	mov    -0xfefe100(,%eax,4),%eax
f0100924:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100928:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010092b:	89 04 24             	mov    %eax,(%esp)
f010092e:	e8 49 0b 00 00       	call   f010147c <strcmp>
f0100933:	85 c0                	test   %eax,%eax
f0100935:	75 24                	jne    f010095b <monitor+0x10b>
            return commands[i].func(argc, argv, tf);
f0100937:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010093a:	8b 55 08             	mov    0x8(%ebp),%edx
f010093d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100941:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100944:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100948:	89 34 24             	mov    %esi,(%esp)
f010094b:	ff 14 85 08 1f 10 f0 	call   *-0xfefe0f8(,%eax,4)


    while (1) {
        buf = readline("K> ");
        if (buf != NULL)
            if (runcmd(buf, tf) < 0)
f0100952:	85 c0                	test   %eax,%eax
f0100954:	78 25                	js     f010097b <monitor+0x12b>
f0100956:	e9 16 ff ff ff       	jmp    f0100871 <monitor+0x21>
    argv[argc] = 0;

    // Lookup and invoke the command
    if (argc == 0)
        return 0;
    for (i = 0; i < NCOMMANDS; i++) {
f010095b:	83 c3 01             	add    $0x1,%ebx
f010095e:	83 fb 03             	cmp    $0x3,%ebx
f0100961:	75 b7                	jne    f010091a <monitor+0xca>
        if (strcmp(argv[0], commands[i].name) == 0)
            return commands[i].func(argc, argv, tf);
    }
    cprintf("Unknown command '%s'\n", argv[0]);
f0100963:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100966:	89 44 24 04          	mov    %eax,0x4(%esp)
f010096a:	c7 04 24 40 1d 10 f0 	movl   $0xf0101d40,(%esp)
f0100971:	e8 53 00 00 00       	call   f01009c9 <cprintf>
f0100976:	e9 f6 fe ff ff       	jmp    f0100871 <monitor+0x21>
        buf = readline("K> ");
        if (buf != NULL)
            if (runcmd(buf, tf) < 0)
                break;
    }
f010097b:	83 c4 5c             	add    $0x5c,%esp
f010097e:	5b                   	pop    %ebx
f010097f:	5e                   	pop    %esi
f0100980:	5f                   	pop    %edi
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    

f0100983 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100989:	8b 45 08             	mov    0x8(%ebp),%eax
f010098c:	89 04 24             	mov    %eax,(%esp)
f010098f:	e8 c1 fc ff ff       	call   f0100655 <cputchar>
	*cnt++;
}
f0100994:	c9                   	leave  
f0100995:	c3                   	ret    

f0100996 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100996:	55                   	push   %ebp
f0100997:	89 e5                	mov    %esp,%ebp
f0100999:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010099c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009a3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009b1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b8:	c7 04 24 83 09 10 f0 	movl   $0xf0100983,(%esp)
f01009bf:	e8 9a 04 00 00       	call   f0100e5e <vprintfmt>
	return cnt;
}
f01009c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009c7:	c9                   	leave  
f01009c8:	c3                   	ret    

f01009c9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009c9:	55                   	push   %ebp
f01009ca:	89 e5                	mov    %esp,%ebp
f01009cc:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009cf:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01009d9:	89 04 24             	mov    %eax,(%esp)
f01009dc:	e8 b5 ff ff ff       	call   f0100996 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009e1:	c9                   	leave  
f01009e2:	c3                   	ret    

f01009e3 <stab_binsearch>:
//      will exit setting left = 118, right = 554.
//
static void
stab_binsearch (const struct Stab *stabs, int *region_left, int *region_right,
                int type, uintptr_t addr)
{
f01009e3:	55                   	push   %ebp
f01009e4:	89 e5                	mov    %esp,%ebp
f01009e6:	57                   	push   %edi
f01009e7:	56                   	push   %esi
f01009e8:	53                   	push   %ebx
f01009e9:	83 ec 10             	sub    $0x10,%esp
f01009ec:	89 c6                	mov    %eax,%esi
f01009ee:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009f1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009f4:	8b 7d 08             	mov    0x8(%ebp),%edi
    int l = *region_left, r = *region_right, any_matches = 0;
f01009f7:	8b 1a                	mov    (%edx),%ebx
f01009f9:	8b 01                	mov    (%ecx),%eax
f01009fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009fe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

    while (l <= r)
f0100a05:	eb 77                	jmp    f0100a7e <stab_binsearch+0x9b>
    {
        int true_m = (l + r) / 2, m = true_m;
f0100a07:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a0a:	01 d8                	add    %ebx,%eax
f0100a0c:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a11:	99                   	cltd   
f0100a12:	f7 f9                	idiv   %ecx
f0100a14:	89 c1                	mov    %eax,%ecx

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type)
f0100a16:	eb 01                	jmp    f0100a19 <stab_binsearch+0x36>
            m--;
f0100a18:	49                   	dec    %ecx
    while (l <= r)
    {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type)
f0100a19:	39 d9                	cmp    %ebx,%ecx
f0100a1b:	7c 1d                	jl     f0100a3a <stab_binsearch+0x57>
f0100a1d:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a20:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a25:	39 fa                	cmp    %edi,%edx
f0100a27:	75 ef                	jne    f0100a18 <stab_binsearch+0x35>
f0100a29:	89 4d ec             	mov    %ecx,-0x14(%ebp)
            continue;
        }

        // actual binary search
        any_matches = 1;
        if (stabs[m].n_value < addr)
f0100a2c:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a2f:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a33:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a36:	73 18                	jae    f0100a50 <stab_binsearch+0x6d>
f0100a38:	eb 05                	jmp    f0100a3f <stab_binsearch+0x5c>
        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type)
            m--;
        if (m < l)
        {                       // no match in [l, m]
            l = true_m + 1;
f0100a3a:	8d 58 01             	lea    0x1(%eax),%ebx
            continue;
f0100a3d:	eb 3f                	jmp    f0100a7e <stab_binsearch+0x9b>

        // actual binary search
        any_matches = 1;
        if (stabs[m].n_value < addr)
        {
            *region_left = m;
f0100a3f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a42:	89 0b                	mov    %ecx,(%ebx)
            l = true_m + 1;
f0100a44:	8d 58 01             	lea    0x1(%eax),%ebx
            l = true_m + 1;
            continue;
        }

        // actual binary search
        any_matches = 1;
f0100a47:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a4e:	eb 2e                	jmp    f0100a7e <stab_binsearch+0x9b>
        if (stabs[m].n_value < addr)
        {
            *region_left = m;
            l = true_m + 1;
        }
        else if (stabs[m].n_value > addr)
f0100a50:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a53:	73 15                	jae    f0100a6a <stab_binsearch+0x87>
        {
            *region_right = m - 1;
f0100a55:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a58:	48                   	dec    %eax
f0100a59:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a5c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a5f:	89 01                	mov    %eax,(%ecx)
            l = true_m + 1;
            continue;
        }

        // actual binary search
        any_matches = 1;
f0100a61:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a68:	eb 14                	jmp    f0100a7e <stab_binsearch+0x9b>
        }
        else
        {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
f0100a6a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a6d:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a70:	89 18                	mov    %ebx,(%eax)
            l = m;
            addr++;
f0100a72:	ff 45 0c             	incl   0xc(%ebp)
f0100a75:	89 cb                	mov    %ecx,%ebx
            l = true_m + 1;
            continue;
        }

        // actual binary search
        any_matches = 1;
f0100a77:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch (const struct Stab *stabs, int *region_left, int *region_right,
                int type, uintptr_t addr)
{
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r)
f0100a7e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a81:	7e 84                	jle    f0100a07 <stab_binsearch+0x24>
            l = m;
            addr++;
        }
    }

    if (!any_matches)
f0100a83:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a87:	75 0d                	jne    f0100a96 <stab_binsearch+0xb3>
        *region_right = *region_left - 1;
f0100a89:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a8c:	8b 00                	mov    (%eax),%eax
f0100a8e:	48                   	dec    %eax
f0100a8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a92:	89 07                	mov    %eax,(%edi)
f0100a94:	eb 22                	jmp    f0100ab8 <stab_binsearch+0xd5>
    else
    {
        // find rightmost region containing 'addr'
        for (l = *region_right;
f0100a96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a99:	8b 00                	mov    (%eax),%eax
             l > *region_left && stabs[l].n_type != type; l--)
f0100a9b:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a9e:	8b 0b                	mov    (%ebx),%ecx
    if (!any_matches)
        *region_right = *region_left - 1;
    else
    {
        // find rightmost region containing 'addr'
        for (l = *region_right;
f0100aa0:	eb 01                	jmp    f0100aa3 <stab_binsearch+0xc0>
             l > *region_left && stabs[l].n_type != type; l--)
f0100aa2:	48                   	dec    %eax
    if (!any_matches)
        *region_right = *region_left - 1;
    else
    {
        // find rightmost region containing 'addr'
        for (l = *region_right;
f0100aa3:	39 c1                	cmp    %eax,%ecx
f0100aa5:	7d 0c                	jge    f0100ab3 <stab_binsearch+0xd0>
f0100aa7:	6b d0 0c             	imul   $0xc,%eax,%edx
             l > *region_left && stabs[l].n_type != type; l--)
f0100aaa:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100aaf:	39 fa                	cmp    %edi,%edx
f0100ab1:	75 ef                	jne    f0100aa2 <stab_binsearch+0xbf>
            /* do nothing */ ;
        *region_left = l;
f0100ab3:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100ab6:	89 07                	mov    %eax,(%edi)
    }
}
f0100ab8:	83 c4 10             	add    $0x10,%esp
f0100abb:	5b                   	pop    %ebx
f0100abc:	5e                   	pop    %esi
f0100abd:	5f                   	pop    %edi
f0100abe:	5d                   	pop    %ebp
f0100abf:	c3                   	ret    

f0100ac0 <debuginfo_eip>:
//      negative if not.  But even if it returns negative it has stored some
//      information into '*info'.
//
int
debuginfo_eip (uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ac0:	55                   	push   %ebp
f0100ac1:	89 e5                	mov    %esp,%ebp
f0100ac3:	57                   	push   %edi
f0100ac4:	56                   	push   %esi
f0100ac5:	53                   	push   %ebx
f0100ac6:	83 ec 3c             	sub    $0x3c,%esp
f0100ac9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100acc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    const struct Stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;
    int lfile, rfile, lfun, rfun, lline, rline;

    // Initialize *info
    info->eip_file = "<unknown>";
f0100acf:	c7 03 24 1f 10 f0    	movl   $0xf0101f24,(%ebx)
    info->eip_line = 0;
f0100ad5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
    info->eip_fn_name = "<unknown>";
f0100adc:	c7 43 08 24 1f 10 f0 	movl   $0xf0101f24,0x8(%ebx)
    info->eip_fn_namelen = 9;
f0100ae3:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
    info->eip_fn_addr = addr;
f0100aea:	89 73 10             	mov    %esi,0x10(%ebx)
    info->eip_fn_narg = 0;
f0100aed:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

    // Find the relevant set of stabs
    if (addr >= ULIM)
f0100af4:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100afa:	76 12                	jbe    f0100b0e <debuginfo_eip+0x4e>
        // Can't search for user-level addresses yet!
        panic ("User address");
    }

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100afc:	b8 8e 73 10 f0       	mov    $0xf010738e,%eax
f0100b01:	3d 71 5a 10 f0       	cmp    $0xf0105a71,%eax
f0100b06:	0f 86 b7 01 00 00    	jbe    f0100cc3 <debuginfo_eip+0x203>
f0100b0c:	eb 1c                	jmp    f0100b2a <debuginfo_eip+0x6a>
        stabstr_end = __STABSTR_END__;
    }
    else
    {
        // Can't search for user-level addresses yet!
        panic ("User address");
f0100b0e:	c7 44 24 08 2e 1f 10 	movl   $0xf0101f2e,0x8(%esp)
f0100b15:	f0 
f0100b16:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
f0100b1d:	00 
f0100b1e:	c7 04 24 3b 1f 10 f0 	movl   $0xf0101f3b,(%esp)
f0100b25:	e8 ce f5 ff ff       	call   f01000f8 <_panic>
    }

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b2a:	80 3d 8d 73 10 f0 00 	cmpb   $0x0,0xf010738d
f0100b31:	0f 85 93 01 00 00    	jne    f0100cca <debuginfo_eip+0x20a>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    lfile = 0;
f0100b37:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    rfile = (stab_end - stabs) - 1;
f0100b3e:	b8 70 5a 10 f0       	mov    $0xf0105a70,%eax
f0100b43:	2d 70 21 10 f0       	sub    $0xf0102170,%eax
f0100b48:	c1 f8 02             	sar    $0x2,%eax
f0100b4b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b51:	83 e8 01             	sub    $0x1,%eax
f0100b54:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch (stabs, &lfile, &rfile, N_SO, addr);
f0100b57:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b5b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b62:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b65:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b68:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100b6d:	e8 71 fe ff ff       	call   f01009e3 <stab_binsearch>
    if (lfile == 0)
f0100b72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b75:	85 c0                	test   %eax,%eax
f0100b77:	0f 84 54 01 00 00    	je     f0100cd1 <debuginfo_eip+0x211>
        return -1;

    // Search within that file's stabs for the function definition
    // (N_FUN).
    lfun = lfile;
f0100b7d:	89 45 dc             	mov    %eax,-0x24(%ebp)
    rfun = rfile;
f0100b80:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b83:	89 45 d8             	mov    %eax,-0x28(%ebp)
    stab_binsearch (stabs, &lfun, &rfun, N_FUN, addr);
f0100b86:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b8a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b91:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b94:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b97:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100b9c:	e8 42 fe ff ff       	call   f01009e3 <stab_binsearch>

    if (lfun <= rfun)
f0100ba1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ba4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ba7:	39 d0                	cmp    %edx,%eax
f0100ba9:	7f 3d                	jg     f0100be8 <debuginfo_eip+0x128>
    {
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bab:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bae:	8d b9 70 21 10 f0    	lea    -0xfefde90(%ecx),%edi
f0100bb4:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bb7:	8b 89 70 21 10 f0    	mov    -0xfefde90(%ecx),%ecx
f0100bbd:	bf 8e 73 10 f0       	mov    $0xf010738e,%edi
f0100bc2:	81 ef 71 5a 10 f0    	sub    $0xf0105a71,%edi
f0100bc8:	39 f9                	cmp    %edi,%ecx
f0100bca:	73 09                	jae    f0100bd5 <debuginfo_eip+0x115>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bcc:	81 c1 71 5a 10 f0    	add    $0xf0105a71,%ecx
f0100bd2:	89 4b 08             	mov    %ecx,0x8(%ebx)
        info->eip_fn_addr = stabs[lfun].n_value;
f0100bd5:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bd8:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bdb:	89 4b 10             	mov    %ecx,0x10(%ebx)
        addr -= info->eip_fn_addr;
f0100bde:	29 ce                	sub    %ecx,%esi
        // Search within the function definition for the line number.
        lline = lfun;
f0100be0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
f0100be3:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100be6:	eb 0f                	jmp    f0100bf7 <debuginfo_eip+0x137>
    }
    else
    {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
f0100be8:	89 73 10             	mov    %esi,0x10(%ebx)
        lline = lfile;
f0100beb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
f0100bf1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bf4:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    // Ignore stuff after the colon.
    info->eip_fn_namelen =
        strfind (info->eip_fn_name, ':') - info->eip_fn_name;
f0100bf7:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bfe:	00 
f0100bff:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c02:	89 04 24             	mov    %eax,(%esp)
f0100c05:	e8 f1 08 00 00       	call   f01014fb <strfind>
f0100c0a:	2b 43 08             	sub    0x8(%ebx),%eax
        info->eip_fn_addr = addr;
        lline = lfile;
        rline = rfile;
    }
    // Ignore stuff after the colon.
    info->eip_fn_namelen =
f0100c0d:	89 43 0c             	mov    %eax,0xc(%ebx)

    /*Hawx: find the line number.
       Relative address about lline & rline
       had been translated by the above code
     */
    stab_binsearch (stabs, &lline, &rline, N_SLINE, addr);
f0100c10:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c14:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c1b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c1e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c21:	b8 70 21 10 f0       	mov    $0xf0102170,%eax
f0100c26:	e8 b8 fd ff ff       	call   f01009e3 <stab_binsearch>
    info->eip_line = stabs[lline].n_desc;
f0100c2b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c2e:	6b c2 0c             	imul   $0xc,%edx,%eax
f0100c31:	05 70 21 10 f0       	add    $0xf0102170,%eax
f0100c36:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100c3a:	89 4b 04             	mov    %ecx,0x4(%ebx)
    // Search backwards from the line number for the relevant filename
    // stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
f0100c3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c40:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100c43:	eb 06                	jmp    f0100c4b <debuginfo_eip+0x18b>
f0100c45:	83 ea 01             	sub    $0x1,%edx
f0100c48:	83 e8 0c             	sub    $0xc,%eax
f0100c4b:	89 d6                	mov    %edx,%esi
f0100c4d:	39 55 c4             	cmp    %edx,-0x3c(%ebp)
f0100c50:	7f 33                	jg     f0100c85 <debuginfo_eip+0x1c5>
           && stabs[lline].n_type != N_SOL
f0100c52:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c56:	80 f9 84             	cmp    $0x84,%cl
f0100c59:	74 0b                	je     f0100c66 <debuginfo_eip+0x1a6>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c5b:	80 f9 64             	cmp    $0x64,%cl
f0100c5e:	75 e5                	jne    f0100c45 <debuginfo_eip+0x185>
f0100c60:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c64:	74 df                	je     f0100c45 <debuginfo_eip+0x185>
        lline--;
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c66:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c69:	8b 86 70 21 10 f0    	mov    -0xfefde90(%esi),%eax
f0100c6f:	ba 8e 73 10 f0       	mov    $0xf010738e,%edx
f0100c74:	81 ea 71 5a 10 f0    	sub    $0xf0105a71,%edx
f0100c7a:	39 d0                	cmp    %edx,%eax
f0100c7c:	73 07                	jae    f0100c85 <debuginfo_eip+0x1c5>
        info->eip_file = stabstr + stabs[lline].n_strx;
f0100c7e:	05 71 5a 10 f0       	add    $0xf0105a71,%eax
f0100c83:	89 03                	mov    %eax,(%ebx)


    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun)
f0100c85:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c88:	8b 4d d8             	mov    -0x28(%ebp),%ecx
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM; lline++)
            info->eip_fn_narg++;

    return 0;
f0100c8b:	b8 00 00 00 00       	mov    $0x0,%eax
        info->eip_file = stabstr + stabs[lline].n_strx;


    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun)
f0100c90:	39 ca                	cmp    %ecx,%edx
f0100c92:	7d 49                	jge    f0100cdd <debuginfo_eip+0x21d>
        for (lline = lfun + 1;
f0100c94:	8d 42 01             	lea    0x1(%edx),%eax
f0100c97:	89 c2                	mov    %eax,%edx
f0100c99:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c9c:	05 70 21 10 f0       	add    $0xf0102170,%eax
f0100ca1:	89 ce                	mov    %ecx,%esi
f0100ca3:	eb 04                	jmp    f0100ca9 <debuginfo_eip+0x1e9>
             lline < rfun && stabs[lline].n_type == N_PSYM; lline++)
            info->eip_fn_narg++;
f0100ca5:	83 43 14 01          	addl   $0x1,0x14(%ebx)


    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun)
        for (lline = lfun + 1;
f0100ca9:	39 d6                	cmp    %edx,%esi
f0100cab:	7e 2b                	jle    f0100cd8 <debuginfo_eip+0x218>
             lline < rfun && stabs[lline].n_type == N_PSYM; lline++)
f0100cad:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cb1:	83 c2 01             	add    $0x1,%edx
f0100cb4:	83 c0 0c             	add    $0xc,%eax
f0100cb7:	80 f9 a0             	cmp    $0xa0,%cl
f0100cba:	74 e9                	je     f0100ca5 <debuginfo_eip+0x1e5>
            info->eip_fn_narg++;

    return 0;
f0100cbc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cc1:	eb 1a                	jmp    f0100cdd <debuginfo_eip+0x21d>
        panic ("User address");
    }

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
        return -1;
f0100cc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc8:	eb 13                	jmp    f0100cdd <debuginfo_eip+0x21d>
f0100cca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ccf:	eb 0c                	jmp    f0100cdd <debuginfo_eip+0x21d>
    // Search the entire set of stabs for the source file (type N_SO).
    lfile = 0;
    rfile = (stab_end - stabs) - 1;
    stab_binsearch (stabs, &lfile, &rfile, N_SO, addr);
    if (lfile == 0)
        return -1;
f0100cd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd6:	eb 05                	jmp    f0100cdd <debuginfo_eip+0x21d>
    if (lfun < rfun)
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM; lline++)
            info->eip_fn_narg++;

    return 0;
f0100cd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cdd:	83 c4 3c             	add    $0x3c,%esp
f0100ce0:	5b                   	pop    %ebx
f0100ce1:	5e                   	pop    %esi
f0100ce2:	5f                   	pop    %edi
f0100ce3:	5d                   	pop    %ebp
f0100ce4:	c3                   	ret    
f0100ce5:	66 90                	xchg   %ax,%ax
f0100ce7:	66 90                	xchg   %ax,%ax
f0100ce9:	66 90                	xchg   %ax,%ax
f0100ceb:	66 90                	xchg   %ax,%ax
f0100ced:	66 90                	xchg   %ax,%ax
f0100cef:	90                   	nop

f0100cf0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum (void (*putch) (int, void *), void *putdat,
          unsigned long long num, unsigned base, int width, int padc)
{
f0100cf0:	55                   	push   %ebp
f0100cf1:	89 e5                	mov    %esp,%ebp
f0100cf3:	57                   	push   %edi
f0100cf4:	56                   	push   %esi
f0100cf5:	53                   	push   %ebx
f0100cf6:	83 ec 3c             	sub    $0x3c,%esp
f0100cf9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cfc:	89 d7                	mov    %edx,%edi
f0100cfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d01:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d07:	89 c3                	mov    %eax,%ebx
f0100d09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d0c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d0f:	8b 75 14             	mov    0x14(%ebp),%esi
    // first recursively print all preceding (more significant) digits
    if (num >= base)
f0100d12:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d17:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d1a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d1d:	39 d9                	cmp    %ebx,%ecx
f0100d1f:	72 05                	jb     f0100d26 <printnum+0x36>
f0100d21:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d24:	77 69                	ja     f0100d8f <printnum+0x9f>
    {
        printnum (putch, putdat, num / base, base, width - 1, padc);
f0100d26:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d29:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d2d:	83 ee 01             	sub    $0x1,%esi
f0100d30:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d34:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d38:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d3c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d40:	89 c3                	mov    %eax,%ebx
f0100d42:	89 d6                	mov    %edx,%esi
f0100d44:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d47:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d4a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d4e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d52:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d55:	89 04 24             	mov    %eax,(%esp)
f0100d58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d5f:	e8 bc 09 00 00       	call   f0101720 <__udivdi3>
f0100d64:	89 d9                	mov    %ebx,%ecx
f0100d66:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d6a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d6e:	89 04 24             	mov    %eax,(%esp)
f0100d71:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d75:	89 fa                	mov    %edi,%edx
f0100d77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d7a:	e8 71 ff ff ff       	call   f0100cf0 <printnum>
f0100d7f:	eb 1b                	jmp    f0100d9c <printnum+0xac>
    }
    else
    {
        // print any needed pad characters before first digit
        while (--width > 0)
            putch (padc, putdat);
f0100d81:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d85:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d88:	89 04 24             	mov    %eax,(%esp)
f0100d8b:	ff d3                	call   *%ebx
f0100d8d:	eb 03                	jmp    f0100d92 <printnum+0xa2>
f0100d8f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
        printnum (putch, putdat, num / base, base, width - 1, padc);
    }
    else
    {
        // print any needed pad characters before first digit
        while (--width > 0)
f0100d92:	83 ee 01             	sub    $0x1,%esi
f0100d95:	85 f6                	test   %esi,%esi
f0100d97:	7f e8                	jg     f0100d81 <printnum+0x91>
f0100d99:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
            putch (padc, putdat);
    }

    // then print this (the least significant) digit
    putch ("0123456789abcdef"[num % base], putdat);
f0100d9c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100da0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100da4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100da7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100daa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100db2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db5:	89 04 24             	mov    %eax,(%esp)
f0100db8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dbf:	e8 8c 0a 00 00       	call   f0101850 <__umoddi3>
f0100dc4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dc8:	0f be 80 49 1f 10 f0 	movsbl -0xfefe0b7(%eax),%eax
f0100dcf:	89 04 24             	mov    %eax,(%esp)
f0100dd2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dd5:	ff d0                	call   *%eax
}
f0100dd7:	83 c4 3c             	add    $0x3c,%esp
f0100dda:	5b                   	pop    %ebx
f0100ddb:	5e                   	pop    %esi
f0100ddc:	5f                   	pop    %edi
f0100ddd:	5d                   	pop    %ebp
f0100dde:	c3                   	ret    

f0100ddf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint (va_list * ap, int lflag)
{
f0100ddf:	55                   	push   %ebp
f0100de0:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2)
f0100de2:	83 fa 01             	cmp    $0x1,%edx
f0100de5:	7e 0e                	jle    f0100df5 <getuint+0x16>
        return va_arg (*ap, unsigned long long);
f0100de7:	8b 10                	mov    (%eax),%edx
f0100de9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100dec:	89 08                	mov    %ecx,(%eax)
f0100dee:	8b 02                	mov    (%edx),%eax
f0100df0:	8b 52 04             	mov    0x4(%edx),%edx
f0100df3:	eb 22                	jmp    f0100e17 <getuint+0x38>
    else if (lflag)
f0100df5:	85 d2                	test   %edx,%edx
f0100df7:	74 10                	je     f0100e09 <getuint+0x2a>
        return va_arg (*ap, unsigned long);
f0100df9:	8b 10                	mov    (%eax),%edx
f0100dfb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dfe:	89 08                	mov    %ecx,(%eax)
f0100e00:	8b 02                	mov    (%edx),%eax
f0100e02:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e07:	eb 0e                	jmp    f0100e17 <getuint+0x38>
    else
        return va_arg (*ap, unsigned int);
f0100e09:	8b 10                	mov    (%eax),%edx
f0100e0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e0e:	89 08                	mov    %ecx,(%eax)
f0100e10:	8b 02                	mov    (%edx),%eax
f0100e12:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e17:	5d                   	pop    %ebp
f0100e18:	c3                   	ret    

f0100e19 <sprintputch>:
    int cnt;
};

static void
sprintputch (int ch, struct sprintbuf *b)
{
f0100e19:	55                   	push   %ebp
f0100e1a:	89 e5                	mov    %esp,%ebp
f0100e1c:	8b 45 0c             	mov    0xc(%ebp),%eax
    b->cnt++;
f0100e1f:	83 40 08 01          	addl   $0x1,0x8(%eax)
    if (b->buf < b->ebuf)
f0100e23:	8b 10                	mov    (%eax),%edx
f0100e25:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e28:	73 0a                	jae    f0100e34 <sprintputch+0x1b>
        *b->buf++ = ch;
f0100e2a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e2d:	89 08                	mov    %ecx,(%eax)
f0100e2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e32:	88 02                	mov    %al,(%edx)
}
f0100e34:	5d                   	pop    %ebp
f0100e35:	c3                   	ret    

f0100e36 <printfmt>:
    }
}

void
printfmt (void (*putch) (int, void *), void *putdat, const char *fmt, ...)
{
f0100e36:	55                   	push   %ebp
f0100e37:	89 e5                	mov    %esp,%ebp
f0100e39:	83 ec 18             	sub    $0x18,%esp
    va_list ap;

    va_start (ap, fmt);
f0100e3c:	8d 45 14             	lea    0x14(%ebp),%eax
    vprintfmt (putch, putdat, fmt, ap);
f0100e3f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e43:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e46:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e4d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e51:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e54:	89 04 24             	mov    %eax,(%esp)
f0100e57:	e8 02 00 00 00       	call   f0100e5e <vprintfmt>
    va_end (ap);
}
f0100e5c:	c9                   	leave  
f0100e5d:	c3                   	ret    

f0100e5e <vprintfmt>:
               ...);

void
vprintfmt (void (*putch) (int, void *), void *putdat, const char *fmt,
           va_list ap)
{
f0100e5e:	55                   	push   %ebp
f0100e5f:	89 e5                	mov    %esp,%ebp
f0100e61:	57                   	push   %edi
f0100e62:	56                   	push   %esi
f0100e63:	53                   	push   %ebx
f0100e64:	83 ec 3c             	sub    $0x3c,%esp
f0100e67:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e6a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e6d:	eb 14                	jmp    f0100e83 <vprintfmt+0x25>

    while (1)
    {
        while ((ch = *(unsigned char *) fmt++) != '%')
        {
            if (ch == '\0')
f0100e6f:	85 c0                	test   %eax,%eax
f0100e71:	0f 84 b3 03 00 00    	je     f010122a <vprintfmt+0x3cc>
                return;
            putch (ch, putdat);
f0100e77:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e7b:	89 04 24             	mov    %eax,(%esp)
f0100e7e:	ff 55 08             	call   *0x8(%ebp)
    int base, lflag, width, precision, altflag;
    char padc;

    while (1)
    {
        while ((ch = *(unsigned char *) fmt++) != '%')
f0100e81:	89 f3                	mov    %esi,%ebx
f0100e83:	8d 73 01             	lea    0x1(%ebx),%esi
f0100e86:	0f b6 03             	movzbl (%ebx),%eax
f0100e89:	83 f8 25             	cmp    $0x25,%eax
f0100e8c:	75 e1                	jne    f0100e6f <vprintfmt+0x11>
f0100e8e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e92:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100e99:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ea0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100ea7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eac:	eb 1d                	jmp    f0100ecb <vprintfmt+0x6d>
        width = -1;
        precision = -1;
        lflag = 0;
        altflag = 0;
      reswitch:
        switch (ch = *(unsigned char *) fmt++)
f0100eae:	89 de                	mov    %ebx,%esi
        {

            // flag to pad on the right
        case '-':
            padc = '-';
f0100eb0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100eb4:	eb 15                	jmp    f0100ecb <vprintfmt+0x6d>
        width = -1;
        precision = -1;
        lflag = 0;
        altflag = 0;
      reswitch:
        switch (ch = *(unsigned char *) fmt++)
f0100eb6:	89 de                	mov    %ebx,%esi
            padc = '-';
            goto reswitch;

            // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
f0100eb8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100ebc:	eb 0d                	jmp    f0100ecb <vprintfmt+0x6d>
            altflag = 1;
            goto reswitch;

          process_precision:
            if (width < 0)
                width = precision, precision = -1;
f0100ebe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ec1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ec4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
        width = -1;
        precision = -1;
        lflag = 0;
        altflag = 0;
      reswitch:
        switch (ch = *(unsigned char *) fmt++)
f0100ecb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100ece:	0f b6 0e             	movzbl (%esi),%ecx
f0100ed1:	0f b6 c1             	movzbl %cl,%eax
f0100ed4:	83 e9 23             	sub    $0x23,%ecx
f0100ed7:	80 f9 55             	cmp    $0x55,%cl
f0100eda:	0f 87 2a 03 00 00    	ja     f010120a <vprintfmt+0x3ac>
f0100ee0:	0f b6 c9             	movzbl %cl,%ecx
f0100ee3:	ff 24 8d e0 1f 10 f0 	jmp    *-0xfefe020(,%ecx,4)
f0100eea:	89 de                	mov    %ebx,%esi
f0100eec:	b9 00 00 00 00       	mov    $0x0,%ecx
        case '7':
        case '8':
        case '9':
            for (precision = 0;; ++fmt)
            {
                precision = precision * 10 + ch - '0';
f0100ef1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100ef4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
                ch = *fmt;
f0100ef8:	0f be 06             	movsbl (%esi),%eax
                if (ch < '0' || ch > '9')
f0100efb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100efe:	83 fb 09             	cmp    $0x9,%ebx
f0100f01:	77 36                	ja     f0100f39 <vprintfmt+0xdb>
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            for (precision = 0;; ++fmt)
f0100f03:	83 c6 01             	add    $0x1,%esi
            {
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9')
                    break;
            }
f0100f06:	eb e9                	jmp    f0100ef1 <vprintfmt+0x93>
            goto process_precision;

        case '*':
            precision = va_arg (ap, int);
f0100f08:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f0b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f0e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f11:	8b 00                	mov    (%eax),%eax
f0100f13:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        width = -1;
        precision = -1;
        lflag = 0;
        altflag = 0;
      reswitch:
        switch (ch = *(unsigned char *) fmt++)
f0100f16:	89 de                	mov    %ebx,%esi
            }
            goto process_precision;

        case '*':
            precision = va_arg (ap, int);
            goto process_precision;
f0100f18:	eb 22                	jmp    f0100f3c <vprintfmt+0xde>
f0100f1a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f1d:	85 c9                	test   %ecx,%ecx
f0100f1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f24:	0f 49 c1             	cmovns %ecx,%eax
f0100f27:	89 45 dc             	mov    %eax,-0x24(%ebp)
        width = -1;
        precision = -1;
        lflag = 0;
        altflag = 0;
      reswitch:
        switch (ch = *(unsigned char *) fmt++)
f0100f2a:	89 de                	mov    %ebx,%esi
f0100f2c:	eb 9d                	jmp    f0100ecb <vprintfmt+0x6d>
f0100f2e:	89 de                	mov    %ebx,%esi
            if (width < 0)
                width = 0;
            goto reswitch;

        case '#':
            altflag = 1;
f0100f30:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
            goto reswitch;
f0100f37:	eb 92                	jmp    f0100ecb <vprintfmt+0x6d>
f0100f39:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

          process_precision:
            if (width < 0)
f0100f3c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f40:	79 89                	jns    f0100ecb <vprintfmt+0x6d>
f0100f42:	e9 77 ff ff ff       	jmp    f0100ebe <vprintfmt+0x60>
                width = precision, precision = -1;
            goto reswitch;

            // long flag (doubled for long long)
        case 'l':
            lflag++;
f0100f47:	83 c2 01             	add    $0x1,%edx
        width = -1;
        precision = -1;
        lflag = 0;
        altflag = 0;
      reswitch:
        switch (ch = *(unsigned char *) fmt++)
f0100f4a:	89 de                	mov    %ebx,%esi
            goto reswitch;

            // long flag (doubled for long long)
        case 'l':
            lflag++;
            goto reswitch;
f0100f4c:	e9 7a ff ff ff       	jmp    f0100ecb <vprintfmt+0x6d>

            // character
        case 'c':
            putch (va_arg (ap, int), putdat);
f0100f51:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f54:	8d 50 04             	lea    0x4(%eax),%edx
f0100f57:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f5e:	8b 00                	mov    (%eax),%eax
f0100f60:	89 04 24             	mov    %eax,(%esp)
f0100f63:	ff 55 08             	call   *0x8(%ebp)
            break;
f0100f66:	e9 18 ff ff ff       	jmp    f0100e83 <vprintfmt+0x25>

            // error message
        case 'e':
            err = va_arg (ap, int);
f0100f6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f71:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f74:	8b 00                	mov    (%eax),%eax
f0100f76:	99                   	cltd   
f0100f77:	31 d0                	xor    %edx,%eax
f0100f79:	29 d0                	sub    %edx,%eax
            if (err < 0)
                err = -err;
            if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f7b:	83 f8 07             	cmp    $0x7,%eax
f0100f7e:	7f 0b                	jg     f0100f8b <vprintfmt+0x12d>
f0100f80:	8b 14 85 40 21 10 f0 	mov    -0xfefdec0(,%eax,4),%edx
f0100f87:	85 d2                	test   %edx,%edx
f0100f89:	75 20                	jne    f0100fab <vprintfmt+0x14d>
                printfmt (putch, putdat, "error %d", err);
f0100f8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f8f:	c7 44 24 08 61 1f 10 	movl   $0xf0101f61,0x8(%esp)
f0100f96:	f0 
f0100f97:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f9e:	89 04 24             	mov    %eax,(%esp)
f0100fa1:	e8 90 fe ff ff       	call   f0100e36 <printfmt>
f0100fa6:	e9 d8 fe ff ff       	jmp    f0100e83 <vprintfmt+0x25>
            else
                printfmt (putch, putdat, "%s", p);
f0100fab:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100faf:	c7 44 24 08 6a 1f 10 	movl   $0xf0101f6a,0x8(%esp)
f0100fb6:	f0 
f0100fb7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fbe:	89 04 24             	mov    %eax,(%esp)
f0100fc1:	e8 70 fe ff ff       	call   f0100e36 <printfmt>
f0100fc6:	e9 b8 fe ff ff       	jmp    f0100e83 <vprintfmt+0x25>
        width = -1;
        precision = -1;
        lflag = 0;
        altflag = 0;
      reswitch:
        switch (ch = *(unsigned char *) fmt++)
f0100fcb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fce:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fd1:	89 45 d0             	mov    %eax,-0x30(%ebp)
                printfmt (putch, putdat, "%s", p);
            break;

            // string
        case 's':
            if ((p = va_arg (ap, char *)) == NULL)
f0100fd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd7:	8d 50 04             	lea    0x4(%eax),%edx
f0100fda:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fdd:	8b 30                	mov    (%eax),%esi
                p = "(null)";
f0100fdf:	85 f6                	test   %esi,%esi
f0100fe1:	b8 5a 1f 10 f0       	mov    $0xf0101f5a,%eax
f0100fe6:	0f 44 f0             	cmove  %eax,%esi
            if (width > 0 && padc != '-')
f0100fe9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100fed:	0f 84 97 00 00 00    	je     f010108a <vprintfmt+0x22c>
f0100ff3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100ff7:	0f 8e 9b 00 00 00    	jle    f0101098 <vprintfmt+0x23a>
                for (width -= strnlen (p, precision); width > 0; width--)
f0100ffd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101001:	89 34 24             	mov    %esi,(%esp)
f0101004:	e8 9f 03 00 00       	call   f01013a8 <strnlen>
f0101009:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010100c:	29 c2                	sub    %eax,%edx
f010100e:	89 55 d0             	mov    %edx,-0x30(%ebp)
                    putch (padc, putdat);
f0101011:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101015:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101018:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010101b:	8b 75 08             	mov    0x8(%ebp),%esi
f010101e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101021:	89 d3                	mov    %edx,%ebx
            // string
        case 's':
            if ((p = va_arg (ap, char *)) == NULL)
                p = "(null)";
            if (width > 0 && padc != '-')
                for (width -= strnlen (p, precision); width > 0; width--)
f0101023:	eb 0f                	jmp    f0101034 <vprintfmt+0x1d6>
                    putch (padc, putdat);
f0101025:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101029:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010102c:	89 04 24             	mov    %eax,(%esp)
f010102f:	ff d6                	call   *%esi
            // string
        case 's':
            if ((p = va_arg (ap, char *)) == NULL)
                p = "(null)";
            if (width > 0 && padc != '-')
                for (width -= strnlen (p, precision); width > 0; width--)
f0101031:	83 eb 01             	sub    $0x1,%ebx
f0101034:	85 db                	test   %ebx,%ebx
f0101036:	7f ed                	jg     f0101025 <vprintfmt+0x1c7>
f0101038:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010103b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010103e:	85 d2                	test   %edx,%edx
f0101040:	b8 00 00 00 00       	mov    $0x0,%eax
f0101045:	0f 49 c2             	cmovns %edx,%eax
f0101048:	29 c2                	sub    %eax,%edx
f010104a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010104d:	89 d7                	mov    %edx,%edi
f010104f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101052:	eb 50                	jmp    f01010a4 <vprintfmt+0x246>
                    putch (padc, putdat);
            for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0);
                 width--)
                if (altflag && (ch < ' ' || ch > '~'))
f0101054:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101058:	74 1e                	je     f0101078 <vprintfmt+0x21a>
f010105a:	0f be d2             	movsbl %dl,%edx
f010105d:	83 ea 20             	sub    $0x20,%edx
f0101060:	83 fa 5e             	cmp    $0x5e,%edx
f0101063:	76 13                	jbe    f0101078 <vprintfmt+0x21a>
                    putch ('?', putdat);
f0101065:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101068:	89 44 24 04          	mov    %eax,0x4(%esp)
f010106c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101073:	ff 55 08             	call   *0x8(%ebp)
f0101076:	eb 0d                	jmp    f0101085 <vprintfmt+0x227>
                else
                    putch (ch, putdat);
f0101078:	8b 55 0c             	mov    0xc(%ebp),%edx
f010107b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010107f:	89 04 24             	mov    %eax,(%esp)
f0101082:	ff 55 08             	call   *0x8(%ebp)
                p = "(null)";
            if (width > 0 && padc != '-')
                for (width -= strnlen (p, precision); width > 0; width--)
                    putch (padc, putdat);
            for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0);
                 width--)
f0101085:	83 ef 01             	sub    $0x1,%edi
f0101088:	eb 1a                	jmp    f01010a4 <vprintfmt+0x246>
f010108a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010108d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101090:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101093:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101096:	eb 0c                	jmp    f01010a4 <vprintfmt+0x246>
f0101098:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010109b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010109e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
            if ((p = va_arg (ap, char *)) == NULL)
                p = "(null)";
            if (width > 0 && padc != '-')
                for (width -= strnlen (p, precision); width > 0; width--)
                    putch (padc, putdat);
            for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0);
f01010a4:	83 c6 01             	add    $0x1,%esi
f01010a7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010ab:	0f be c2             	movsbl %dl,%eax
f01010ae:	85 c0                	test   %eax,%eax
f01010b0:	74 27                	je     f01010d9 <vprintfmt+0x27b>
f01010b2:	85 db                	test   %ebx,%ebx
f01010b4:	78 9e                	js     f0101054 <vprintfmt+0x1f6>
f01010b6:	83 eb 01             	sub    $0x1,%ebx
f01010b9:	79 99                	jns    f0101054 <vprintfmt+0x1f6>
f01010bb:	89 f8                	mov    %edi,%eax
f01010bd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010c0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010c3:	89 c3                	mov    %eax,%ebx
f01010c5:	eb 1a                	jmp    f01010e1 <vprintfmt+0x283>
                if (altflag && (ch < ' ' || ch > '~'))
                    putch ('?', putdat);
                else
                    putch (ch, putdat);
            for (; width > 0; width--)
                putch (' ', putdat);
f01010c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010cb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010d2:	ff d6                	call   *%esi
                 width--)
                if (altflag && (ch < ' ' || ch > '~'))
                    putch ('?', putdat);
                else
                    putch (ch, putdat);
            for (; width > 0; width--)
f01010d4:	83 eb 01             	sub    $0x1,%ebx
f01010d7:	eb 08                	jmp    f01010e1 <vprintfmt+0x283>
f01010d9:	89 fb                	mov    %edi,%ebx
f01010db:	8b 75 08             	mov    0x8(%ebp),%esi
f01010de:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010e1:	85 db                	test   %ebx,%ebx
f01010e3:	7f e2                	jg     f01010c7 <vprintfmt+0x269>
f01010e5:	89 75 08             	mov    %esi,0x8(%ebp)
f01010e8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010eb:	e9 93 fd ff ff       	jmp    f0100e83 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint (va_list * ap, int lflag)
{
    if (lflag >= 2)
f01010f0:	83 fa 01             	cmp    $0x1,%edx
f01010f3:	7e 16                	jle    f010110b <vprintfmt+0x2ad>
        return va_arg (*ap, long long);
f01010f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f8:	8d 50 08             	lea    0x8(%eax),%edx
f01010fb:	89 55 14             	mov    %edx,0x14(%ebp)
f01010fe:	8b 50 04             	mov    0x4(%eax),%edx
f0101101:	8b 00                	mov    (%eax),%eax
f0101103:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101106:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101109:	eb 32                	jmp    f010113d <vprintfmt+0x2df>
    else if (lflag)
f010110b:	85 d2                	test   %edx,%edx
f010110d:	74 18                	je     f0101127 <vprintfmt+0x2c9>
        return va_arg (*ap, long);
f010110f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101112:	8d 50 04             	lea    0x4(%eax),%edx
f0101115:	89 55 14             	mov    %edx,0x14(%ebp)
f0101118:	8b 30                	mov    (%eax),%esi
f010111a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010111d:	89 f0                	mov    %esi,%eax
f010111f:	c1 f8 1f             	sar    $0x1f,%eax
f0101122:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101125:	eb 16                	jmp    f010113d <vprintfmt+0x2df>
    else
        return va_arg (*ap, int);
f0101127:	8b 45 14             	mov    0x14(%ebp),%eax
f010112a:	8d 50 04             	lea    0x4(%eax),%edx
f010112d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101130:	8b 30                	mov    (%eax),%esi
f0101132:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101135:	89 f0                	mov    %esi,%eax
f0101137:	c1 f8 1f             	sar    $0x1f,%eax
f010113a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                putch (' ', putdat);
            break;

            // (signed) decimal
        case 'd':
            num = getint (&ap, lflag);
f010113d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101140:	8b 55 e4             	mov    -0x1c(%ebp),%edx
            if ((long long) num < 0)
            {
                putch ('-', putdat);
                num = -(long long) num;
            }
            base = 10;
f0101143:	b9 0a 00 00 00       	mov    $0xa,%ecx
            break;

            // (signed) decimal
        case 'd':
            num = getint (&ap, lflag);
            if ((long long) num < 0)
f0101148:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010114c:	0f 89 80 00 00 00    	jns    f01011d2 <vprintfmt+0x374>
            {
                putch ('-', putdat);
f0101152:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101156:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010115d:	ff 55 08             	call   *0x8(%ebp)
                num = -(long long) num;
f0101160:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101163:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101166:	f7 d8                	neg    %eax
f0101168:	83 d2 00             	adc    $0x0,%edx
f010116b:	f7 da                	neg    %edx
            }
            base = 10;
f010116d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101172:	eb 5e                	jmp    f01011d2 <vprintfmt+0x374>
            goto number;

            // unsigned decimal
        case 'u':
            num = getuint (&ap, lflag);
f0101174:	8d 45 14             	lea    0x14(%ebp),%eax
f0101177:	e8 63 fc ff ff       	call   f0100ddf <getuint>
            base = 10;
f010117c:	b9 0a 00 00 00       	mov    $0xa,%ecx
            goto number;
f0101181:	eb 4f                	jmp    f01011d2 <vprintfmt+0x374>

            // (unsigned) octal
        case 'o':
            // Replace this with your code.
            num = getuint (&ap, lflag);
f0101183:	8d 45 14             	lea    0x14(%ebp),%eax
f0101186:	e8 54 fc ff ff       	call   f0100ddf <getuint>
            base = 8;
f010118b:	b9 08 00 00 00       	mov    $0x8,%ecx
            goto number;
f0101190:	eb 40                	jmp    f01011d2 <vprintfmt+0x374>


            // pointer
        case 'p':
            putch ('0', putdat);
f0101192:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101196:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010119d:	ff 55 08             	call   *0x8(%ebp)
            putch ('x', putdat);
f01011a0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011ab:	ff 55 08             	call   *0x8(%ebp)
            num = (unsigned long long) (uintptr_t) va_arg (ap, void *);
f01011ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b1:	8d 50 04             	lea    0x4(%eax),%edx
f01011b4:	89 55 14             	mov    %edx,0x14(%ebp)
f01011b7:	8b 00                	mov    (%eax),%eax
f01011b9:	ba 00 00 00 00       	mov    $0x0,%edx
            base = 16;
f01011be:	b9 10 00 00 00       	mov    $0x10,%ecx
            goto number;
f01011c3:	eb 0d                	jmp    f01011d2 <vprintfmt+0x374>

            // (unsigned) hexadecimal
        case 'x':
            num = getuint (&ap, lflag);
f01011c5:	8d 45 14             	lea    0x14(%ebp),%eax
f01011c8:	e8 12 fc ff ff       	call   f0100ddf <getuint>
            base = 16;
f01011cd:	b9 10 00 00 00       	mov    $0x10,%ecx
          number:
            printnum (putch, putdat, num, base, width, padc);
f01011d2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01011d6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011da:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01011dd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01011e1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01011e5:	89 04 24             	mov    %eax,(%esp)
f01011e8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011ec:	89 fa                	mov    %edi,%edx
f01011ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01011f1:	e8 fa fa ff ff       	call   f0100cf0 <printnum>
            break;
f01011f6:	e9 88 fc ff ff       	jmp    f0100e83 <vprintfmt+0x25>

            // escaped '%' character
        case '%':
            putch (ch, putdat);
f01011fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011ff:	89 04 24             	mov    %eax,(%esp)
f0101202:	ff 55 08             	call   *0x8(%ebp)
            break;
f0101205:	e9 79 fc ff ff       	jmp    f0100e83 <vprintfmt+0x25>

            // unrecognized escape sequence - just print it literally
        default:
            putch ('%', putdat);
f010120a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010120e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101215:	ff 55 08             	call   *0x8(%ebp)
            for (fmt--; fmt[-1] != '%'; fmt--)
f0101218:	89 f3                	mov    %esi,%ebx
f010121a:	eb 03                	jmp    f010121f <vprintfmt+0x3c1>
f010121c:	83 eb 01             	sub    $0x1,%ebx
f010121f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101223:	75 f7                	jne    f010121c <vprintfmt+0x3be>
f0101225:	e9 59 fc ff ff       	jmp    f0100e83 <vprintfmt+0x25>
                /* do nothing */ ;
            break;
        }
    }
}
f010122a:	83 c4 3c             	add    $0x3c,%esp
f010122d:	5b                   	pop    %ebx
f010122e:	5e                   	pop    %esi
f010122f:	5f                   	pop    %edi
f0101230:	5d                   	pop    %ebp
f0101231:	c3                   	ret    

f0101232 <vsnprintf>:
        *b->buf++ = ch;
}

int
vsnprintf (char *buf, int n, const char *fmt, va_list ap)
{
f0101232:	55                   	push   %ebp
f0101233:	89 e5                	mov    %esp,%ebp
f0101235:	83 ec 28             	sub    $0x28,%esp
f0101238:	8b 45 08             	mov    0x8(%ebp),%eax
f010123b:	8b 55 0c             	mov    0xc(%ebp),%edx
    struct sprintbuf b = { buf, buf + n - 1, 0 };
f010123e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101241:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101245:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101248:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    if (buf == NULL || n < 1)
f010124f:	85 c0                	test   %eax,%eax
f0101251:	74 30                	je     f0101283 <vsnprintf+0x51>
f0101253:	85 d2                	test   %edx,%edx
f0101255:	7e 2c                	jle    f0101283 <vsnprintf+0x51>
        return -E_INVAL;

    // print the string to the buffer
    vprintfmt ((void *) sprintputch, &b, fmt, ap);
f0101257:	8b 45 14             	mov    0x14(%ebp),%eax
f010125a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010125e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101261:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101265:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101268:	89 44 24 04          	mov    %eax,0x4(%esp)
f010126c:	c7 04 24 19 0e 10 f0 	movl   $0xf0100e19,(%esp)
f0101273:	e8 e6 fb ff ff       	call   f0100e5e <vprintfmt>

    // null terminate the buffer
    *b.buf = '\0';
f0101278:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010127b:	c6 00 00             	movb   $0x0,(%eax)

    return b.cnt;
f010127e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101281:	eb 05                	jmp    f0101288 <vsnprintf+0x56>
vsnprintf (char *buf, int n, const char *fmt, va_list ap)
{
    struct sprintbuf b = { buf, buf + n - 1, 0 };

    if (buf == NULL || n < 1)
        return -E_INVAL;
f0101283:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

    // null terminate the buffer
    *b.buf = '\0';

    return b.cnt;
}
f0101288:	c9                   	leave  
f0101289:	c3                   	ret    

f010128a <snprintf>:

int
snprintf (char *buf, int n, const char *fmt, ...)
{
f010128a:	55                   	push   %ebp
f010128b:	89 e5                	mov    %esp,%ebp
f010128d:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    int rc;

    va_start (ap, fmt);
f0101290:	8d 45 14             	lea    0x14(%ebp),%eax
    rc = vsnprintf (buf, n, fmt, ap);
f0101293:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101297:	8b 45 10             	mov    0x10(%ebp),%eax
f010129a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010129e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01012a8:	89 04 24             	mov    %eax,(%esp)
f01012ab:	e8 82 ff ff ff       	call   f0101232 <vsnprintf>
    va_end (ap);

    return rc;
f01012b0:	c9                   	leave  
f01012b1:	c3                   	ret    
f01012b2:	66 90                	xchg   %ax,%ax
f01012b4:	66 90                	xchg   %ax,%ax
f01012b6:	66 90                	xchg   %ax,%ax
f01012b8:	66 90                	xchg   %ax,%ax
f01012ba:	66 90                	xchg   %ax,%ax
f01012bc:	66 90                	xchg   %ax,%ax
f01012be:	66 90                	xchg   %ax,%ax

f01012c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012c0:	55                   	push   %ebp
f01012c1:	89 e5                	mov    %esp,%ebp
f01012c3:	57                   	push   %edi
f01012c4:	56                   	push   %esi
f01012c5:	53                   	push   %ebx
f01012c6:	83 ec 1c             	sub    $0x1c,%esp
f01012c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012cc:	85 c0                	test   %eax,%eax
f01012ce:	74 10                	je     f01012e0 <readline+0x20>
		cprintf("%s", prompt);
f01012d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d4:	c7 04 24 6a 1f 10 f0 	movl   $0xf0101f6a,(%esp)
f01012db:	e8 e9 f6 ff ff       	call   f01009c9 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012e7:	e8 8a f3 ff ff       	call   f0100676 <iscons>
f01012ec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012ee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012f3:	e8 6d f3 ff ff       	call   f0100665 <getchar>
f01012f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012fa:	85 c0                	test   %eax,%eax
f01012fc:	79 17                	jns    f0101315 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101302:	c7 04 24 60 21 10 f0 	movl   $0xf0102160,(%esp)
f0101309:	e8 bb f6 ff ff       	call   f01009c9 <cprintf>
			return NULL;
f010130e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101313:	eb 6d                	jmp    f0101382 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101315:	83 f8 7f             	cmp    $0x7f,%eax
f0101318:	74 05                	je     f010131f <readline+0x5f>
f010131a:	83 f8 08             	cmp    $0x8,%eax
f010131d:	75 19                	jne    f0101338 <readline+0x78>
f010131f:	85 f6                	test   %esi,%esi
f0101321:	7e 15                	jle    f0101338 <readline+0x78>
			if (echoing)
f0101323:	85 ff                	test   %edi,%edi
f0101325:	74 0c                	je     f0101333 <readline+0x73>
				cputchar('\b');
f0101327:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010132e:	e8 22 f3 ff ff       	call   f0100655 <cputchar>
			i--;
f0101333:	83 ee 01             	sub    $0x1,%esi
f0101336:	eb bb                	jmp    f01012f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101338:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010133e:	7f 1c                	jg     f010135c <readline+0x9c>
f0101340:	83 fb 1f             	cmp    $0x1f,%ebx
f0101343:	7e 17                	jle    f010135c <readline+0x9c>
			if (echoing)
f0101345:	85 ff                	test   %edi,%edi
f0101347:	74 08                	je     f0101351 <readline+0x91>
				cputchar(c);
f0101349:	89 1c 24             	mov    %ebx,(%esp)
f010134c:	e8 04 f3 ff ff       	call   f0100655 <cputchar>
			buf[i++] = c;
f0101351:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101357:	8d 76 01             	lea    0x1(%esi),%esi
f010135a:	eb 97                	jmp    f01012f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010135c:	83 fb 0d             	cmp    $0xd,%ebx
f010135f:	74 05                	je     f0101366 <readline+0xa6>
f0101361:	83 fb 0a             	cmp    $0xa,%ebx
f0101364:	75 8d                	jne    f01012f3 <readline+0x33>
			if (echoing)
f0101366:	85 ff                	test   %edi,%edi
f0101368:	74 0c                	je     f0101376 <readline+0xb6>
				cputchar('\n');
f010136a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101371:	e8 df f2 ff ff       	call   f0100655 <cputchar>
			buf[i] = 0;
f0101376:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010137d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101382:	83 c4 1c             	add    $0x1c,%esp
f0101385:	5b                   	pop    %ebx
f0101386:	5e                   	pop    %esi
f0101387:	5f                   	pop    %edi
f0101388:	5d                   	pop    %ebp
f0101389:	c3                   	ret    
f010138a:	66 90                	xchg   %ax,%ax
f010138c:	66 90                	xchg   %ax,%ax
f010138e:	66 90                	xchg   %ax,%ax

f0101390 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101390:	55                   	push   %ebp
f0101391:	89 e5                	mov    %esp,%ebp
f0101393:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101396:	b8 00 00 00 00       	mov    $0x0,%eax
f010139b:	eb 03                	jmp    f01013a0 <strlen+0x10>
		n++;
f010139d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013a4:	75 f7                	jne    f010139d <strlen+0xd>
		n++;
	return n;
}
f01013a6:	5d                   	pop    %ebp
f01013a7:	c3                   	ret    

f01013a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013a8:	55                   	push   %ebp
f01013a9:	89 e5                	mov    %esp,%ebp
f01013ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b6:	eb 03                	jmp    f01013bb <strnlen+0x13>
		n++;
f01013b8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013bb:	39 d0                	cmp    %edx,%eax
f01013bd:	74 06                	je     f01013c5 <strnlen+0x1d>
f01013bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013c3:	75 f3                	jne    f01013b8 <strnlen+0x10>
		n++;
	return n;
}
f01013c5:	5d                   	pop    %ebp
f01013c6:	c3                   	ret    

f01013c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013c7:	55                   	push   %ebp
f01013c8:	89 e5                	mov    %esp,%ebp
f01013ca:	53                   	push   %ebx
f01013cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013d1:	89 c2                	mov    %eax,%edx
f01013d3:	83 c2 01             	add    $0x1,%edx
f01013d6:	83 c1 01             	add    $0x1,%ecx
f01013d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013dd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013e0:	84 db                	test   %bl,%bl
f01013e2:	75 ef                	jne    f01013d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013e4:	5b                   	pop    %ebx
f01013e5:	5d                   	pop    %ebp
f01013e6:	c3                   	ret    

f01013e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013e7:	55                   	push   %ebp
f01013e8:	89 e5                	mov    %esp,%ebp
f01013ea:	53                   	push   %ebx
f01013eb:	83 ec 08             	sub    $0x8,%esp
f01013ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01013f1:	89 1c 24             	mov    %ebx,(%esp)
f01013f4:	e8 97 ff ff ff       	call   f0101390 <strlen>
	strcpy(dst + len, src);
f01013f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101400:	01 d8                	add    %ebx,%eax
f0101402:	89 04 24             	mov    %eax,(%esp)
f0101405:	e8 bd ff ff ff       	call   f01013c7 <strcpy>
	return dst;
}
f010140a:	89 d8                	mov    %ebx,%eax
f010140c:	83 c4 08             	add    $0x8,%esp
f010140f:	5b                   	pop    %ebx
f0101410:	5d                   	pop    %ebp
f0101411:	c3                   	ret    

f0101412 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101412:	55                   	push   %ebp
f0101413:	89 e5                	mov    %esp,%ebp
f0101415:	56                   	push   %esi
f0101416:	53                   	push   %ebx
f0101417:	8b 75 08             	mov    0x8(%ebp),%esi
f010141a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010141d:	89 f3                	mov    %esi,%ebx
f010141f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101422:	89 f2                	mov    %esi,%edx
f0101424:	eb 0f                	jmp    f0101435 <strncpy+0x23>
		*dst++ = *src;
f0101426:	83 c2 01             	add    $0x1,%edx
f0101429:	0f b6 01             	movzbl (%ecx),%eax
f010142c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010142f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101432:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101435:	39 da                	cmp    %ebx,%edx
f0101437:	75 ed                	jne    f0101426 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101439:	89 f0                	mov    %esi,%eax
f010143b:	5b                   	pop    %ebx
f010143c:	5e                   	pop    %esi
f010143d:	5d                   	pop    %ebp
f010143e:	c3                   	ret    

f010143f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010143f:	55                   	push   %ebp
f0101440:	89 e5                	mov    %esp,%ebp
f0101442:	56                   	push   %esi
f0101443:	53                   	push   %ebx
f0101444:	8b 75 08             	mov    0x8(%ebp),%esi
f0101447:	8b 55 0c             	mov    0xc(%ebp),%edx
f010144a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010144d:	89 f0                	mov    %esi,%eax
f010144f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101453:	85 c9                	test   %ecx,%ecx
f0101455:	75 0b                	jne    f0101462 <strlcpy+0x23>
f0101457:	eb 1d                	jmp    f0101476 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101459:	83 c0 01             	add    $0x1,%eax
f010145c:	83 c2 01             	add    $0x1,%edx
f010145f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101462:	39 d8                	cmp    %ebx,%eax
f0101464:	74 0b                	je     f0101471 <strlcpy+0x32>
f0101466:	0f b6 0a             	movzbl (%edx),%ecx
f0101469:	84 c9                	test   %cl,%cl
f010146b:	75 ec                	jne    f0101459 <strlcpy+0x1a>
f010146d:	89 c2                	mov    %eax,%edx
f010146f:	eb 02                	jmp    f0101473 <strlcpy+0x34>
f0101471:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101473:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101476:	29 f0                	sub    %esi,%eax
}
f0101478:	5b                   	pop    %ebx
f0101479:	5e                   	pop    %esi
f010147a:	5d                   	pop    %ebp
f010147b:	c3                   	ret    

f010147c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010147c:	55                   	push   %ebp
f010147d:	89 e5                	mov    %esp,%ebp
f010147f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101482:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101485:	eb 06                	jmp    f010148d <strcmp+0x11>
		p++, q++;
f0101487:	83 c1 01             	add    $0x1,%ecx
f010148a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010148d:	0f b6 01             	movzbl (%ecx),%eax
f0101490:	84 c0                	test   %al,%al
f0101492:	74 04                	je     f0101498 <strcmp+0x1c>
f0101494:	3a 02                	cmp    (%edx),%al
f0101496:	74 ef                	je     f0101487 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101498:	0f b6 c0             	movzbl %al,%eax
f010149b:	0f b6 12             	movzbl (%edx),%edx
f010149e:	29 d0                	sub    %edx,%eax
}
f01014a0:	5d                   	pop    %ebp
f01014a1:	c3                   	ret    

f01014a2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014a2:	55                   	push   %ebp
f01014a3:	89 e5                	mov    %esp,%ebp
f01014a5:	53                   	push   %ebx
f01014a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ac:	89 c3                	mov    %eax,%ebx
f01014ae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014b1:	eb 06                	jmp    f01014b9 <strncmp+0x17>
		n--, p++, q++;
f01014b3:	83 c0 01             	add    $0x1,%eax
f01014b6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014b9:	39 d8                	cmp    %ebx,%eax
f01014bb:	74 15                	je     f01014d2 <strncmp+0x30>
f01014bd:	0f b6 08             	movzbl (%eax),%ecx
f01014c0:	84 c9                	test   %cl,%cl
f01014c2:	74 04                	je     f01014c8 <strncmp+0x26>
f01014c4:	3a 0a                	cmp    (%edx),%cl
f01014c6:	74 eb                	je     f01014b3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014c8:	0f b6 00             	movzbl (%eax),%eax
f01014cb:	0f b6 12             	movzbl (%edx),%edx
f01014ce:	29 d0                	sub    %edx,%eax
f01014d0:	eb 05                	jmp    f01014d7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014d2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014d7:	5b                   	pop    %ebx
f01014d8:	5d                   	pop    %ebp
f01014d9:	c3                   	ret    

f01014da <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014da:	55                   	push   %ebp
f01014db:	89 e5                	mov    %esp,%ebp
f01014dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014e4:	eb 07                	jmp    f01014ed <strchr+0x13>
		if (*s == c)
f01014e6:	38 ca                	cmp    %cl,%dl
f01014e8:	74 0f                	je     f01014f9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014ea:	83 c0 01             	add    $0x1,%eax
f01014ed:	0f b6 10             	movzbl (%eax),%edx
f01014f0:	84 d2                	test   %dl,%dl
f01014f2:	75 f2                	jne    f01014e6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01014f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014f9:	5d                   	pop    %ebp
f01014fa:	c3                   	ret    

f01014fb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014fb:	55                   	push   %ebp
f01014fc:	89 e5                	mov    %esp,%ebp
f01014fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101501:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101505:	eb 07                	jmp    f010150e <strfind+0x13>
		if (*s == c)
f0101507:	38 ca                	cmp    %cl,%dl
f0101509:	74 0a                	je     f0101515 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010150b:	83 c0 01             	add    $0x1,%eax
f010150e:	0f b6 10             	movzbl (%eax),%edx
f0101511:	84 d2                	test   %dl,%dl
f0101513:	75 f2                	jne    f0101507 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101515:	5d                   	pop    %ebp
f0101516:	c3                   	ret    

f0101517 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101517:	55                   	push   %ebp
f0101518:	89 e5                	mov    %esp,%ebp
f010151a:	57                   	push   %edi
f010151b:	56                   	push   %esi
f010151c:	53                   	push   %ebx
f010151d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101520:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101523:	85 c9                	test   %ecx,%ecx
f0101525:	74 36                	je     f010155d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101527:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010152d:	75 28                	jne    f0101557 <memset+0x40>
f010152f:	f6 c1 03             	test   $0x3,%cl
f0101532:	75 23                	jne    f0101557 <memset+0x40>
		c &= 0xFF;
f0101534:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101538:	89 d3                	mov    %edx,%ebx
f010153a:	c1 e3 08             	shl    $0x8,%ebx
f010153d:	89 d6                	mov    %edx,%esi
f010153f:	c1 e6 18             	shl    $0x18,%esi
f0101542:	89 d0                	mov    %edx,%eax
f0101544:	c1 e0 10             	shl    $0x10,%eax
f0101547:	09 f0                	or     %esi,%eax
f0101549:	09 c2                	or     %eax,%edx
f010154b:	89 d0                	mov    %edx,%eax
f010154d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010154f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101552:	fc                   	cld    
f0101553:	f3 ab                	rep stos %eax,%es:(%edi)
f0101555:	eb 06                	jmp    f010155d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101557:	8b 45 0c             	mov    0xc(%ebp),%eax
f010155a:	fc                   	cld    
f010155b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010155d:	89 f8                	mov    %edi,%eax
f010155f:	5b                   	pop    %ebx
f0101560:	5e                   	pop    %esi
f0101561:	5f                   	pop    %edi
f0101562:	5d                   	pop    %ebp
f0101563:	c3                   	ret    

f0101564 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101564:	55                   	push   %ebp
f0101565:	89 e5                	mov    %esp,%ebp
f0101567:	57                   	push   %edi
f0101568:	56                   	push   %esi
f0101569:	8b 45 08             	mov    0x8(%ebp),%eax
f010156c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010156f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101572:	39 c6                	cmp    %eax,%esi
f0101574:	73 35                	jae    f01015ab <memmove+0x47>
f0101576:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101579:	39 d0                	cmp    %edx,%eax
f010157b:	73 2e                	jae    f01015ab <memmove+0x47>
		s += n;
		d += n;
f010157d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101580:	89 d6                	mov    %edx,%esi
f0101582:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101584:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010158a:	75 13                	jne    f010159f <memmove+0x3b>
f010158c:	f6 c1 03             	test   $0x3,%cl
f010158f:	75 0e                	jne    f010159f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101591:	83 ef 04             	sub    $0x4,%edi
f0101594:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101597:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010159a:	fd                   	std    
f010159b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010159d:	eb 09                	jmp    f01015a8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010159f:	83 ef 01             	sub    $0x1,%edi
f01015a2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015a5:	fd                   	std    
f01015a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015a8:	fc                   	cld    
f01015a9:	eb 1d                	jmp    f01015c8 <memmove+0x64>
f01015ab:	89 f2                	mov    %esi,%edx
f01015ad:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015af:	f6 c2 03             	test   $0x3,%dl
f01015b2:	75 0f                	jne    f01015c3 <memmove+0x5f>
f01015b4:	f6 c1 03             	test   $0x3,%cl
f01015b7:	75 0a                	jne    f01015c3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015b9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015bc:	89 c7                	mov    %eax,%edi
f01015be:	fc                   	cld    
f01015bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015c1:	eb 05                	jmp    f01015c8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015c3:	89 c7                	mov    %eax,%edi
f01015c5:	fc                   	cld    
f01015c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015c8:	5e                   	pop    %esi
f01015c9:	5f                   	pop    %edi
f01015ca:	5d                   	pop    %ebp
f01015cb:	c3                   	ret    

f01015cc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015cc:	55                   	push   %ebp
f01015cd:	89 e5                	mov    %esp,%ebp
f01015cf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01015d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e3:	89 04 24             	mov    %eax,(%esp)
f01015e6:	e8 79 ff ff ff       	call   f0101564 <memmove>
}
f01015eb:	c9                   	leave  
f01015ec:	c3                   	ret    

f01015ed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015ed:	55                   	push   %ebp
f01015ee:	89 e5                	mov    %esp,%ebp
f01015f0:	56                   	push   %esi
f01015f1:	53                   	push   %ebx
f01015f2:	8b 55 08             	mov    0x8(%ebp),%edx
f01015f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015f8:	89 d6                	mov    %edx,%esi
f01015fa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015fd:	eb 1a                	jmp    f0101619 <memcmp+0x2c>
		if (*s1 != *s2)
f01015ff:	0f b6 02             	movzbl (%edx),%eax
f0101602:	0f b6 19             	movzbl (%ecx),%ebx
f0101605:	38 d8                	cmp    %bl,%al
f0101607:	74 0a                	je     f0101613 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101609:	0f b6 c0             	movzbl %al,%eax
f010160c:	0f b6 db             	movzbl %bl,%ebx
f010160f:	29 d8                	sub    %ebx,%eax
f0101611:	eb 0f                	jmp    f0101622 <memcmp+0x35>
		s1++, s2++;
f0101613:	83 c2 01             	add    $0x1,%edx
f0101616:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101619:	39 f2                	cmp    %esi,%edx
f010161b:	75 e2                	jne    f01015ff <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010161d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101622:	5b                   	pop    %ebx
f0101623:	5e                   	pop    %esi
f0101624:	5d                   	pop    %ebp
f0101625:	c3                   	ret    

f0101626 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101626:	55                   	push   %ebp
f0101627:	89 e5                	mov    %esp,%ebp
f0101629:	8b 45 08             	mov    0x8(%ebp),%eax
f010162c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010162f:	89 c2                	mov    %eax,%edx
f0101631:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101634:	eb 07                	jmp    f010163d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101636:	38 08                	cmp    %cl,(%eax)
f0101638:	74 07                	je     f0101641 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010163a:	83 c0 01             	add    $0x1,%eax
f010163d:	39 d0                	cmp    %edx,%eax
f010163f:	72 f5                	jb     f0101636 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101641:	5d                   	pop    %ebp
f0101642:	c3                   	ret    

f0101643 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101643:	55                   	push   %ebp
f0101644:	89 e5                	mov    %esp,%ebp
f0101646:	57                   	push   %edi
f0101647:	56                   	push   %esi
f0101648:	53                   	push   %ebx
f0101649:	8b 55 08             	mov    0x8(%ebp),%edx
f010164c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010164f:	eb 03                	jmp    f0101654 <strtol+0x11>
		s++;
f0101651:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101654:	0f b6 0a             	movzbl (%edx),%ecx
f0101657:	80 f9 09             	cmp    $0x9,%cl
f010165a:	74 f5                	je     f0101651 <strtol+0xe>
f010165c:	80 f9 20             	cmp    $0x20,%cl
f010165f:	74 f0                	je     f0101651 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101661:	80 f9 2b             	cmp    $0x2b,%cl
f0101664:	75 0a                	jne    f0101670 <strtol+0x2d>
		s++;
f0101666:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101669:	bf 00 00 00 00       	mov    $0x0,%edi
f010166e:	eb 11                	jmp    f0101681 <strtol+0x3e>
f0101670:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101675:	80 f9 2d             	cmp    $0x2d,%cl
f0101678:	75 07                	jne    f0101681 <strtol+0x3e>
		s++, neg = 1;
f010167a:	8d 52 01             	lea    0x1(%edx),%edx
f010167d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101681:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101686:	75 15                	jne    f010169d <strtol+0x5a>
f0101688:	80 3a 30             	cmpb   $0x30,(%edx)
f010168b:	75 10                	jne    f010169d <strtol+0x5a>
f010168d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101691:	75 0a                	jne    f010169d <strtol+0x5a>
		s += 2, base = 16;
f0101693:	83 c2 02             	add    $0x2,%edx
f0101696:	b8 10 00 00 00       	mov    $0x10,%eax
f010169b:	eb 10                	jmp    f01016ad <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010169d:	85 c0                	test   %eax,%eax
f010169f:	75 0c                	jne    f01016ad <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016a1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016a3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016a6:	75 05                	jne    f01016ad <strtol+0x6a>
		s++, base = 8;
f01016a8:	83 c2 01             	add    $0x1,%edx
f01016ab:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01016ad:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016b2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016b5:	0f b6 0a             	movzbl (%edx),%ecx
f01016b8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016bb:	89 f0                	mov    %esi,%eax
f01016bd:	3c 09                	cmp    $0x9,%al
f01016bf:	77 08                	ja     f01016c9 <strtol+0x86>
			dig = *s - '0';
f01016c1:	0f be c9             	movsbl %cl,%ecx
f01016c4:	83 e9 30             	sub    $0x30,%ecx
f01016c7:	eb 20                	jmp    f01016e9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01016c9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01016cc:	89 f0                	mov    %esi,%eax
f01016ce:	3c 19                	cmp    $0x19,%al
f01016d0:	77 08                	ja     f01016da <strtol+0x97>
			dig = *s - 'a' + 10;
f01016d2:	0f be c9             	movsbl %cl,%ecx
f01016d5:	83 e9 57             	sub    $0x57,%ecx
f01016d8:	eb 0f                	jmp    f01016e9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01016da:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01016dd:	89 f0                	mov    %esi,%eax
f01016df:	3c 19                	cmp    $0x19,%al
f01016e1:	77 16                	ja     f01016f9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01016e3:	0f be c9             	movsbl %cl,%ecx
f01016e6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016e9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01016ec:	7d 0f                	jge    f01016fd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01016ee:	83 c2 01             	add    $0x1,%edx
f01016f1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01016f5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01016f7:	eb bc                	jmp    f01016b5 <strtol+0x72>
f01016f9:	89 d8                	mov    %ebx,%eax
f01016fb:	eb 02                	jmp    f01016ff <strtol+0xbc>
f01016fd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01016ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101703:	74 05                	je     f010170a <strtol+0xc7>
		*endptr = (char *) s;
f0101705:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101708:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010170a:	f7 d8                	neg    %eax
f010170c:	85 ff                	test   %edi,%edi
f010170e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101711:	5b                   	pop    %ebx
f0101712:	5e                   	pop    %esi
f0101713:	5f                   	pop    %edi
f0101714:	5d                   	pop    %ebp
f0101715:	c3                   	ret    
f0101716:	66 90                	xchg   %ax,%ax
f0101718:	66 90                	xchg   %ax,%ax
f010171a:	66 90                	xchg   %ax,%ax
f010171c:	66 90                	xchg   %ax,%ax
f010171e:	66 90                	xchg   %ax,%ax

f0101720 <__udivdi3>:
f0101720:	55                   	push   %ebp
f0101721:	57                   	push   %edi
f0101722:	56                   	push   %esi
f0101723:	83 ec 0c             	sub    $0xc,%esp
f0101726:	8b 44 24 28          	mov    0x28(%esp),%eax
f010172a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010172e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101732:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101736:	85 c0                	test   %eax,%eax
f0101738:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010173c:	89 ea                	mov    %ebp,%edx
f010173e:	89 0c 24             	mov    %ecx,(%esp)
f0101741:	75 2d                	jne    f0101770 <__udivdi3+0x50>
f0101743:	39 e9                	cmp    %ebp,%ecx
f0101745:	77 61                	ja     f01017a8 <__udivdi3+0x88>
f0101747:	85 c9                	test   %ecx,%ecx
f0101749:	89 ce                	mov    %ecx,%esi
f010174b:	75 0b                	jne    f0101758 <__udivdi3+0x38>
f010174d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101752:	31 d2                	xor    %edx,%edx
f0101754:	f7 f1                	div    %ecx
f0101756:	89 c6                	mov    %eax,%esi
f0101758:	31 d2                	xor    %edx,%edx
f010175a:	89 e8                	mov    %ebp,%eax
f010175c:	f7 f6                	div    %esi
f010175e:	89 c5                	mov    %eax,%ebp
f0101760:	89 f8                	mov    %edi,%eax
f0101762:	f7 f6                	div    %esi
f0101764:	89 ea                	mov    %ebp,%edx
f0101766:	83 c4 0c             	add    $0xc,%esp
f0101769:	5e                   	pop    %esi
f010176a:	5f                   	pop    %edi
f010176b:	5d                   	pop    %ebp
f010176c:	c3                   	ret    
f010176d:	8d 76 00             	lea    0x0(%esi),%esi
f0101770:	39 e8                	cmp    %ebp,%eax
f0101772:	77 24                	ja     f0101798 <__udivdi3+0x78>
f0101774:	0f bd e8             	bsr    %eax,%ebp
f0101777:	83 f5 1f             	xor    $0x1f,%ebp
f010177a:	75 3c                	jne    f01017b8 <__udivdi3+0x98>
f010177c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101780:	39 34 24             	cmp    %esi,(%esp)
f0101783:	0f 86 9f 00 00 00    	jbe    f0101828 <__udivdi3+0x108>
f0101789:	39 d0                	cmp    %edx,%eax
f010178b:	0f 82 97 00 00 00    	jb     f0101828 <__udivdi3+0x108>
f0101791:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101798:	31 d2                	xor    %edx,%edx
f010179a:	31 c0                	xor    %eax,%eax
f010179c:	83 c4 0c             	add    $0xc,%esp
f010179f:	5e                   	pop    %esi
f01017a0:	5f                   	pop    %edi
f01017a1:	5d                   	pop    %ebp
f01017a2:	c3                   	ret    
f01017a3:	90                   	nop
f01017a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	89 f8                	mov    %edi,%eax
f01017aa:	f7 f1                	div    %ecx
f01017ac:	31 d2                	xor    %edx,%edx
f01017ae:	83 c4 0c             	add    $0xc,%esp
f01017b1:	5e                   	pop    %esi
f01017b2:	5f                   	pop    %edi
f01017b3:	5d                   	pop    %ebp
f01017b4:	c3                   	ret    
f01017b5:	8d 76 00             	lea    0x0(%esi),%esi
f01017b8:	89 e9                	mov    %ebp,%ecx
f01017ba:	8b 3c 24             	mov    (%esp),%edi
f01017bd:	d3 e0                	shl    %cl,%eax
f01017bf:	89 c6                	mov    %eax,%esi
f01017c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01017c6:	29 e8                	sub    %ebp,%eax
f01017c8:	89 c1                	mov    %eax,%ecx
f01017ca:	d3 ef                	shr    %cl,%edi
f01017cc:	89 e9                	mov    %ebp,%ecx
f01017ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017d2:	8b 3c 24             	mov    (%esp),%edi
f01017d5:	09 74 24 08          	or     %esi,0x8(%esp)
f01017d9:	89 d6                	mov    %edx,%esi
f01017db:	d3 e7                	shl    %cl,%edi
f01017dd:	89 c1                	mov    %eax,%ecx
f01017df:	89 3c 24             	mov    %edi,(%esp)
f01017e2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017e6:	d3 ee                	shr    %cl,%esi
f01017e8:	89 e9                	mov    %ebp,%ecx
f01017ea:	d3 e2                	shl    %cl,%edx
f01017ec:	89 c1                	mov    %eax,%ecx
f01017ee:	d3 ef                	shr    %cl,%edi
f01017f0:	09 d7                	or     %edx,%edi
f01017f2:	89 f2                	mov    %esi,%edx
f01017f4:	89 f8                	mov    %edi,%eax
f01017f6:	f7 74 24 08          	divl   0x8(%esp)
f01017fa:	89 d6                	mov    %edx,%esi
f01017fc:	89 c7                	mov    %eax,%edi
f01017fe:	f7 24 24             	mull   (%esp)
f0101801:	39 d6                	cmp    %edx,%esi
f0101803:	89 14 24             	mov    %edx,(%esp)
f0101806:	72 30                	jb     f0101838 <__udivdi3+0x118>
f0101808:	8b 54 24 04          	mov    0x4(%esp),%edx
f010180c:	89 e9                	mov    %ebp,%ecx
f010180e:	d3 e2                	shl    %cl,%edx
f0101810:	39 c2                	cmp    %eax,%edx
f0101812:	73 05                	jae    f0101819 <__udivdi3+0xf9>
f0101814:	3b 34 24             	cmp    (%esp),%esi
f0101817:	74 1f                	je     f0101838 <__udivdi3+0x118>
f0101819:	89 f8                	mov    %edi,%eax
f010181b:	31 d2                	xor    %edx,%edx
f010181d:	e9 7a ff ff ff       	jmp    f010179c <__udivdi3+0x7c>
f0101822:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101828:	31 d2                	xor    %edx,%edx
f010182a:	b8 01 00 00 00       	mov    $0x1,%eax
f010182f:	e9 68 ff ff ff       	jmp    f010179c <__udivdi3+0x7c>
f0101834:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101838:	8d 47 ff             	lea    -0x1(%edi),%eax
f010183b:	31 d2                	xor    %edx,%edx
f010183d:	83 c4 0c             	add    $0xc,%esp
f0101840:	5e                   	pop    %esi
f0101841:	5f                   	pop    %edi
f0101842:	5d                   	pop    %ebp
f0101843:	c3                   	ret    
f0101844:	66 90                	xchg   %ax,%ax
f0101846:	66 90                	xchg   %ax,%ax
f0101848:	66 90                	xchg   %ax,%ax
f010184a:	66 90                	xchg   %ax,%ax
f010184c:	66 90                	xchg   %ax,%ax
f010184e:	66 90                	xchg   %ax,%ax

f0101850 <__umoddi3>:
f0101850:	55                   	push   %ebp
f0101851:	57                   	push   %edi
f0101852:	56                   	push   %esi
f0101853:	83 ec 14             	sub    $0x14,%esp
f0101856:	8b 44 24 28          	mov    0x28(%esp),%eax
f010185a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010185e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101862:	89 c7                	mov    %eax,%edi
f0101864:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101868:	8b 44 24 30          	mov    0x30(%esp),%eax
f010186c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101870:	89 34 24             	mov    %esi,(%esp)
f0101873:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101877:	85 c0                	test   %eax,%eax
f0101879:	89 c2                	mov    %eax,%edx
f010187b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010187f:	75 17                	jne    f0101898 <__umoddi3+0x48>
f0101881:	39 fe                	cmp    %edi,%esi
f0101883:	76 4b                	jbe    f01018d0 <__umoddi3+0x80>
f0101885:	89 c8                	mov    %ecx,%eax
f0101887:	89 fa                	mov    %edi,%edx
f0101889:	f7 f6                	div    %esi
f010188b:	89 d0                	mov    %edx,%eax
f010188d:	31 d2                	xor    %edx,%edx
f010188f:	83 c4 14             	add    $0x14,%esp
f0101892:	5e                   	pop    %esi
f0101893:	5f                   	pop    %edi
f0101894:	5d                   	pop    %ebp
f0101895:	c3                   	ret    
f0101896:	66 90                	xchg   %ax,%ax
f0101898:	39 f8                	cmp    %edi,%eax
f010189a:	77 54                	ja     f01018f0 <__umoddi3+0xa0>
f010189c:	0f bd e8             	bsr    %eax,%ebp
f010189f:	83 f5 1f             	xor    $0x1f,%ebp
f01018a2:	75 5c                	jne    f0101900 <__umoddi3+0xb0>
f01018a4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018a8:	39 3c 24             	cmp    %edi,(%esp)
f01018ab:	0f 87 e7 00 00 00    	ja     f0101998 <__umoddi3+0x148>
f01018b1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018b5:	29 f1                	sub    %esi,%ecx
f01018b7:	19 c7                	sbb    %eax,%edi
f01018b9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018bd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018c1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018c5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018c9:	83 c4 14             	add    $0x14,%esp
f01018cc:	5e                   	pop    %esi
f01018cd:	5f                   	pop    %edi
f01018ce:	5d                   	pop    %ebp
f01018cf:	c3                   	ret    
f01018d0:	85 f6                	test   %esi,%esi
f01018d2:	89 f5                	mov    %esi,%ebp
f01018d4:	75 0b                	jne    f01018e1 <__umoddi3+0x91>
f01018d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01018db:	31 d2                	xor    %edx,%edx
f01018dd:	f7 f6                	div    %esi
f01018df:	89 c5                	mov    %eax,%ebp
f01018e1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01018e5:	31 d2                	xor    %edx,%edx
f01018e7:	f7 f5                	div    %ebp
f01018e9:	89 c8                	mov    %ecx,%eax
f01018eb:	f7 f5                	div    %ebp
f01018ed:	eb 9c                	jmp    f010188b <__umoddi3+0x3b>
f01018ef:	90                   	nop
f01018f0:	89 c8                	mov    %ecx,%eax
f01018f2:	89 fa                	mov    %edi,%edx
f01018f4:	83 c4 14             	add    $0x14,%esp
f01018f7:	5e                   	pop    %esi
f01018f8:	5f                   	pop    %edi
f01018f9:	5d                   	pop    %ebp
f01018fa:	c3                   	ret    
f01018fb:	90                   	nop
f01018fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101900:	8b 04 24             	mov    (%esp),%eax
f0101903:	be 20 00 00 00       	mov    $0x20,%esi
f0101908:	89 e9                	mov    %ebp,%ecx
f010190a:	29 ee                	sub    %ebp,%esi
f010190c:	d3 e2                	shl    %cl,%edx
f010190e:	89 f1                	mov    %esi,%ecx
f0101910:	d3 e8                	shr    %cl,%eax
f0101912:	89 e9                	mov    %ebp,%ecx
f0101914:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101918:	8b 04 24             	mov    (%esp),%eax
f010191b:	09 54 24 04          	or     %edx,0x4(%esp)
f010191f:	89 fa                	mov    %edi,%edx
f0101921:	d3 e0                	shl    %cl,%eax
f0101923:	89 f1                	mov    %esi,%ecx
f0101925:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101929:	8b 44 24 10          	mov    0x10(%esp),%eax
f010192d:	d3 ea                	shr    %cl,%edx
f010192f:	89 e9                	mov    %ebp,%ecx
f0101931:	d3 e7                	shl    %cl,%edi
f0101933:	89 f1                	mov    %esi,%ecx
f0101935:	d3 e8                	shr    %cl,%eax
f0101937:	89 e9                	mov    %ebp,%ecx
f0101939:	09 f8                	or     %edi,%eax
f010193b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010193f:	f7 74 24 04          	divl   0x4(%esp)
f0101943:	d3 e7                	shl    %cl,%edi
f0101945:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101949:	89 d7                	mov    %edx,%edi
f010194b:	f7 64 24 08          	mull   0x8(%esp)
f010194f:	39 d7                	cmp    %edx,%edi
f0101951:	89 c1                	mov    %eax,%ecx
f0101953:	89 14 24             	mov    %edx,(%esp)
f0101956:	72 2c                	jb     f0101984 <__umoddi3+0x134>
f0101958:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010195c:	72 22                	jb     f0101980 <__umoddi3+0x130>
f010195e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101962:	29 c8                	sub    %ecx,%eax
f0101964:	19 d7                	sbb    %edx,%edi
f0101966:	89 e9                	mov    %ebp,%ecx
f0101968:	89 fa                	mov    %edi,%edx
f010196a:	d3 e8                	shr    %cl,%eax
f010196c:	89 f1                	mov    %esi,%ecx
f010196e:	d3 e2                	shl    %cl,%edx
f0101970:	89 e9                	mov    %ebp,%ecx
f0101972:	d3 ef                	shr    %cl,%edi
f0101974:	09 d0                	or     %edx,%eax
f0101976:	89 fa                	mov    %edi,%edx
f0101978:	83 c4 14             	add    $0x14,%esp
f010197b:	5e                   	pop    %esi
f010197c:	5f                   	pop    %edi
f010197d:	5d                   	pop    %ebp
f010197e:	c3                   	ret    
f010197f:	90                   	nop
f0101980:	39 d7                	cmp    %edx,%edi
f0101982:	75 da                	jne    f010195e <__umoddi3+0x10e>
f0101984:	8b 14 24             	mov    (%esp),%edx
f0101987:	89 c1                	mov    %eax,%ecx
f0101989:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010198d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101991:	eb cb                	jmp    f010195e <__umoddi3+0x10e>
f0101993:	90                   	nop
f0101994:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101998:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010199c:	0f 82 0f ff ff ff    	jb     f01018b1 <__umoddi3+0x61>
f01019a2:	e9 1a ff ff ff       	jmp    f01018c1 <__umoddi3+0x71>
