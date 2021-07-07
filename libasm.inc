ORG   0
ALIGN 4

PROGRAM EQU 0x110200
Program32: 

BITS 32
SECTION protectedmode vstart=PROGRAM, valign=4

jmp 	_MAIN

%DEFINE EQ ,
%DEFINE Prints(ARG1, ARG2, ARG3)  Write ARG1, ARG2, ARG3
%DEFINE Main(ARG1, ARG2) .Main ARG1, ARG2

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
		call 	0x08:LIB.SYSCALL__WRITE
%ENDMACRO

; ============================================

LIB:
.SYSCALL__WRITE:
	pushad
	mov 	eax, 0
	int 	0x01
	popad
retf	
