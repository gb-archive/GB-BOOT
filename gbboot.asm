; GBBOOT
; this program is executed from WRAM
; this is the main utility program of the project

; other ideas:
; custom palette that carry into dmg games
; preconditioning the system state before branching
; sub menus are gonna be needed for all this haha
; serial console mode, in and out
; sound test mode
; arbitrary reads and writes
; image viewer

; tell wla-gb about the WRAM slots that it is executed from
.memorymap
	defaultslot 1
	slotsize $1000
	slot 0 $C000
	slot 1 $D000
.endme

; we aren't doing anything fancy with cgb wram bank switching or anything
.rombanksize $1000
.rombanks 2

; character encoding for using the font data with strings
; let's use $ terminated strings
; also the font is stolen from super mario land and i should fix it
.asciitable
	map "0" to "9" = $0
	map "A" to "Z" = $a
	map "." = $23
	map ":" = $25
	map "," = $26
	map "Z" = $27
	map "!" = $28
	map "-" = $29
	map "*" = $2a
	map "X" = $2b
	map " " = $2c
	map "$" = $2d
.enda

; includes
.include "cgb_hardware.i"

; defines
.define version "0.1"			; program version string
.define r_pad $80			; continuous pad
.define r_pad_instant $81		; intantaneous pad
.define r_menu_index $82		; hram var for current menu item index
.define r_system_id $83			; stores the register a on startup
.define str_buf $d000			; 16 byte string buf

; first bank
.bank 0 slot 0

; at the beginning
.org 0

; start
start:
	; first things first
	ldh	(r_system_id), a	; store the system signature
	di				; we can't use interrupts
	ld	sp, $dfff		; set stack to top of wram1
	call	disable_lcd		; turn off the lcd first
	ldh	a, (r_system_id)	; check for cgb
	cp	$11			; and if so
	call	z, init_cgb		; init the color functions
	call	init_lcd		; init the screen
	call	draw_init_screen	; draw the menu options and stuff
	xor	a			; start the menu index at 0
	ldh	(r_menu_index), a
	jr	+			; already drew the menu items so skip

; init the cgb functions
init_cgb:
	; load bg color palettes
	ld	a, $80			; start at 0 and auto increment
	ldh	(R_BCPS), a		; set the access settings
	ld	hl, palettes		; source of the color palette data
	ld	b, _sizeof_palettes	; length of the palette data
-	ldi	a, (hl)			; grab a byte
	ldh	(R_BCPD), a		; store the byte
	dec	b			; dec bytes remaining
	jr	nz, -			; loop until done

	; load obj color palettes
	ld	a, $80			; start at 0 and auto increment
	ldh	(R_OCPS), a		; set the access settings
	ld	hl, palettes		; source of the color palette data
	ld	b, _sizeof_palettes	; length of the palette data
-	ldi	a, (hl)			; grab a byte
	ldh	(R_OCPD), a		; store the byte
	dec	b			; dec bytes remaining
	jr	nz, -			; loop until done

	; load bg attributes
	ld	a, 1			; vram bank 1
	ldh	(R_VBK), a		; switch to vram bank 1
	ld	hl, $9800		; destination of the bg map attributes
	ld	bc, $400		; just fill the whole thing why not
-	ld	a, $00			; blank attributes, and first palette
	ldi	(hl), a			; store the attributes
	dec	bc			; dec the remaining bytes counter
	ld	a, b			; check it
	or	c			; to see if its 0
	jr	nz, -			; and loop until it is
	ld	a, 0			; vram bank 0
	ldh	(R_VBK), a		; switch back to vram bank 0

	; done
	ret

; enter the menu screen
enter_menu:
	; disable the lcd
	call	disable_lcd

	; redraw the menu items
	ld	de, menu_items		; the characters to copy
	ld	hl, ($9800 + $20 * 4)	; where to print the text
	call	print_list		; draw them

	; reset the pad, but keep the menu index
+	xor	a
	ldh	(r_pad), a
	ldh	(r_pad_instant), a
	call	read_joypad		; get the button presses to begin with

	; draw the selection token
	call	draw_menu_index

	; reenable the lcd
	call	enable_lcd

; menu selection loop
menu_selection:
	; check for input
	call	read_joypad		; get the button presses to begin with
	ldh	a, (r_pad_instant)	; grab the instantaneous button presses
	bit	7, a			; check to see if down was pressed
	jr	z, +
	call	inc_menu_index		; and move the selection down if so
	jr	menu_selection
