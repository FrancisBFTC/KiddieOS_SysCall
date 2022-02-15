%INCLUDE 	"libasm.inc"

VCL:     db 0,0,0,0,0,0
bus:     db 0
dev:     db 0
fun:     db 0
count:   dw 0
ct:      dw 0
index:   dw 0
Colc1    db " [",0
Colc2    db "]",0
Buffer:  db "0000",0
Connect1:  db "|___",0
Connect2:  db 0x0D,"|___",0
Space:     db 0x0D,"|   ",0 
PCI:       db "PCI:",0

QUANT_DEV  EQU 3

Main(ARGC, ARGV)

	cli
	; Load Driver and Initialize Device
	mov 	eax, 0x14   ; Syscall Init_Device
	int 	0xCE        ; Invoke the Syscall
	
	Printz(0x03, PCI)
	
	xor 	ebx, ebx
	mov 	ecx, QUANT_DEV
Loop_Tree:	
	push 	ecx
	
	Printz(0x0F, Connect2)
	
	mov 	ecx, 255
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
			
			Get_Class_Number(ax, bx, dx)
			
			cmp 	ax, 0xFFFF
			je 		Ret_Verify
			
			mov 	cx, word[index]
			
			cmp 	word[ct], 1
			je 		NewClass
		
			cmp		word[count], 0
			ja 		CompareToSub
		SaveClass:
			mov 	bx, word[index]
			mov 	edi, VCL
			mov 	byte[edi + ebx], ah
			
			Restore_Args(ax, bx, dx)
			Get_Class_Name(ax, bx, dx)
			Printz(0x07, esi)
			Printz(0x0F, Space)
			Printz(0x0F, Connect1)
			Restore_Args(ax, bx, dx)
			Get_SubClass_Name(ax, bx, dx)
			Printz(0x06, esi)
			
			Restore_Args(ax, bx, dx)
			Get_Class_Number(ax, bx, dx)
			Get_Hexa16(ax, Buffer)
			Printz(0x06, Colc1)
			pop  ax
			pop  esi
			Printz(0x05, esi)
			Printz(0x06, Colc2)
			
			inc 	word[count]
			inc 	word[index]
			jmp 	Ret_Verify
			
		NewClass:
			xor 	ebx, ebx
			Loop_New_Class:
				cmp 	byte[VCL + ebx], ah
				je 		Ret_Verify
				inc 	ebx
				loop 	Loop_New_Class
				mov 	word[ct], 0
				jmp 	SaveClass
			
		CompareToSub:
			mov 	bx, word[index]
			sub 	ebx, 1
			cmp 	byte[VCL + ebx], ah
			jne 	Ret_Verify
			
			Printz(0x0F, Space)
			Printz(0x0F, Connect1)
			Restore_Args(ax, bx, dx)
			Get_SubClass_Name(ax, bx, dx)
			Printz(0x06, esi)
			
			Restore_Args(ax, bx, dx)
			Get_Class_Number(ax, bx, dx)
			Get_Hexa16(ax, Buffer)
			Printz(0x06, Colc1)
			pop  ax
			pop  esi
			Printz(0x05, esi)
			Printz(0x06, Colc2)
			
		Ret_Verify:       
			
			Restore_Args(ax, bx, dx)
			
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
	
	mov 	word[ct], 1
	mov 	word[count], 0

Printz(0x0F, Space)

pop 	ecx
dec 	ecx
cmp 	ecx, 0
jnz  	Loop_Tree
	
Printz(0x0F, Connect2)

	; Close Driver
	mov 	eax, 0x15   ; Syscall Close_Device
	int 	0xCE        ; Invoke the Syscall
	
	sti
.EndMain
