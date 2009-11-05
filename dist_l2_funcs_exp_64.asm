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
%define local_qu    r8
%define local_pntn  rsi

global dl2v_2_8_exp
type dl2v_2_8_exp function
size dl2v_2_8_exp dl2v_2_8_exp.endfunc - dl2v_2_8_exp

ALIGN 16
dl2v_2_8_exp:
    ; Quick bail for N=0
    test local_n, local_n
    jz .all_zero

ALIGN 16
.N_loop:
    mov local_qu, qu
    xorpd xmm8, xmm8     ; acc1 = 0.0
    xorpd xmm9, xmm9     ; acc2 = 0.0
    
    mov local_d, D
    and local_d, -0x8
    jmp .end_D_8_loop

ALIGN 16
.D_8_loop:
    movupd xmm0, [local_qu]
    movupd xmm1, [local_pntn]
    movupd xmm2, [local_qu + 16]
    movupd xmm3, [local_pntn + 16]
    
    subpd xmm0, xmm1
    subpd xmm2, xmm3
    mulpd xmm0, xmm0
    mulpd xmm2, xmm2
    addpd xmm8, xmm0
    addpd xmm9, xmm2

    movupd xmm4, [local_qu + 32]
    movupd xmm5, [local_pntn + 32]
    movupd xmm6, [local_qu + 48]
    movupd xmm7, [local_pntn + 48]
    
    subpd xmm4, xmm5
    subpd xmm6, xmm7
    mulpd xmm4, xmm4
    mulpd xmm6, xmm6
    addpd xmm8, xmm0
    addpd xmm9, xmm2

    add local_pntn, 8*8
    add local_qu, 8*8
    sub local_d, 8
.end_D_8_loop:
    jnz .D_8_loop

    mov local_d, D
    and local_d, 0x7
    and local_d, -0x2
    jmp .end_D_2_loop

ALIGN 16
.D_2_loop:
    movupd xmm0, [local_qu]
    movupd xmm1, [local_pntn]
    subpd xmm0, xmm1
    mulpd xmm0, xmm0
    addpd xmm4, xmm0

    add local_qu, 2*8
    add local_pntn, 2*8
    sub local_d, 2
.end_D_2_loop:
    jnz .D_2_loop

    mov local_d, D
    and local_d, 0x1
    jz .end_D_loop
    movsd xmm0, [local_qu]
    movsd xmm1, [local_pntn]
    subsd xmm0, xmm1
    mulsd xmm0, xmm0
    addsd xmm8, xmm0
    add local_qu, 8
    add local_pntn, 8
    
.end_D_loop:
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

