.386 ;
.model flat,stdcall ; Flat memory model
option casemap:none ; Treat labels as case-sensitive

.code

_start:

__setjmp_wrapper PROC
    mov eax,[esp+4]
	mov [eax], ebx
	mov [eax+4], esi
	mov [eax+8], edi
	mov [eax+12], ebp
	lea ecx, [esp+4]
	mov [eax+16], ecx
	mov ecx, [esp]
	mov [eax+20], ecx
	xor eax, eax
	ret
__setjmp_wrapper ENDP

__longjmp_wrapper PROC
	mov edx, [esp+4]
	mov eax, [esp+8]
	cmp eax, 1
	adc al, 0
	mov ebx, [edx]
	mov esi, [edx+4]
	mov edi, [edx+8]
	mov ebp, [edx+12]
	mov esp, [edx+16]
	jmp DWORD PTR [edx+20]
__longjmp_wrapper ENDP

END _start