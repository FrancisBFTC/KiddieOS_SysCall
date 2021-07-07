%INCLUDE "libasm.inc"

INT8  Number EQ 0x41
CHAR  Value  EQ "X"

Main(ARGC, ARGV)
	
	; Prints (Arg1, Arg2, Arg3) ->
	; Arg1: Type
	; Arg2: Color Back/Fore
	; Arg3: Content Value
	
	Prints ('s', 0x4F, "My own program running!")
	Prints ('s', 0x2F, "Variable Value = ")
	Prints ('c', 0x1F, Value)
	
.EndMain
