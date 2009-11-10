;-------------------------------------------------------------------;
; Experimental distance functions in pure assembly.                 ;
;-------------------------------------------------------------------;

;-------------------------------------------------------------------;
; Notes to self: we _can_ trash eax, ecx and edx without saving     ;
; them (plus sse regs). Everything else must be restored.           ;
;-------------------------------------------------------------------;

BITS 64

SECTION .text

;-------------------------------------------------------------------;
; dl2v_2_8_exp(                                                     ;
;                  const double* qu,                                ;
;                  const double* pnts,                              ;
;                  unsigned N,                                      ;
;                  unsigned D,                                      ;
;                  double* dsq_out);                                ;
;-------------------------------------------------------------------;
; Parameters
%define qu      rdi
%define D       ecx
; Locals
%define local_n     edx
%define local_dsq_out r8
%define local_d     eax
%define local_qu    r10
%define local_pntn  rsi

global dl2v_2_8_exp
type dl2v_2_8_exp function
size dl2v_2_8_exp dl2v_2_8_exp.endfunc - dl2v_2_8_exp

ALIGN 16
dl2v_2_8_exp:
    ; Quick bail for N=0
    prefetcht1 [local_pntn]
    test local_n, local_n
    jmp .end_N_loop

.N_loop:
    mov local_qu, qu
    xorpd xmm8, xmm8     ; acc1 = 0.0
    xorpd xmm9, xmm9     ; acc2 = 0.0
    
    mov local_d, D
    and local_d, -0x8
    jmp .end_D_8_loop

.D_8_loop:
    prefetcht1 [local_pntn + 64]
    movupd xmm0, [local_qu]
    movupd xmm1, [local_pntn]
    movupd xmm2, [local_qu + 16]
    movupd xmm3, [local_pntn + 16]
    movupd xmm4, [local_qu + 32]
    movupd xmm5, [local_pntn + 32]
    movupd xmm6, [local_qu + 48]
    movupd xmm7, [local_pntn + 48]
    
    subpd xmm0, xmm1
    mulpd xmm0, xmm0
    addpd xmm8, xmm0
    
    subpd xmm2, xmm3
    mulpd xmm2, xmm2
    addpd xmm9, xmm2
    
    subpd xmm4, xmm5
    mulpd xmm4, xmm4
    addpd xmm8, xmm4
    
    subpd xmm6, xmm7
    mulpd xmm6, xmm6
    addpd xmm9, xmm6

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
    addsd xmm8, xmm0
    add local_qu, 8
    add local_pntn, 8
    sub local_d, 1
.end_D_loop:
    jnz .D_loop

    ; Sum up the accumulators
    addpd xmm8, xmm9
    movapd xmm9, xmm8
    shufpd xmm9, xmm9, 0x1
    addsd xmm8, xmm9

    movlpd [local_dsq_out], xmm8
    add local_dsq_out, 8
    
    sub local_n, 1
.end_N_loop:
    jnz .N_loop

.all_zero:
    ret
.endfunc

;-------------------------------------------------------------------;
; sl2u_2_16_exp(                                                     ;
;                  const float* qu,         esp+0x8                 ;
;                  const float* pnts,       esp+0xc                 ;
;                  unsigned N,              esp+0x10                ;
;                  unsigned D,              esp+0x14                ;
;                  float* dsq_out);         esp+0x18                ;
;-------------------------------------------------------------------;
; Parameters
%define qu      rdi
%define D       ecx
; Locals
%define local_n       edx
%define local_dsq_out r8
%define local_d       eax
%define local_qu      r9
%define local_pntn    rsi

global sl2u_2_16_exp
type sl2u_2_16_exp function
size sl2u_2_16_exp sl2u_2_16_exp.endfunc - sl2u_2_16_exp

ALIGN 16
sl2u_2_16_exp:
    ; This might help
    prefetcht1 [local_pntn]
    
    ; Quick bail for N=0
    test local_n, local_n
    jz .end_N_loop
.N_loop:
    mov local_qu, qu
    xorps xmm8, xmm8     ; acc1 = 0.0
    xorps xmm9, xmm9     ; acc2 = 0.0

    test local_qu, 15
    jnz .pre_D_16_loop

.pre_D_QA_16_loop:
    mov local_d, D
    and local_d, -16
    jmp .end_D_QA_16_loop
.D_QA_16_loop:
    prefetcht1 [local_pntn + 64]
    movups xmm0, [local_pntn]
    movups xmm1, [local_pntn + 16]
    movups xmm2, [local_pntn + 32]
    movups xmm3, [local_pntn + 48]

    subps xmm0, [local_qu]
    subps xmm1, [local_qu + 16]
    subps xmm2, [local_qu + 32]
    subps xmm3, [local_qu + 48]
    
    mulps xmm0, xmm0
    mulps xmm1, xmm1
    mulps xmm2, xmm2
    mulps xmm3, xmm3
    
    addps xmm8, xmm0
    addps xmm9, xmm1
    addps xmm8, xmm2
    addps xmm9, xmm3
    
    add local_pntn, 16*4
    add local_qu, 16*4
    sub local_d, 16
.end_D_QA_16_loop:
    jnz .D_QA_16_loop

    jmp .pre_D_loop
    
.pre_D_16_loop:
    mov local_d, D
    and local_d, -16
    jmp .end_D_16_loop
.D_16_loop:
    prefetcht1 [local_pntn + 64]

    movups xmm0, [local_qu]
    movups xmm1, [local_pntn]
    movups xmm2, [local_qu + 16]
    movups xmm3, [local_pntn + 16]
    movups xmm4, [local_qu + 32]
    movups xmm5, [local_pntn + 32]
    movups xmm6, [local_qu + 48]
    movups xmm7, [local_pntn + 48]
    
    subps xmm0, xmm1
    subps xmm2, xmm3
    subps xmm4, xmm5
    subps xmm6, xmm7
    
    mulps xmm0, xmm0
    mulps xmm2, xmm2
    mulps xmm4, xmm4
    mulps xmm6, xmm6
    
    addps xmm8, xmm0
    addps xmm9, xmm2
    addps xmm8, xmm4
    addps xmm9, xmm6
    
    add local_pntn, 16*4
    add local_qu, 16*4
    sub local_d, 16
.end_D_16_loop:
    jnz .D_16_loop

.pre_D_loop
    mov local_d, D
    and local_d, 15

    test local_d, local_d
    jmp .end_D_loop
.D_loop:
    movss xmm0, [local_qu]
    subss xmm0, [local_pntn]
    mulss xmm0, xmm0
    addss xmm8, xmm0
    add local_qu, 4
    add local_pntn, 4
    sub local_d, 1
.end_D_loop:
    jnz .D_loop

    ; Sum up the accumulators
    addps xmm8, xmm9
    movaps xmm0, xmm8

    ; Suprisingly, haddps actually seems to be slower
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
    ret
.endfunc

