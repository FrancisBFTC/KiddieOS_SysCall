%INCLUDE 	"libasm.inc"

Main(ARGC, ARGV)
	; Load Driver and Initialize Device
	mov 	eax, 0x14   ; Syscall Init_Device
	int 	0xCE        ; Invoke the Syscall
	
	xor 	ebx, ebx
	
	mov 	ecx, 100
	mov 	ax, 0
	mov 	bx, 0
	mov 	dx, 0
Loop_Bus:
	push 	ecx
	mov 	bx, 0
	
	mov 	ecx, 32
	Loop_Dev:
		push 	ecx
		mov 	dx,0
		
		mov 	ecx, 8
		Loop_Func:
			push 	ecx
			
			push 	ax
			push    bx
			push  	dx
			call 	Get_Class_Device
			;sub 	esp, 6
			
			cmp 	ax, 0xFFFF
			je 		Ret_Verify
			mov		bx, word[ct]
			cmp		word[count], bx
			ja 		CompareToSub
	
			mov 	bx, word[count]
			mov 	edi, VCL
			mov 	byte[edi + ebx], ah
			
			pop 	dx
			pop 	bx
			pop 	ax
			
			push 	ax
			push    bx
			push  	dx
			call 	Get_Class_Name
			;sub 	esp, 6
			
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
			
			pop 	dx
			pop 	bx
			pop 	ax
			
			push 	ax
			push    bx
			push  	dx
			call 	Get_SubClass_Name
			;sub 	esp, 6
			
			mov 	eax, 0x01
			mov  	edx, 0x06
			int 	0xCE
		
		Ret_Verify:          ; Fault -> GPF Error Here
		                     ; Any instruction that is put here, give us GPF Error
			
			pop 	dx 
			pop 	bx
			pop 	ax
			
			inc 	dx
			
			pop 	ecx
			dec 	ecx
			cmp 	ecx, 0
			jnz  	Loop_Func
		
		inc 	bx
		
		pop 	ecx
		dec 	ecx
		cmp 	ecx, 0
		jnz  	Loop_Dev
	
	inc 	ax
	
	pop 	ecx
	dec 	ecx
	cmp 	ecx, 0
	jnz  	Loop_Bus
	
	inc 	word[ct]
	jmp 	$
	
	; Close Driver
	mov 	eax, 0x15   ; Syscall Close_Device
	int 	0xCE        ; Invoke the Syscall
.EndMain

SECTION .data

VCL:   db 0,0
bus:   db 0
dev:   db 0
fun:   db 0
count: dw 0
ct:    dw 0
Spaces: db 0x0D,"|___",0