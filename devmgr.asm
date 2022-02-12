%INCLUDE 	"libasm.inc"

Main(ARGC, ARGV)
	; VirtualBox Graphics Adapter
	mov 	eax, 0x4    ; SysCall PCI Get_Name_Device
	mov 	bh, 0       ; Bus Number
	mov 	bl, 2       ; Device Number
	mov 	cl, 0       ; Function Number
	int 	0xCE        ; Invoke the Syscall
						; Return = ESI
	                    ; ESI = Device String; 
	mov 	eax, 0x1    ; SysCall Print_Zero_Terminated
	mov 	edx, 0x05   ; Color Back|Fore
	int 	0xCE        ; Invoke the Syscall
	
	; PIIX4 ACPI
	mov 	eax, 0x4    ; SysCall PCI Get_Name_Device
	mov 	bh, 0       ; Bus Number
	mov 	bl, 7       ; Device Number
	mov 	cl, 0       ; Function Number
	int 	0xCE        ; Invoke the Syscall
						; Return = ESI
	                    ; ESI = Device String; 
	mov 	eax, 0x1    ; SysCall Print_Zero_Terminated
	mov 	edx, 0x02   ; Color Back|Fore
	int 	0xCE        ; Invoke the Syscall
.EndMain