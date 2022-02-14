ADDRESS EQU 0x112000

ORG   0x9000
ALIGN 4
Code32Bit:
BITS 32

SECTION protectedmode vstart=ADDRESS, valign=4
%DEFINE EQ ,
%DEFINE Prints(ARG1, ARG2, ARG3)  Write ARG1, ARG2, ARG3
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

; ============================================
; Macro Functions Library

%MACRO Write 3
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
		call 	0x08:LIB.SYS__WRITE
%ENDMACRO

; ============================================

LIB:
.SYS__WRITE:
	pushad
	mov 	eax, 0
	int 	0xCE
	popad
retf	

;
; Return a Device Class Number
; unsigned short Get_Class_Device(uint16_t bus, uint16_t dev, uint16_t func)
; bus  = 8
; dev  = 10
; func = 12
; ebp
Get_Class_Device:
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
Get_Class_Name:
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
Get_SubClass_Name:
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
