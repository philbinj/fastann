;-------------------------------------------------------------------;
; Experimental distance functions in pure assembly.                 ;
;-------------------------------------------------------------------;

;-------------------------------------------------------------------;
; Notes to self: we _can_ trash eax, ecx and edx without saving     ;
; them (plus sse regs). Everything else must be restored.           ;
;-------------------------------------------------------------------;

BITS 32

SECTION .rodata align=16

SECTION .text

;-------------------------------------------------------------------;
; dl2v_2_8_exp(                                                     ;
;                  const double* qu,        esp+0x8                 ;
;                  const double* pnts,      esp+0xc                 ;
;                  unsigned N,              esp+0x10                ;
;                  unsigned D,              esp+0x14                ;
;                  double* dsq_out);        esp+0x18                ;
;-------------------------------------------------------------------;
; Parameters
%define qu      [ebp + 0x8]
%define pnts    [ebp + 0xc]
%define N       [ebp + 0x10]
%define D       [ebp + 0x14]
%define dsq_out [ebp + 0x18]
; Locals
%define local_n       esi
%define local_dsq_out ebx
%define local_d       ecx
%define local_qu      eax
%define local_pntn    edx

global dl2v_2_8_exp
type dl2v_2_8_exp function
size dl2v_2_8_exp dl2v_2_8_exp.endfunc - dl2v_2_8_exp

ALIGN 16
dl2v_2_8_exp:
    push ebp
    mov ebp, esp
    push esi
    push ebx

    ; Quick bail for N=0
    mov local_pntn, pnts
    mov local_dsq_out, dsq_out
    mov local_n, N

    test local_n, local_n
    jmp .end_N_loop
.N_loop:
    mov local_qu, qu
    xorpd xmm4, xmm4     ; acc1 = 0.0
    xorpd xmm5, xmm5     ; acc2 = 0.0
    
    mov local_d, D
    and local_d, -0x8
    jmp .end_D_8_loop
.D_8_loop:
    movlpd xmm0, [local_qu]
    movhpd xmm0, [local_qu + 8]
    movlpd xmm1, [local_pntn]
    movhpd xmm1, [local_pntn + 8]
    movlpd xmm2, [local_qu + 16]
    movhpd xmm2, [local_qu + 24]
    movlpd xmm3, [local_pntn + 16]
    movhpd xmm3, [local_pntn + 24]
    
    subpd xmm0, xmm1
    subpd xmm2, xmm3
    mulpd xmm0, xmm0
    mulpd xmm2, xmm2
    addpd xmm4, xmm0
    addpd xmm5, xmm2

    movlpd xmm0, [local_qu + 32]
    movhpd xmm0, [local_qu + 40]
    movlpd xmm1, [local_pntn + 32]
    movhpd xmm1, [local_pntn + 40]
    movlpd xmm2, [local_qu + 48]
    movhpd xmm2, [local_qu + 56]
    movlpd xmm3, [local_pntn + 48]
    movhpd xmm3, [local_pntn + 56]
    
    subpd xmm0, xmm1
    subpd xmm2, xmm3
    mulpd xmm0, xmm0
    mulpd xmm2, xmm2
    addpd xmm4, xmm0
    addpd xmm5, xmm2

    add local_pntn, 8*8
    add local_qu, 8*8
    sub local_d, 8
.end_D_8_loop:
    jnz .D_8_loop

    mov local_d, D
    and local_d, 0x7
    jz .end_D_loop
.D_loop:
    movsd xmm0, [local_qu]
    subsd xmm0, [local_pntn]
    mulsd xmm0, xmm0
    addsd xmm4, xmm0
    add local_qu, 8
    add local_pntn, 8
    sub local_d, 1
.end_D_loop:
    jnz .D_loop

    ; Sum up the accumulators
    addpd xmm4, xmm5
    movapd xmm5, xmm4
    shufpd xmm5, xmm5, 0x1
    addsd xmm4, xmm5

    movlpd [local_dsq_out], xmm4
    add local_dsq_out, 8
    
    sub local_n, 1
.end_N_loop:
    jnz .N_loop

.all_zero:
    pop ebx
    pop esi
    pop ebp
    ret
.endfunc

;-------------------------------------------------------------------;
; sl2v_2_8_exp(                                                     ;
;                  const float* qu,         esp+0x8                 ;
;                  const float* pnts,       esp+0xc                 ;
;                  unsigned N,              esp+0x10                ;
;                  unsigned D,              esp+0x14                ;
;                  float* dsq_out);         esp+0x18                ;
;-------------------------------------------------------------------;
; Parameters
%define qu      [ebp + 0x8]
%define pnts    [ebp + 0xc]
%define N       [ebp + 0x10]
%define D       [ebp + 0x14]
%define dsq_out [ebp + 0x18]
; Locals
%define local_n       esi
%define local_dsq_out ebx
%define local_d       ecx
%define local_qu      eax
%define local_pntn    edx