+	bit	6, a			; check to see if down was pressed
	jr	z, +
	call	dec_menu_index		; and move the selection down if so
	jr	menu_selection
+	bit	0, a			; check to see if a button was pressed
	jr	z, menu_selection	; nothing pressed, loop

	; a button was pressed on a menu item
	ldh	a, (r_menu_index)	; grab the selected index
	cp	$00			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	cart_info		; this is it
+	cp	$01			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	dump_rom		; this is it
+	cp	$02			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	dump_save		; this is it
+	cp	$03			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	unimplemented		; this is it
+	cp	$04			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	unimplemented		; this is it
+	cp	$05			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	unimplemented		; this is it
+	cp	$06			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	unimplemented		; this is it
+	cp	$07			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	unimplemented		; this is it
+	cp	$08			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	execute_cart		; this is it
+	cp	$09			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	unimplemented		; this is it
+	cp	$0a			; find out which was pressed
	jr	nz, +			; yee, nee?
	call	unimplemented		; this is it
+	cp	$0b			; find out which was pressed
	jr	nz, menu_selection		; yee, nee?
	call	unimplemented		; this is it
	jr	menu_selection		; loop

; when you choose to dump the rom over serial
dump_rom:
	; print the message
	call	wait_for_lcd			; wait for the screen
	ld	de, rom_dump_message		; the characters to copy
	ld	hl, $9800			; where to print the text
	call	print_list			; print it

	; prepare to dump
	ld	hl, $0000		; source
	ld	bc, $8000		; size
	call	dump			; dump it

	; done
	call	wait_for_lcd			; wait for the screen
	ld	de, rom_dump_done_message	; the characters to copy
	ld	hl, $9800			; where to print the text
	call	print_list			; print it
	ret

; when you choose to dump the save over serial
dump_save:
	; print the message
	call	wait_for_lcd			; wait for the screen
	ld	de, save_dump_message		; the characters to copy
	ld	hl, $9800			; where to print the text
	call	print_list			; print it

	; prepare to dump
	ld	hl, $a000		; source
	ld	bc, $2000		; size
	call	dump			; dump it

	; done
	call	wait_for_lcd			; wait for the screen
	ld	de, save_dump_done_message	; the characters to copy
	ld	hl, $9800			; where to print the text
	call	print_list			; print it
	ret

; dump a memory region over serial
; start = hl
; length = bc
dump:
-	ldi	a, (hl)			; load a byte
	call	send_byte		; send the byte over serial
	dec	bc			; dec the bytes remaining counter
	ld	a, b			; check bc
	or	c			; to see if its done yet
	jr	nz, -			; and loop until done
	ret				; done

; sends a single byte over serial
; data = a
send_byte:
	push	af
	call	wait_for_serial		; wait for it to send
	pop	af
	ldh	(R_SB), a		; load the byte to send
	ld	a, $83			; internal clock, fast speed if possible
	ldh	(R_SC), a		; send it
	ret				; done here

; wait until a serial byte has been transfered
wait_for_serial:
-	ldh	a, (R_SC)		; get the control byte to check
	bit	7, a			; see if the transfer is still active
	jr	nz, -			; wait more if it is
	ret

; when you select to execte the inserted cart
execute_cart:
	; prepare to branch
	call	wait_for_lcd		; wait for the lcd a couple times
	call	wait_for_lcd		; wait for the lcd a couple times
	ldh	a, (r_system_id)	; restore the system signature
	jp	$100			; branch!

; choose to display information from the inserted cart header
cart_info:

; prints out the title of the inserted cartridge on the top line
print_cart_title:
	; grab the cart title
	ld	hl, $0134			; source: title in cart
	ld	de, str_buf			; dest: string buffer
	ld	b, $10				; length of buffer
-	ldi	a, (hl)				; grab char
	and	a				; check it
	jr	z, +				; is it the end of the string?
	; do this conversion from ascii better later! ! !
	ld	c, 55				; convert from ascii
	sub	c				; translate
	ld	(de), a				; nope so store the char
	inc	de				; inc the char pointer
	dec	b				; and dec remaining byte count
	jr	nz, -				; and loop til done

	; fill remainder of buffer with string termination
+	ld	a, $2d				; string term = $2d
-	ld	(de), a				; put it in the buffer
	inc	de				; increment the char pointer
	dec	b				; decrement the bytes remaining count
	jr	nz, -				; loop til done

	; print the string
	call	wait_for_lcd			; wait for the screen
	ld	de, cart_name_label		; first the "NAME:" label
	ld	hl, $9800			; destination in vram
	call	print_string			; print it
	ld	hl, $9805			; and then the title string itself

