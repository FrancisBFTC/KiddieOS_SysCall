%INCLUDE 	"libasm.inc"

VCL   db 0,0
bus   db 0
dev   db 0
fun   db 0
count dw 0
ct 	  dw 0

Spaces db 0x0D,"|___",0

Verify_Class:
	pushad
	mov 	eax, 0x1B
	mov 	bh, [bus]
	mov 	bl, [dev]
	mov 	cl, [fun]
	int 	0xCE
	cmp 	ax, 0xFFFF
	je 		Ret_Verify
	mov		bx, word[ct]
	cmp		word[count], bx
	ja 		CompareToSub
	
	mov 	bx, word[count]
	mov 	edi, VCL
	mov 	byte[edi + ebx], ah
			
	mov 	eax, 0x16
	mov 	bh, [bus]
	mov 	bl, [dev]
	mov 	cl, [fun]
	int 	0xCE
	mov 	eax, 0x01
	mov  	edx, 0x07
	int 	0xCE
	
	inc 	word[count]
	jmp 	Ret_Verify
	
CompareToSub:
	cmp 	byte[VCL], ah
	jne 	Ret_Verify
	
	mov 	eax, 0x01
	mov 	esi, Spaces
	mov  	edx, 0x0F
	int 	0xCE

	mov 	eax, 0x17
	mov 	bh, [bus]
	mov 	bl, [dev]
	mov 	cl, [fun]
	int 	0xCE
	mov 	eax, 0x01
	mov  	edx, 0x06
	int 	0xCE
	
Ret_Verify:
	popad
	ret

Main(ARGC, ARGV)
	; Load Driver and Initialize Device
	mov 	eax, 0x14   ; Syscall Init_Device
	int 	0xCE        ; Invoke the Syscall
	
	xor 	ebx, ebx
	
	mov 	ecx, 255
Loop_Bus:
	push 	ecx
	mov 	byte[dev], 0
	
	mov 	ecx, 32
	Loop_Dev:
		push 	ecx
		mov 	byte[fun],0
		
		mov 	ecx, 8
		Loop_Func:
			push 	ecx
			
			call 	Verify_Class
			
			inc 	byte[fun]
			pop 	ecx
			loop 	Loop_Func
		
		inc 	byte[dev]
		pop 	ecx
		loop 	Loop_Dev
	
	inc 	byte[bus]
	pop 	ecx
	loop 	Loop_Bus
	
	inc 	word[ct]
	
	; Close Driver
	mov 	eax, 0x15   ; Syscall Close_Device
	int 	0xCE        ; Invoke the Syscall
.EndMain