global sl2u_2_16_exp
type sl2u_2_16_exp function
size sl2u_2_16_exp sl2u_2_16_exp.endfunc - sl2u_2_16_exp

ALIGN 16
sl2u_2_16_exp:
    push ebp
    mov ebp, esp
    push esi
    push ebx
    
    ; This might help
    ;prefetcht1 [local_qu]
    prefetcht1 [local_pntn]
    
    ; Quick bail for N=0
    mov local_pntn, pnts
    mov local_dsq_out, dsq_out
    mov local_n, N

    test local_n, local_n
    jmp .end_N_loop
.N_loop:
    mov local_qu, qu
    xorps xmm4, xmm4     ; acc1 = 0.0
    xorps xmm5, xmm5     ; acc2 = 0.0
    
    mov local_d, D
    and local_d, -16
    jmp .end_D_16_loop
.D_16_loop:
    prefetcht1 [local_pntn + 32]

    movlps xmm0, [local_qu]
    movhps xmm0, [local_qu + 8]
    movlps xmm1, [local_pntn]
    movhps xmm1, [local_pntn + 8]
    movlps xmm2, [local_qu + 16]
    movhps xmm2, [local_qu + 24]
    movlps xmm3, [local_pntn + 16]
    movhps xmm3, [local_pntn + 24]
    
    subps xmm0, xmm1
    subps xmm2, xmm3
    mulps xmm0, xmm0
    mulps xmm2, xmm2
    
    addps xmm4, xmm0
    addps xmm5, xmm2

    prefetcht1 [local_pntn + 64]
    movlps xmm0, [local_qu + 32]
    movhps xmm0, [local_qu + 40]
    movlps xmm1, [local_pntn + 32]
    movhps xmm1, [local_pntn + 40]
    movlps xmm2, [local_qu + 48]
    movhps xmm2, [local_qu + 56]
    movlps xmm3, [local_pntn + 48]
    movhps xmm3, [local_pntn + 56]
    
    subps xmm0, xmm1
    subps xmm2, xmm3
    mulps xmm0, xmm0
    mulps xmm2, xmm2
    
    addps xmm4, xmm0
    addps xmm5, xmm2

    add local_pntn, 16*4
    add local_qu, 16*4
    sub local_d, 16
.end_D_16_loop:
    jnz .D_16_loop

    mov local_d, D
    and local_d, 15
    jz .end_D_loop
.D_loop:
    movss xmm0, [local_qu]
    subss xmm0, [local_pntn]
    mulss xmm0, xmm0
    addss xmm4, xmm0
    add local_qu, 4
    add local_pntn, 4
    sub local_d, 1
.end_D_loop:
    jnz .D_loop

    ; Sum up the accumulators
    addps xmm4, xmm5
    movaps xmm0, xmm4

    movhlps xmm1, xmm0
    addps xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm0, xmm0, 1
    addss xmm0, xmm1

    movlps [local_dsq_out], xmm0
    add local_dsq_out, 4
    
    sub local_n, 1
.end_N_loop:
    jnz .N_loop

.all_zero:
    pop ebx
    pop esi
    pop ebp
    ret
.endfunc

;-------------------------------------------------------------------;
; dl2v_2_8_exp2(                                                    ;
;                  const double* qu,        esp+0x8                 ;
;                  const double* pnts,      esp+0xc                 ;
;                  unsigned N,              esp+0x10                ;
;                  unsigned D,              esp+0x14                ;
;                  double* dsq_out);        esp+0x18                ;
;                                                                   ;
; The too cool for school edition.                                  ;
; This was acutally slower in the end unless D was large.           ;
;-------------------------------------------------------------------;
; Parameters
%define qu      [ebp + 0x8]
%define pnts    [ebp + 0xc]
%define N       [ebp + 0x10]
%define D       [ebp + 0x14]
%define dsq_out [ebp + 0x18]
; Locals
%define local_n       esi
%define local_dsq_out ebx
%define local_d       ecx
%define local_D       edi
%define local_qu      eax
%define local_pntn    edx

global dl2v_2_8_exp2
type dl2v_2_8_exp2 function
size dl2v_2_8_exp2 dl2v_2_8_exp2.endfunc - dl2v_2_8_exp2

ALIGN 16
dl2v_2_8_exp2:
    push ebp
    mov ebp, esp
    push esi
    push ebx
    push edi

    mov local_pntn, pnts
    mov local_dsq_out, dsq_out
    mov local_n, N

    test local_n, local_n
    jmp .end_N_loop
.N_loop:
    mov local_D, D
    mov local_qu, qu
    xorpd xmm4, xmm4     ; acc1 = 0.0
    xorpd xmm5, xmm5     ; acc2 = 0.0

    ; OK, if they're not both aligned, we try to advance once.
    test local_qu, 0x8
    jnz .advance_one

    test local_pntn, 0x8
    jnz .advance_one

