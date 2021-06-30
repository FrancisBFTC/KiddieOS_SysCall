%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS 16]
[ORG SYSC_MNG] 

jmp 	_SYSCALL_MAIN

_SYSMODE   DB  16
_STACK_BP  DW  0xFFFF
_STACK_SP  DW  0xFFFF

_SYSCALL_MAIN:
	cmp 	byte[_SYSMODE], 16
	je 		GoTo16
	cmp 	byte[_SYSMODE], 32
	je 		GoTo32
	cmp 	byte[_SYSMODE], SYSTEM-1
	je 		Save16
	
	mov 	si, ErrorArq
	call 	Print_String
ret

; ==================================================================
; Altera o modo do processador & Carrega as estruturas

GoTo32:
	;mov 	ax, 0x0800
	;mov 	ds, ax
	;mov 	eax, ds
	;shl 	eax, 4
	;add 	dword[GDT32.Address32], eax
	;mov 	word[GDT32_Start.CAddr1], ax
	;mov 	word[GDT32_Start.DAddr1], ax
	;and 	eax, 0x00FF0000
	;shr 	eax, 16
	;mov 	byte[GDT32_Start.CAddr2], al
	;mov 	byte[GDT32_Start.DAddr2], al
	cli
	lgdt	[GDT32]   ; Carrega o GDT de 32-bit na CPU
	lgdt 	[cs:IDT32]   ; Carrega a IDT de 32-bit na CPU
	
	; Sander
	mov		eax,cr0 	 ; Define CPU para 32 bits
	or		eax, 1       ; <- The "Critical Error" in VirtualBox occurs here.
	mov		cr0,eax
	
	; Sander
	jmp 	GDT32CodeSeg:DefineSegments1  ; The crash occurs here after commenting the code above.
	

	[BITS 32]
	DefineSegments1:
		; Sander
		mov 	esi, 0xB8000       ; <- It never runs.
		mov 	al, 'Y'
		mov 	byte[esi], al
		
		mov		ax,GDT32DataSeg		; Carrega segmento no descritor de dados
		mov		ds,ax				; Para todos os registradores de segmentos
		mov		es,ax
		mov		fs,ax
		mov		gs,ax
		mov		ss,ax
		mov 	ebp, 0x90000
		mov 	esp, ebp
ret

GoTo16:
	cli
	lgdt	[GDT16]   ; Carrega o GDT de 16-bit na CPU
	lidt 	[cs:IDT16]   ; Carrega a IDT de 16-bit na CPU  
UpdateMode:
	mov		eax,cr0 	 ; Define CPU para 16 bits
	and		eax, 0
	mov		cr0,eax
	jmp  	DefineSegments2  ; Salta para rotina em 16 bits
	
	[BITS 16]
	DefineSegments2:
		cld
		mov		ax, 0x0800	; Carrega segmento no descritor de dados
		mov		ds,ax				; Para todos os registradores de segmentos
		mov		es,ax
		mov		fs,ax
		mov		gs,ax
		mov 	ax, 0x07D0
		mov 	ss, ax	
		mov 	bp, word[_STACK_BP]
		mov 	sp, word[_STACK_SP]
	sti
ret

Save16:
	cli
	sgdt	[GDT16]   ; Armazena da CPU para GDT de 16-bit
	sidt 	[IDT16]   ; Armazena da CPU para IDT de 16-bit
	jmp 	UpdateMode

; ==================================================================


; ==================================================================

;LoadIDT:
;	mov 	eax, cs
;	mov 	es, ax
;	movzx	eax,ax
;	shl		eax,4
;	mov	[R32_IDT_Base],eax
;	mov	[R16_IDT_Base],eax
;ret

; Alterar para 32 bit
;GoTo32:
	;pushfw
	;push	eax
	;push	word ds
	;push	word es
	;push	word fs
	;push	word gs
	;cli
	;mov		eax,ss
	;mov		cr3,eax

	; Code to 32 bit 
	
	;mov		eax,cr3
	;mov		ss,ax
	;lidt	[cs:IDTR32]
	;pop		word gs
	;pop		word fs
	;pop		word es
	;pop		word ds
	;pop		eax
	;popfw
