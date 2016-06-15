ADD_1:		dd 01010101h, 01010101h
MASK_AND:	dd 7f7f7f7fh, 7f7f7f7fh
PLUS_384:	dd 01800180h, 01800180h
PLUS_128:	dd 00800080h, 00800080h

%assign LocalFrameSize  0
%assign RegisterStorageSize  16

; Arguments:
%assign source                    LocalFrameSize + RegisterStorageSize +  4
%assign dest                      LocalFrameSize + RegisterStorageSize +  8
%assign lx2                       LocalFrameSize + RegisterStorageSize + 12
%assign h                         LocalFrameSize + RegisterStorageSize + 16

; Locals (on local stack frame)


; extern void C rec_mmx (
;                                     unsigned char *source,
;                                     unsigned char *dest,
;                                     int lx2,
;                                     int h
;
;  The local variables are on the stack,
;

global recva_mmx
global recvac_mmx
global rech_mmx
global rechc_mmx
global add_block_mmx
global set_block_mmx


  align 16
rech_mmx:
  push       esi
  push       edi
  push       ecx
  push       ebx
  mov        esi, [esp+source]
  mov        edi, [esp+dest]
  mov        ecx, [esp+h]
  mov        ebx, [esp+lx2]
  movq       mm5, [MASK_AND]
  movq       mm6, [ADD_1]
.rech1:
  movq       mm0,[esi]
  movq       mm1,[esi+1]
  movq       mm2,[esi+8]
  movq       mm3,[esi+9]
  psrlw      mm0,1
  psrlw      mm1,1
  psrlw      mm2,1
  psrlw      mm3,1
  pand       mm0,mm5
  pand       mm1,mm5
  pand       mm2,mm5
  pand       mm3,mm5
  paddusb    mm0,mm1
  paddusb    mm2,mm3
  paddusb    mm0,mm6
  paddusb    mm2,mm6
  movq       [edi],mm0
  add        esi,ebx
  movq       [edi+8],mm2
  add        edi,ebx
  dec        ecx
  jnz        .rech1
  emms
  pop        ebx
  pop        ecx
  pop        edi
  pop        esi
  ret

  align 16
rechc_mmx:
  push       esi
  push       edi
  push       ecx
  push       ebx
;  sub        esp, LocalFrameSize
  mov        esi, [esp+source]
  mov        edi, [esp+dest]
  mov        ecx, [esp+h]
  mov        ebx, [esp+lx2]
  movq       mm5, [MASK_AND]
  movq       mm6, [ADD_1]
.rechc1:
  movq       mm0,[esi]
  movq       mm1,[esi+1]
  psrlw      mm0,1
  psrlw      mm1,1
  pand       mm0,mm5
  pand       mm1,mm5
  paddusb    mm0,mm1
  paddusb    mm0,mm6
  movq       [edi],mm0
  add        edi,ebx
  add        esi,ebx
  dec        ecx
  jnz        .rechc1
  emms
;  add        esp, LocalFrameSize
  pop        ebx
  pop        ecx
  pop        edi
  pop        esi
  ret



%assign RegisterStorageSize  20
%assign source                    LocalFrameSize + RegisterStorageSize +  4
%assign dest                      LocalFrameSize + RegisterStorageSize +  8
%assign lx                        LocalFrameSize + RegisterStorageSize + 12
%assign lx2                       LocalFrameSize + RegisterStorageSize + 16
%assign h                         LocalFrameSize + RegisterStorageSize + 20

  align 16
recva_mmx:
  push       esi
  push       edi
  push       ecx
  push       ebx
  push       edx
  mov        esi, [esp+source]
  mov        edi, [esp+dest]
  mov        ecx, [esp+h]
  mov        ebx, [esp+lx2]
  mov        edx, [esp+lx]
  movq	     mm7, [MASK_AND]
  movq	     mm6, [ADD_1]
.recva1:
  movq       mm0,[esi]
  movq       mm1,[esi+edx]
  movq       mm2,[esi+8]
  movq       mm3,[esi+edx+8]
  movq       mm4,[edi]
  movq	     mm5,[edi+8]
  psrlw      mm0,1
  psrlw      mm1,1
  psrlw      mm2,1
  psrlw      mm3,1
  psrlw      mm4,1
  psrlw      mm5,1
  pand       mm0,mm7
  pand       mm1,mm7
  pand       mm2,mm7
  pand       mm3,mm7
  pand       mm4,mm7
  pand       mm5,mm7
  paddusb    mm0,mm1
  paddusb    mm2,mm3
  paddusb    mm0,mm6
  paddusb    mm2,mm6
  psrlw      mm0,1
  psrlw      mm2,1
  pand       mm0,mm7
  pand       mm2,mm7
  paddusb    mm4,mm0
  paddusb    mm5,mm2
  paddusb    mm4,mm6
  paddusb    mm5,mm6
  movq       [edi],mm4
  movq       [edi+8],mm5
  add        edi,ebx
  add        esi,ebx
  dec        ecx
  jnz        near .recva1
  emms
  pop        edx
  pop        ebx
  pop        ecx
  pop        edi
  pop        esi
  ret

  align 16
recvac_mmx:
  push       esi
  push       edi
  push       ecx
  push       ebx
  push       edx
  mov        esi, [esp+source]
  mov        edi, [esp+dest]
  mov        ecx, [esp+h]
  mov        ebx, [esp+lx2]
  mov        edx, [esp+lx]
  movq	     mm5, [MASK_AND]
  movq	     mm6, [ADD_1]
.recvac1:
  movq       mm0,[esi]
  movq       mm1,[esi+edx]
  movq       mm4,[edi]
  psrlw      mm0,1
  psrlw      mm1,1
  psrlw      mm4,1
  pand       mm0,mm5
  pand       mm1,mm5
  pand       mm4,mm5
  paddusb    mm0,mm1
  paddusb    mm0,mm6
  psrlw      mm0,1
  pand       mm0,mm5
  paddusb    mm4,mm0
  paddusb    mm4,mm6
  movq       [edi],mm4
  add        edi,ebx
  add        esi,ebx
  dec        ecx
  jnz        .recvac1
  emms
  pop        edx
  pop        ebx
  pop        ecx
  pop        edi
  pop        esi
  ret

%assign RegisterStorageSize  20
%assign rfp                       LocalFrameSize + RegisterStorageSize +  4
%assign bp                        LocalFrameSize + RegisterStorageSize +  8
%assign iincr                     LocalFrameSize + RegisterStorageSize + 12

; FIXME clipping needs to be done

  align 16
add_block_mmx:
  push       esi
  push       edi
  push       ecx
  push       ebx
  push       edx
  mov        esi, [esp+bp]
  mov        edi, [esp+rfp]
  mov        ebx, [esp+iincr]
;  movq       mm7, [PLUS_384]
  mov        ecx,8
  pxor        mm2,mm2		; clear
%rep 8
  movq       mm0, [edi]		; get dest
  movq	     mm1,mm0		
  punpcklbw  mm0,mm2
  punpckhbw  mm1,mm2
  paddsw     mm0, [esi]
  paddsw     mm1, [esi+8]
;  paddsw     mm0, mm7
;  paddsw     mm1, mm7
  packuswb   mm0,mm1	     
  movq	     [edi], mm0
  add        edi,ebx
  add	     esi,16
%endrep
  emms
  pop        edx
  pop	     ebx
  pop        ecx
  pop        edi
  pop        esi
  ret

  align 16
set_block_mmx:
  push       esi
  push       edi
  push       ecx
  push       ebx
  push       edx
  mov        esi, [esp+bp]
  mov        edi, [esp+rfp]
  mov        ebx, [esp+iincr]
  movq       mm7, [PLUS_128]
%rep 4
  movq       mm0, [esi]
  movq       mm1, [esi+8]
  paddsw     mm0, mm7
  movq       mm2, [esi+16]
  paddsw     mm1, mm7
  movq       mm3, [esi+24]
  paddsw     mm2, mm7
  packuswb   mm0, mm1
  paddsw     mm3, mm7
  movq       [edi], mm0
  packuswb   mm2, mm3
  add        edi, ebx
  add        esi, 32
  movq       [edi], mm2
  add        edi, ebx
%endrep
  emms
  pop        edx
  pop        ebx
  pop        ecx
  pop        edi
  pop        esi
  ret