.pre_D_8_A_A_loop:
    mov local_d, local_D
    and local_d, -0x8
    jmp .end_D_8_A_A_loop
.D_8_A_A_loop:
    movapd xmm0, [local_qu]
    movapd xmm1, [local_qu + 16]
    movapd xmm2, [local_qu + 32]
    movapd xmm3, [local_qu + 48]

    subpd xmm0, [local_pntn]
    subpd xmm1, [local_pntn + 16]
    subpd xmm2, [local_pntn + 32]
    subpd xmm3, [local_pntn + 48]

    mulpd xmm0, xmm0
    mulpd xmm1, xmm1
    mulpd xmm2, xmm2
    mulpd xmm3, xmm3

    addpd xmm4, xmm0
    addpd xmm5, xmm1
    addpd xmm4, xmm2
    addpd xmm5, xmm3
    
    add local_pntn, 8*8
    add local_qu, 8*8
    sub local_d, 8
.end_D_8_A_A_loop:
    jnz .D_8_A_A_loop
    jmp .pre_D_loop

.advance_one:
    movsd xmm0, [local_qu]
    subsd xmm0, [local_pntn]
    mulsd xmm0, xmm0
    addsd xmm4, xmm0

    add local_pntn, 8
    add local_qu, 8
    sub local_D, 1

    ;jz .post_D_loop

    test local_qu, 0x8
    jnz .pre_D_8_U_A_loop

    test local_pntn, 0x8
    jnz .pre_D_8_A_U_loop

    jmp .pre_D_8_A_A_loop

.pre_D_8_U_A_loop:
    mov local_d, D
    and local_d, -0x8
    jmp .end_D_8_U_A_loop
.D_8_U_A_loop:
    movlpd xmm0, [local_qu]
    movhpd xmm0, [local_qu + 8]
    movlpd xmm1, [local_qu + 16]
    movhpd xmm1, [local_qu + 24]
    movlpd xmm2, [local_qu + 32]
    movhpd xmm2, [local_qu + 40]
    movlpd xmm3, [local_qu + 48]
    movhpd xmm3, [local_qu + 56]
    
    subpd xmm0, [local_pntn]
    subpd xmm1, [local_pntn + 16]
    subpd xmm2, [local_pntn + 32]
    subpd xmm3, [local_pntn + 48]
    
    mulpd xmm0, xmm0
    mulpd xmm1, xmm1
    mulpd xmm2, xmm2
    mulpd xmm3, xmm3
    
    addpd xmm4, xmm0
    addpd xmm5, xmm1
    addpd xmm4, xmm2
    addpd xmm5, xmm3

    add local_pntn, 8*8
    add local_qu, 8*8
    sub local_d, 8
.end_D_8_U_A_loop:
    jnz .D_8_U_A_loop

    jmp .pre_D_loop


.pre_D_8_A_U_loop:
    mov local_d, D
    and local_d, -0x8
    jmp .end_D_8_A_U_loop
.D_8_A_U_loop:
    movlpd xmm0, [local_pntn]
    movhpd xmm0, [local_pntn + 8]
    movlpd xmm1, [local_pntn + 16]
    movhpd xmm1, [local_pntn + 24]
    movlpd xmm2, [local_pntn + 32]
    movhpd xmm2, [local_pntn + 40]
    movlpd xmm3, [local_pntn + 48]
    movhpd xmm3, [local_pntn + 56]
    
    subpd xmm0, [local_qu]
    subpd xmm1, [local_qu + 16]
    subpd xmm2, [local_qu + 32]
    subpd xmm3, [local_qu + 48]
    
    mulpd xmm0, xmm0
    mulpd xmm1, xmm1
    mulpd xmm2, xmm2
    mulpd xmm3, xmm3
    
    addpd xmm4, xmm0
    addpd xmm5, xmm1
    addpd xmm4, xmm2
    addpd xmm5, xmm3

    add local_pntn, 8*8
    add local_qu, 8*8
    sub local_d, 8
.end_D_8_A_U_loop:
    jnz .D_8_A_U_loop

.pre_D_loop:
    mov local_d, local_D
    and local_d, 0x7
    jmp .end_D_loop
.D_loop:
    movsd xmm0, [local_qu]
    subsd xmm0, [local_pntn]
    mulsd xmm0, xmm0
    addsd xmm4, xmm0
    add local_qu, 8
    add local_pntn, 8
    sub local_d, 1
.end_D_loop:
    jnz .D_loop

.post_D_loop:
    ; Sum up the accumulators
    addpd xmm4, xmm5
    movapd xmm5, xmm4
    shufpd xmm5, xmm5, 0x1
    addsd xmm4, xmm5

    movlpd [local_dsq_out], xmm4
    add local_dsq_out, 8
    
    sub local_n, 1
.end_N_loop:
    jnz .N_loop

.all_zero:
    pop edi
    pop ebx
    pop esi
    pop ebp
    ret
.endfunc
