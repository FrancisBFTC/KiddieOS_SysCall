ADDRESS EQU 0x112000

ORG   0x9000
ALIGN 4
Code32Bit:
BITS 32

SECTION protectedmode vstart=ADDRESS, valign=4
%DEFINE EQ ,
%DEFINE Main(ARG1, ARG2) .Main ARG1, ARG2
%DEFINE _ENTRY(FUNC) (FUNC - SIZE_PROG)

; ---------------------------------------------------------
; Estrutura de Executável KiddieOS

START_PROG:
	OPCODE:     db 0xE9
	ENTRY:      dd _ENTRY(_MAIN)
	SIZE_PROG: 	dd (END_PROG - START_PROG)
	ADDR_PROG:	dd ADDRESS
; ---------------------------------------------------------


; ============================================
; Entry & End of program

%MACRO .Main 2
	%1 db 0
	%2 db (_END + 3)
	_MAIN:
		pushad	
%ENDMACRO 

%MACRO .EndMain 0
	_END:
		popad
		mov 	ax, 0
		retf
	END_PROG:
		nop
%ENDMACRO
; ============================================

; ============================================
; Primitive Types

%MACRO INT8 2
	%1 db %2,0
%ENDMACRO

%MACRO INT16 2
	%1 dw %2,0
%ENDMACRO

%MACRO INT32 2
	%1 dd %2,0
%ENDMACRO

%MACRO INT64 2
	%1 dq %2,0
%ENDMACRO

%MACRO CHAR 2
	%1 db %2,0
%ENDMACRO

%MACRO CHARS 2
	%1: db %2,0
	%1.Length dw ($ - %1)
%ENDMACRO
; ============================================

; =====================================================================
; Macro Functions Library

%DEFINE Prints(ARG1, ARG2, ARG3)  STR.Write ARG1, ARG2, ARG3
%DEFINE Printz(ARG1, ARG2)        STR.Write_Till_Zero ARG1, ARG2
%DEFINE Get_Hexa16(ARG1, ARG2)    STR.Get_Hexa_16 ARG1, ARG2
%DEFINE Get_Hexa32(ARG1, ARG2)    STR.Get_Hexa_32 ARG1, ARG2
%DEFINE Get_Dec32(ARG1, ARG2)     STR.Get_Dec_32 ARG1, ARG2

%MACRO STR.Write 3
	jmp 	0x08:%%String
	%IF %1 == 's'
		%%Data: db %3
		%%Data.Length dd ($ - %%Data)
		%%String:
			mov 	esi, %%Data
			mov 	ecx, dword[ %%Data.Length ]
	%ELIF %1 == 'i'
		%%String:
			mov 	esi, %3
	%ELIF %1 == 'c'
		%%String:
			mov 	esi, %3
			mov 	ecx, 1
	%ELSE
		%%String:
			mov 	esi, %3
			;mov 	ecx, word[ %3.length ]
			mov 	ecx, 1
	%ENDIF
		mov 	dl, %2
		call 	__SYS_WRITE
%ENDMACRO

%MACRO STR.Write_Till_Zero 2
	push 	DWORD %2
	push    DWORD %1
	call 	__SYS_WRITE_TILL_ZERO
	STR.Restore_Args1
%ENDMACRO

%MACRO STR.Restore_Args1 0
	pop 	edx
	pop     esi
%ENDMACRO

%MACRO STR.Get_Hexa_16 2
	push 	DWORD %2
	push 	WORD  %1
	call 	__SYS_GET_HEXA_16	
%ENDMACRO

%MACRO STR.Get_Hexa_32 2
	push 	DWORD %2
	push 	DWORD %1
	call 	__SYS_GET_HEXA_32
%ENDMACRO

%MACRO STR.Get_Dec_32 2
	push 	DWORD %2
	push 	DWORD %1
	call 	__SYS_GET_DEC_32
%ENDMACRO

; Print X Bytes on Screen
; void SYS_WRITE(char *String)
__SYS_WRITE:
	pushad
	mov 	eax, 0x00
	int 	0xCE
	popad
ret

; Print a String on Screen zero-terminated
; void SYS_WRITE_TILL_ZERO(int color, char* String)
; color  = 8
; String = 12
; ebp
__SYS_WRITE_TILL_ZERO:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x01
	mov 	edx, DWORD [ebp + 8]
	mov 	esi, DWORD [ebp + 12]
	int 	0xCE
	
	pop ebp