; prints str_buf in vram at hl
print_str_buf:
	ld	de, str_buf			; source is str_buf
	ld	b, $10				; length of buffer

; prints string into vram at hl from source de
print_string:
	; grab char
-	ld	a, (de)			; grab a character
	inc	de			; and inc the pointer
	cp	$2d			; is it the end of the string?
	ret	z			; then we are done here

	; otherwise just copy the char
	ldi	(hl), a			; put the char in place
	jr	-			; next char

	; done here
	ret

; when you select a yet to be implemented function from the menu
unimplemented:
	; print the message
	call	wait_for_lcd			; wait for the screen
	ld	de, unimplemented_message	; the characters to copy
	ld	hl, $9800			; where to print the text
	jp	print_list			; print it

; gets continuous joypad input on $ff80
; and instantaneous joypad input on $ff81
read_joypad:
	; select the direction keys
	ld	a, $20
	ldh	(R_P1), a

	; read the results
	ldh	a, (R_P1)
	ldh	a, (R_P1)

	; invert
	cpl

	; only care about pressed bits
	and	$0f

	; put on high bytes on b
	swap	a
	ld	b, a

	; select the button keys
	ld	a, $10
	ldh	(R_P1), a

	; read the results
	ldh	a, (R_P1)
	ldh	a, (R_P1)
	ldh	a, (R_P1)
	ldh	a, (R_P1)
	ldh	a, (R_P1)
	ldh	a, (R_P1)

	; invert
	cpl

	; only care about pressed bits
	and	$0f

	; merge with direction bits
	or	b

	; mask for instantaneous
	ld	c, a
	ldh	a, (r_pad)
	xor	c
	and	c

	; save instaneous
	ldh	(r_pad_instant), a

	; store continuous
	ld	a, c
	ldh	(r_pad), a

	; disable reading the buttons
	ld	a, $30
	ldh	(R_P1), a

	; done
	ret

; undraws the old token to draw the new one
undraw_menu_index:
	ld	a, $2c			; blank space
	jr	render_menu_index	; and draw the space

; go up in the menu
dec_menu_index:
	ldh	a, (r_menu_index)	; grab the menu index
	dec	a			; decrement it
	cp	$ff			; overflow?
	jr	nz, change_menu_index	; if so
	ld	a, $b			; then modulo it
	jr	change_menu_index	; and go change it

; go down in the menu
inc_menu_index:
	ldh	a, (r_menu_index)	; grab the menu index
	inc	a			; increment it
	cp	$c			; overflow?
	jr	nz, change_menu_index	; if so
	xor	a			; then modulo it

; changes the menu index to a
change_menu_index:
	push	af			; save a
	call	wait_for_lcd		; first wait till vblank
	call	undraw_menu_index	; first hide the current char
	pop	af			; grab a back
	ldh	(r_menu_index), a	; save the menu index

; draws the token indicating the selected menu item
draw_menu_index:
	ld	a, $2a			; and now draw the char

; a = character
render_menu_index:
	push	af			; save the character to draw
	ldh	a, (r_menu_index)	; grab the index
	inc	a			; make 0 count for 1
	ld	b, a			; put it on b
	ld	hl, ($9801 + $20 * 3)	; where to put it
	ld	de, $20			; line width
-	add	hl, de			; move down a line
	dec	b			; however many times the index is
	jr	nz, -			; continue until done
	pop	af			; then grab the character to draw again
	ld	(hl), a			; put the character where it goes

	; done
	ret

; sets all the tiles to spaces
clear_bg:
	; prepare to fill bg vram
	ld	hl, $9800		; destination
	ld	bc, $0400		; length

	; fill loop
-	ld	a, $2c			; take a space
	ldi	(hl), a			; and put it there
	dec	bc			; count down bytes remaining
	ld	a, b			; check b...
	or	c			; ...and c to see if bc is 0 yet
	jr	nz, -			; loop until so

	; done here
	ret

; displays the inital screen
draw_init_screen:
	; prepare to loop through the menu items
	ld	de, init_screen		; the characters to copy
	ld	hl, $9800		; where to print the text

; prints any list of lines you want
; hl = destination pointer
; de = string array pointer
print_list:
	push	hl			; save the location for next string

	; copy a string
	; grab char
