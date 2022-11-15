.586
.model flat, stdcall
.stack 4096

ExitProcess PROTO dwExitCode:DWORD

.data
mynum DWORD 6
mynum_factorial DWORD 0
mynum_flags DWORD 0

.code

CleanRegisters MACRO ; Just zeroes out all the main registers
	XOR eax, eax
	XOR ebx, ebx
	XOR ecx, ecx
	XOR edx, edx
ENDM

IsEven MACRO num, flags ; Checks if num is even, and sets 2nd bit of flags to 1 if so, otherwise leaves it untouched
	MOV eax, num

	CMP eax, 0 ; if num is 0, not even
	JLE is_odd

	XOR edx, edx		
	MOV ecx, 2 ; put 2 in register because immediates not allowed
	DIV ecx ; div num (in eax) by 2

	CMP edx, 0 ; if remainder is 0, is even, else odd
	JNE is_odd

	OR flags, 00000010b ; set flag

	is_odd:
	MOV ebx, flags ; put result in ebx
ENDM

main PROC
	_even_check:
	CleanRegisters
	IsEven mynum, mynum_flags ; check if even, place resulting flag in memory
	MOV mynum_flags, ebx

	_prime_check:
	CleanRegisters
	PUSH mynum_flags ; ebp + 12
	PUSH mynum ; ebp + 8
	CALL IsPrime ; check if prime, place resulting flag in memory
	MOV mynum_flags, ebx

	_factorial:
	CleanRegisters
	MOV ebx, mynum

	CMP ebx, 0 ; if mynum (in ebx) less than 0, dont call proc, handle with jump
	JL _negative

	PUSH ebx ; ebp + 8
	CALL Factorial ; factorial mynum, place result in memory
	MOV mynum_factorial, eax
	JMP _end

	_negative: ; handles a negative input, sets result to -1
	MOV mynum_factorial, -1
	
	_end:
	CleanRegisters
	mov eax, mynum ; all this is just for viewing values from memory more easily!
	mov ebx, mynum_factorial
	mov ecx, mynum_flags
	INVOKE ExitProcess, 0
main ENDP


Factorial PROC
	PUSH ebp ; save ebp
	MOV ebp, esp ; create stack frame
	MOV eax, [ebp+8] ; store arg

	CMP eax, 0 ; this handles a 0 input, increment makes it so output is 1 (negative input is impossible)
	JG _factorial

	INC eax

	_factorial:
	CMP eax, 1 ; if num is 1 or less, done 
	JLE end_factorial

	DEC eax ; decrement
	PUSH eax ; push for arg, ebp + 8 in proc
	CALL factorial ; recurse

	MOV esi, [esp+8] ; get arg from stack
	MUL esi ; multiply by eax

	end_factorial:
	POP ebp ; restore ebp
	RET	4 ; return and remove arg from stack
Factorial ENDP


IsPrime PROC
	PUSH ebp
	MOV ebp, esp ; establish stack frame
	MOV ecx, [ebp+8] ; mynum
	MOV ebx, [ebp+12] ; mynum_flags

	CMP ecx, 0 ; jump to end of prime check if negative
	JLE end_prime

	CMP ecx, 1 ; special case for 1, as right shift would make it considered nonprime
	JE prime

	SHR ecx, 1 ; effectively divides number by 2, also eliminates 1, which is nonprime
		       ; number / 2 is the largest factor we need to try to determine primeness

	TEST ecx, ecx ; set zero flag if ecx is zero
	JZ end_prime  ; if zero flag set, num was 0 or 1, so nonprime

	check_loop:
	CMP ecx, 1 ; if ecx is 1, every possible factor has been tried, so num is prime
	JBE prime  ; JBE = jump if below/equal

	MOV eax, [ebp+8] ; setting up for division
	XOR edx, edx

	DIV ecx
	TEST edx, edx ; if zero flag is ever set (aka edx is 0), number is not prime
	JZ end_prime

	LOOP check_loop

	prime:
	OR ebx, 00000001b ; set most significant bit if prime

	end_prime:
	POP ebp ; restore ebp
	RET 8 ; return and remove args from stack
IsPrime ENDP

END main