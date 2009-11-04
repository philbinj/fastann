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
%define local_n     esi
%define local_D     ebx
%define local_D_8   edi
%define local_d     ecx
%define local_qu    eax
%define local_pntn  edx

global dl2v_2_8_exp
type dl2v_2_8_exp function
size dl2v_2_8_exp dl2v_2_8_exp.endfunc - dl2v_2_8_exp

ALIGN 16
dl2v_2_8_exp:
    push ebp
    mov ebp, esp
    push esi
    push ebx
    push edi

    mov local_D, D
    lea local_D, [local_D*8]    ; 8 bytes per double
    mov local_D_8, D            
    and local_D_8, -0x8         ; local_D = D&-8
    lea local_D_8, [local_D_8*8]
    
    mov local_pntn, pnts

    xor local_n, local_n ; n = 0
    jmp .end_N_loop
.N_loop:
    xor local_d, local_d ; d = 0

    mov local_qu, qu
    xorpd xmm4, xmm4     ; acc1 = 0.0
    xorpd xmm5, xmm5     ; acc2 = 0.0
    
    jmp .end_D_8_loop
.D_8_loop:
;    movupd xmm0, [local_qu]
;    movupd xmm1, [local_pntn]
;    movupd xmm2, [local_qu + 2*8]
;    movupd xmm3, [local_pntn + 2*8]
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

    add local_d, 8*8
    add local_pntn, 8*8
    add local_qu, 8*8
.end_D_8_loop:
    cmp local_d, local_D_8
    jl near .D_8_loop

    jmp near .end_D_loop
.D_loop:
    movsd xmm0, [local_qu]
    movsd xmm1, [local_pntn]
    subsd xmm0, xmm1
    mulsd xmm0, xmm0
    addsd xmm4, xmm0
    
    add local_d, 8
    add local_pntn, 8
    add local_qu, 8
.end_D_loop:
    cmp local_d, local_D
    jl near .D_loop

    ; Sum up the accumulators
    addpd xmm4, xmm5
    movapd xmm5, xmm4
    shufpd xmm5, xmm5, 0x1
    addsd xmm4, xmm5

    ; Temporarily hijack local_D
    mov local_D, dsq_out
    movlpd [local_D], xmm4
    add local_D, 8
    mov dsq_out, local_D
    mov local_D, D
    lea local_D, [local_D*8]
    
    add local_n, 0x1
.end_N_loop:
    cmp local_n, N
    jl .N_loop
    
    pop edi
    pop ebx
    pop esi
    pop ebp
    ret
.endfunc