-	ld	a, (de)			; grab a character
	inc	de			; and inc the pointer
	cp	$ff			; is it the end of the array?
	jr	z, +			; then we're done here!
	cp	$2d			; is it the end of the string?
	jr	z, ++			; then prepare for the text one!

	; otherwise just copy the char
	ldi	(hl), a			; put the char in place
	jr	-			; next char

	; go to next string
++	pop	hl			; retrieve the inital position
	push	de			; save the text location
	ld	de, $20			; jump down to the next line
	add	hl, de			; by adding $20 to the old inital position
	pop	de			; and retreive the text location
	push	hl			; and save the new inital position
	jr	-			; and procede to first new char

	; done here
+	pop	hl			; just to make the stack even
	ret

; wait for the lcd to finish its stuff so we can access vram
wait_for_lcd:
-	ldh	a, (R_LY)		; grab current line
	cp	$91			; is it at the end yet?
	jr	nz, -			; loop until so
	ret				; done

; disable the lcd
disable_lcd:
	; first wait unti the lcd is ready
	call wait_for_lcd

	; then turn off the lcd
	xor	a			; make a 0
	ldh	(R_LCDC), a		; turn off lcd

	; done
	ret

; reenable the lcd
enable_lcd:
	; turn lcd back on
	ld	a, %10010001		; lcd on, bg chr 0, bg on
	ldh	(R_LCDC), a		; put it
	ret				; done

; init the lcd and vram and stuff
; warning: make sure you disable it first and reenable it afterwards
init_lcd:
	; prepare to copy the font into chr memory
	ld	hl, font		; source
	ld	de, $8000		; destination
	ld	bc, _sizeof_font	; length

	; copy the font into memory
-	ldi	a, (hl)			; grab a byte
	ld	(de), a			; and put it where it goes
	inc	de			; get ready for next
	dec	bc			; count down how many bytes left
	ld	a, b			; check b...
	or	c			; ...and c to see if bc is 0 yet
	jr	nz, -			; loop until so

	; clear the screen
	call clear_bg

	; setup color palette
	ld	a, $e4			; 'standard' palette
	ldh	(R_BGP), a		; put it

	; done
	ret

; this is the font data
font:
.incbin "font.chr"
font_end:

; color palettes for cgb
palettes:
.dw $739f $aabd $557a $0007
palettes_end:

; these are the menu option names
; array is $ff terminated
init_screen:
.asc "   HELLO!$"
.asc "  GB BOOT VER " version "$"
.asc " OK TO REMOVE CART$"
.asc "$"
menu_items:
.asc "   CART INFO$"
.asc "   DUMP ROM$"
.asc "   DUMP SAVE$"
.asc "   LOAD ROM$"
.asc "   LOAD SAVE$"
.asc "   ERASE FLASH$"
.asc "   PROGRAM FLASH$"
.asc "   SERIAL BOOT$"
.asc "   EXECUTE CART$"
.asc "   MBC:$"
.asc "   ROM SIZE:$"
.asc "   SRAM SIZE:$"
.asc "$"
.asc "GB BOOT BY MEGALOLER$"
.asc $ff

; beginning to dump save
save_dump_message:
.asc "DUMPING CART SAVE...$"
.asc "   PRESS B TO CANCEL$"
.asc "  BANK: 00 OF 00    $"
.asc $ff

; canceled save dump
save_dump_canceled_message:
.asc "DUMPING CART SAVE   $"
.asc "    DUMP CANCELED   $"
.asc $ff

; completed save dump
save_dump_done_message:
.asc "DUMPING CART SAVE   $"
.asc "    DUMP COMPLETE!  $"
.asc $ff


; beginning to dump rom
rom_dump_message:
.asc "DUMPING CART ROM... $"
.asc "   PRESS B TO CANCEL$"
.asc "  BANK: 00 OF 00    $"
.asc $ff

; canceled rom dump
rom_dump_canceled_message:
.asc "DUMPING CART ROM    $"
.asc "    DUMP CANCELED   $"
.asc $ff

; completed rom dump
rom_dump_done_message:
.asc "DUMPING CART ROM    $"
.asc "    DUMP COMPLETE!  $"
.asc $ff

; the message that tells you something isnt done yet
unimplemented_message:
.asc "  OOPS              $"
.asc "NOT YET IMPLEMENTED $"
.asc "  TRY AGAIN, SILLY! $"
.asc $ff

; some various lone strings
cart_name_label:
.asc "NAME:$"
