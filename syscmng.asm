%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
;%INCLUDE "Hardware/iodevice.lib"

[BITS 16]
[ORG SYSCMNG] 

jmp 	_SYSCALL_MAIN

STACK32_TOP  	EQU 0x200000
CODE32_VRAM  	EQU 0x110000
VIDEO_MEMORY    EQU 0x0B8000
PROGRAM_BUFFER  EQU 0x9000
PROGRAM_VRAM    EQU CODE32_VRAM+0x200
 
Return_Value dw 0
Counter 	 db 0


; ==================================================================
; Inicializaçao da chamada de programas e mudanças do processador

_SYSCALL_MAIN:
	jmp 	SwitchTo32BIT


; ==================================================================
	
	
SwitchTo32BIT:
	call 	EnableA20       ; Habilite o portão A20 (usa o método rápido como prova de conceito)
    cli
	
	mov		ax, 0x0800
	mov		ds,ax
	
    mov 	eax,cs          ; EAX = CS
    shl 	eax,4           ; EAX = (CS << 4)
    mov 	ebx,eax         ; Faça uma cópia de (CS << 4)
	
	cmp 	byte[Counter], 0
	ja 		NotLoadStructsAgain
	
	push 	eax
	mov 	si, IDT_Start
	mov 	di, Vector.Address 
	mov 	cx, IDTSIZE
FillIDT:
	mov 	eax, dword[di]
	and 	eax, 0x0000FFFF
	mov 	word[si], ax 
	mov 	eax, dword[di]
	and 	eax, 0xFFFF0000
	shr 	eax, 16
	mov 	word[si+6], ax
	add 	si, 8
	add 	di, 4
	loop 	FillIDT
	pop 	eax
	
	
	add 	[GDT+2], eax           ; Adicione o endereço linear básico ao endereço GDT_Start
    lgdt 	[GDT] 
	add 	[IDT32+2], eax
	
	; Calcule o endereço linear dos rótulos usando (segmento << 4) + deslocamento.
    ; EBX já é (segmento << 4). Adicione-o aos deslocamentos dos rótulos para
    ; converta-os em endereços lineares
	
NotLoadStructsAgain:	
	lidt 	[IDT32]
	
	mov 	edi, ProtectedMode16     ;  EDI = entrada de modo protegido de 16 bits (endereço linear)
	add 	edi, ebx                 ;  Endereço linear de ProtectedMode16
	add 	ebx, Code32Bit  		 ;  EBX = (CS << 4) + Code32Bit

	push 	ds
	push 	es
	push 	fs
	push 	gs
	mov 	ecx, cs
	
    push 	dword CODE_SEG32            ; 0x08 = Seletor de codigo 32 bit em CS
    push	ebx            			    ; Deslocamento linear de Code32Bit
    mov 	bp, sp          			; Endereço m16:32 no topo da pilha, aponte BP para ele
	
	
    mov 	eax,cr0
    or 		eax,1
    mov 	cr0,eax         			; Definir sinalizador de modo protegido
	
    jmp 	dword far [bp]
                      
	
	
; Habilite a20 (método rápido). Isso pode não funcionar em todos os hardwares
EnableA20:
    cli
    in 		al, 0x92         ; Leia a porta A de controle do sistema
    test 	al, 0x02         ; Teste o valor a20 atual (bit 1)
    jnz 	.skipfa20        ; Se já e 1, nao habilita
    or 		al, 0x02         ; Defina A20 bit (bit 1) como 1
    and 	al, 0xfe         ; Sempre escreva um zero no bit 0 para evitar
                             ;     uma reinicialização rápida em modo real
    out 	0x92, al         ; Habilite linha A20
.skipfa20:
    sti
ret


; Ponto de entrada e código de modo protegido de 16 bits
ProtectedMode16:
	mov 	word[Return_Value], ax
    mov 	ax, DATA_SEG16       ; Defina todos os segmentos de dados para o seletor de dados de 16 bits
    mov 	ds, ax
    mov 	es, ax
    mov 	fs, ax
    mov 	gs, ax
    mov 	ss, ax
	
	; Desativar paginação (bit 31) e modo protegido (bit 0)
    ; O kernel terá que se certificar de que o GDT está em
    ; a 1:1 (página de identidade mapeada), bem como memória inferior
    ; onde o programa DOS reside antes de retornar
    ; para nós com um RETF
	mov 	eax, cr0              ; Disable protected mode
    and 	eax, 0x7FFFFFFE     
	mov 	cr0, eax
	
	push 	cx
	push 	RealMode16
	retf
	
; Ponto de entrada de modo real de 16 bits
RealMode16:
	xor 	esp, esp          ; Limpar todos os bits no ESP
	mov 	ss, dx            ; Restaura o segmento de pilha de modo real
	lea 	sp, [bp+8]        ; Restaurar SP em modo real
	
	; (BP + 8 para pular o ponto de entrada de 32 bits e o seletor que
	; foi colocado na pilha em modo real)
	
    pop 	gs                      ; Restaurar o resto do segmento de dados de modo real
	pop 	fs
	pop 	es
	pop 	ds

	lidt 	[IDT16]                 ; Restaura a tabela de interrupção de modo real
    sti  
	inc 	byte[Counter]