;retfw


; ==================================================================


; ==================================================================
; Base = Addr1 + Addr2 + Addr3 (0x00000000)
; Segmento Limite = Size1 + Size2 (0xFFFFF)
; Estrutura GDT para 32-bit
; Contém descritor de código e dados

GDT32:
	.Size32    dw GDT32_End - GDT32_Start - 1		; Tamanho do GDT
	.Address32 dd GDT32_Start    			 	; Endereço Inicial do GDT

GDT32_Start:
	.NullDescriptor32 dq 0 			    	; Descritor Nulo

	; Descritor de código 32-bit
	; CS deve apontar para este descritor
	.Code32: 
		.CSize1    dw 0xFFFF	     ; Tamanho do segmento (primeiros 0-15 bits)
		.CAddr1    dw 0x8000      ; Endereço de base (0-15 bits) (Linear Address - 0x0800)
		.CAddr2    db 0x00        ; Endereço de base (16-23 bits)
		.CAccType  db 0x9A        ; Tipo de acesso (10011010b)
		.CF_Size2  db 1100_1111b  ; Flags (F) = High 4 bits, Size2 = Low 4 bits (Size = 20 bits)
		.CAddr3    db 0x00        ; Endereço de base (24-31 bits)
	   
	; Descriptor de dados 4GB 
	; DS, SS, ES, FS e GS devem apontar para este descritor
	.Data32: 
		.DSize1    dw 0xFFFF	     ; Tamanho de segmento (primeiros 0-15 bits)
		.DAddr1    dw 0x8000      ; Endereço de base (0-15 bits) (Linear Address - 0x0800)
		.DAddr2    db 0x00        ; Endereço de base (16-23 bits)
		.DAccType  db 0x92        ; Tipo de acesso (10010010b)
		.DF_Size2  db 1000_1111b  ; Flags (F) = High 4 bits, Size2 = Low 4 bits (Size = 20 bits)
		.DAddr3    db 0x00        ; Endereço de base (24-31 bits)
		
GDT32_End:

GDT32CodeSeg  EQU GDT32_Start.Code32 - GDT32_Start
GDT32DataSeg  EQU GDT32_Start.Data32 - GDT32_Start

; ==================================================================

; ==================================================================
; Estrutura GDT para 16-bit
; Recebe da CPU tudo que foi colocado pela BIOS:
; Tamanho da estrutura: 72 bytes; Endereço de base: 0x000FE89F (F000h:0E89Fh)
; Contém 9 descritores (2 deles sendo de código e 3 de dados + 4 nulos)
; 1 descritor de código aponta para o Segmento 0xF000 e 1 de dados para 0x0040
; 2 descritores de código e dados no modo protegido (Não apontam pra nenhum segmento)
; 3 descritores são no modo real e (2 deles apontam para um segmento)

GDT16:
	.Size16      dw 0x0000		 ; Tamanho do GDT
	.Address16   dd 0x00000000   ; Endereço Inicial do GDT

; ==================================================================


;GDT16CodeSeg  EQU GDT16_Start.Code16 - GDT16_Start

ErrorArq db "Error: This architecture is not recognized.",0

; ==================================================================
; Estrutura IDT (Interrupt Descriptor Table)
; Contém o descriptor de 32-bit & 16-bit
; O Limite é de 1023 (256 * 4) - 1
IDT32:
	.IDT_Size32  dw 1023
	.IDT_Addr32  dd IDT.Vector

IDT16:
	.IDT_Size16  dw 0x0000
	.IDT_Addr16  dd 0x00000000
; ==================================================================


; ==================================================================
; Vector Table
IDT.Vector:
	TIMES 0x7F DD 0x00000000
		   DW 0x0800, SYSC_MNG   ; INT 0x80
		   DW 0x0800, KERNEL     ; INT 0x81
		   DW 0x0800, SHELL16    ; INT 0x82
IDT.Rest:
	TIMES 1024 - (IDT.Rest-IDT.Vector) DB 0

; ==================================================================