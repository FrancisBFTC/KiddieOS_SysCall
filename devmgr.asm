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
Buffer1: db 0,0,0,0,0,0,0,0,0,0
Connect1:  db "|___",0
Connect2:  db 0x0D,"|___",0
Space:     db 0x0D,"|   ",0 
PCI:       db "PCI:",0
StrScan    db 0x0D,"Scanning Devices...",0x0D,0
StrFound   db " Devices Was Found!",0x0D,0

countstore  dd 0
countstack  dd 1
stack 		dd 0
highid      db 0

QUANT_DEV  EQU 4

Main(ARGC, ARGV)

	cli
	; Load Driver and Initialize Device
	mov 	eax, 0x14   ; Syscall Init_Device
	int 	0xCE        ; Invoke the Syscall
	
	mov 	DWORD[stack], esp
	sub 	DWORD[stack], 200
	
Printz(0x0F, StrScan)
mov 	ax, 0
mov 	bx, 0
mov 	dx, 0
mov 	ecx, 255
scan_bus:
	push 	ecx
	mov 	ecx, 32
	scan_dev:
		push 	ecx
		mov 	ecx, 8
		scan_func:
			push	ecx
			Get_Class_Number(ax, bx, dx)
			cmp 	ax, 0xFFFF
			je 		Skip_Store
			inc 	DWORD [countstore]
			
			mov 	ebx, 2
			mov 	ecx, DWORD[countstack]
			cmp 	DWORD[countstore], 1
			ja 		Comp_Class
			push 	ax
			add 	esp, 2
			mov 	ebp, esp
			mov 	esp, DWORD[stack]
			xor 	ecx, ecx
			push 	ecx
			mov 	DWORD[stack], esp
			mov 	esp, ebp
			jmp 	Skip_Store
		Comp_Class:
			cmp 	BYTE[esp - ebx], ah
			je 		Inc_Low_ID
			add 	ebx, 2
			loop 	Comp_Class
			sub 	esp, ebx
			add 	esp, 2
			push 	ax
			add 	esp, ebx
			inc 	DWORD[countstack]
			Restore_Args(ax, bx, dx)
		Inc_High_ID:	
			; Incrementar ID Alto & Salva parâmetros PCI
			mov 	ebp, esp
			mov 	esp, DWORD[stack]
			xor 	ecx, ecx
			add 	byte[highid], 0x10
			mov 	cl, byte[highid]
			shl 	ecx, 8
			mov 	cl, al
			shl 	ecx, 8
			mov 	cl, bl
			shl 	ecx, 8
			mov 	cl, dl
			push 	ecx
			mov 	DWORD[stack], esp
			mov 	esp, ebp
			inc 	edx
			pop 	ecx
			loop 	scan_func

		Inc_Low_ID:
			; Incrementar ID Baixo
			
		Skip_Store:	
			Restore_Args(ax, bx, dx)
			inc 	edx
			pop 	ecx
		loop	scan_func
		inc 	ebx
		pop 	ecx
	loop 	scan_dev
	inc 	eax
	pop 	ecx
loop 	scan_bus
Get_Dec32([countstore], Buffer1)
pop		eax
pop 	esi
Printz(0x02, esi)
Printz(0x0F, StrFound)	
	
	Printz(0x03, PCI)
	
	jmp 	$
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