ret

%INCLUDE "Hardware/gdtidt_x86.lib"

; Código que será executado no modo protegido de 32 bits
;
; Após a entrada, os registros contêm:
; EDI = entrada de modo protegido de 16 bits (endereço linear)
; ESI = buffer de memória do programa (endereço linear)
; EBX = Code32Bit (endereço linear)
; ECX = segmento de código de modo real DOS
ALIGN 4
Code32Bit:
BITS 32

SECTION protectedmode vstart=CODE32_VRAM, valign=4

Start32:
	mov 	si, dx
	mov 	ebp, esp
	mov 	edx, ss
	
    cld
    mov 	eax,DATA_SEG32              ; 0x10 = é um seletor plano para dados
    mov 	ds,eax
    mov 	es,eax
    mov 	fs,eax
    mov 	gs,eax
    mov 	ss,eax
    mov 	esp,STACK32_TOP             ; Deve definir ESP para um local de memória utilizável
	
	push 	CODE_SEG16                 ; Coloque o ponto de entrada remoto 0x18 do modo protegido de 16 bits: ProtectedMode16
    push 	edi
	
	push 	edx
	push 	ebp
	push 	ecx
	
	mov 	dx, si
	
	; A pilha vai crescer para baixo a partir deste local
	mov 	edi,CODE32_VRAM    ; EDI = endereço linear onde o código PM será copiado
    mov 	esi,ebx            ; ESI = endereço linear de Code32Bit
    mov 	ecx,PMSIZE_LONG    ; ECX = número de DWORDs para copiar
    rep 	movsd              ; Copie todos os códigos/dados de Code32Bit para CODE32_VRAM
	call 	CODE_SEG32:EntryCode32
	
	
	pop 	ecx
	pop 	ebp
	pop 	edx
	retf
	

EntryCode32:
	
	mov 	byte[CursorRaw], dh
	mov 	byte[CursorCol], dl
	
	mov 	edi,PROGRAM_VRAM       ; EDI = Endereço linear para onde o programa sera copiado
    mov 	esi,PROGRAM_BUFFER     ; ESI = Endereço Linear do programa (0x0900:0)
    mov 	cx,157                 ; ECX = numero de DWORDs para copiar
    rep 	movsb	   	           ; Copiar todas as ECX dwords de ESI para EDI 
    call 	CODE_SEG32:PROGRAM_VRAM   ; Salto absoluto para o novo endereço
	
	mov 	dh, byte[CursorRaw]
	mov 	dl, byte[CursorRaw]
	mov 	si, dx
	
	push 	eax
	mov 	al, 0
	mov 	edi, PROGRAM_VRAM
	mov 	cx, 157
	rep 	stosb

	mov 	edi, PROGRAM_BUFFER
	mov 	cx, 157
	rep 	stosb
	pop 	eax
	
retf


	; INT 0x01 : Interrupção de Vídeo  ------------
	; ---------------------------------------------
	; Função 0 		-> Exibir uma String na tela
	; Parâmetros: 	EAX = Função
	; 				ESI = String
	;				DL  = Cor de fundo|Texto
	;				ECX = Tamanho da String
	;Retorno: 		Nenhum
	
	; Função 1 		->  Pegar uma String da tela
	; Parâmetros: 	EAX = Função
	; 				EDI = Buffer
	;				DH  = Coluna
	; 				DL  = Linha
	;				ECX = Tamanho do Buffer
	; Retorno: 		Nenhum
	; ---------------------------------------------

BITS 32
LIB_String32:
	xor 	ebx, ebx
	mov 	bx, ax
	shl 	ebx, 2
	mov 	ebx, dword[MonitorRoutines + ebx]
	jmp 	ebx
	
MonitorRoutines:
	dd Print_String32
	dd Get_String
	
	
Print_String32:
	pushad
	push 	edx
	push 	ecx
	xor 	cx, cx
	xor 	eax, eax
	mov 	edi, VIDEO_MEMORY
	mov 	dh, byte[CursorRaw]
	mov 	al, (80*2)
	mov 	cl, dh
	mul 	cl
	mov 	cl, byte[CursorCol]
	shl 	cl, 1
	add 	ax, cx
	add 	edi, eax
	pop 	ecx
	pop 	edx
Print_S:
    mov 	al,byte [ds:esi]
    mov 	byte [edi],al 
    inc 	edi 
    mov 	al, dl
    mov 	byte [edi],al 
	inc 	esi
	inc 	edi
	loop 	Print_S
	popad
	inc 	byte[CursorRaw]
iretd
CursorRaw  db 0
CursorCol  db 0

Get_String:
	pushad
	mov 	esi, VIDEO_MEMORY
Get_S:
    mov 	al,byte [esi]
    mov 	byte [ds:edi],al 
	inc 	edi
	add 	esi, 2
	loop 	Get_S
	popad
iretd

PMSIZE_LONG equ ($-$$+3)>>2