ret

; Fill a buffer with a 16-bit hexadecimal value
; void SYS_GET_HEXA_16(uint16_t number, char* String)
; number  = 8
; String  = 12
; ebp
__SYS_GET_HEXA_16:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x1D
	mov 	bx, WORD [ebp + 8]
	mov 	edi, DWORD [ebp + 10]
	int 	0xCE
	
	pop ebp
ret

; Fill a buffer with a 32-bit hexadecimal value
; void SYS_GET_HEXA_32(int number, char* String)
; number  = 8
; String  = 12
; ebp
__SYS_GET_HEXA_32:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x1C
	mov 	ebx, DWORD [ebp + 8]
	mov 	edi, DWORD [ebp + 12]
	int 	0xCE
	
	pop ebp
ret


; Fill a buffer with a 32-bit decimal value
; void SYS_GET_DEC_32(int number, char* String)
; number  = 8
; String  = 12
; ebp
__SYS_GET_DEC_32:
	push 	ebp
    mov 	ebp,esp
	
	mov 	eax, 0x1E
	mov 	ebx, DWORD [ebp + 8]
	mov 	edi, DWORD [ebp + 12]
	int 	0xCE
	
	pop ebp
ret


; =====================================================================


; =====================================================================
; PCI Macros & Functions

%DEFINE Get_Class_Number(X, Y, Z)  PCI.Get_Device_Number X, Y, Z
%DEFINE Get_Class_Name(X, Y, Z)    PCI.Get_Class_Name X, Y, Z
%DEFINE Get_SubClass_Name(X, Y, Z) PCI.Get_SubClass_Name X, Y, Z
%DEFINE Restore_Args(X, Y, Z)      PCI.Restore_Args X, Y, Z


%MACRO PCI.Get_Device_Number 3
	push 	WORD %3
	push    WORD %2
	push  	WORD %1
	call 	__Get_Class_Device
%ENDMACRO

%MACRO PCI.Get_Class_Name 3
	push 	WORD %3
	push    WORD %2
	push  	WORD %1
	call 	__Get_Class_Name
%ENDMACRO

%MACRO PCI.Get_SubClass_Name 3
	push 	WORD %3
	push    WORD %2
	push  	WORD %1
	call 	__Get_SubClass_Name
%ENDMACRO

%MACRO PCI.Restore_Args 3
	pop 	WORD %1
	pop     WORD %2
	pop  	WORD %3
%ENDMACRO

%MACRO PCI.Restore_Args1 3
	pop 	ax
	pop     bx
	pop  	dx
%ENDMACRO

; Return a Device Class Number
; unsigned short Get_Class_Device(uint16_t bus, uint16_t dev, uint16_t func)
; bus  = 8
; dev  = 10
; func = 12
; ebp
__Get_Class_Device:
    push 	ebp
    mov 	ebp,esp

    mov 	eax,0x1B
    mov 	bx, word [ebp + 8]
	shl 	bx, 8
    or  	bx, word [ebp + 10]
    mov 	cx, word [ebp + 12]
    int 	0xCE

    pop ebp
    ret
	
;
; Return a Class Name Device
; char* Get_Class_Name(uint16_t bus, uint16_t dev, uint16_t func)
; bus  = 8
; dev  = 10
; func = 12
; ebp
__Get_Class_Name:
    push 	ebp
    mov 	ebp,esp

    mov 	eax,0x16
    mov 	bx, word [ebp + 8]
	shl 	bx, 8
    or  	bx, word [ebp + 10]
    mov 	cx, word [ebp + 12]
    int 	0xCE

    pop ebp
    ret
	
;
; Return a SubClass Name Device
; char* Get_SubClass_Name(uint16_t bus, uint16_t dev, uint16_t func)
; bus  = 8
; dev  = 10
; func = 12
; ebp
__Get_SubClass_Name:
    push 	ebp
    mov 	ebp,esp

    mov 	eax,0x17
    mov 	bx, word [ebp + 8]
	shl 	bx, 8
    or  	bx, word [ebp + 10]
    mov 	cx, word [ebp + 12]
    int 	0xCE

    pop ebp
    ret
; =====================================================================