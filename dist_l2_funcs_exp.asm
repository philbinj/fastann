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
%define local_dsq_out ebx
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

    ; Quick bail for N=0
    mov eax, N
    test eax, eax
    jz .all_zero

    ; Quick bail for D=0

    mov local_pntn, pnts
    mov local_dsq_out, dsq_out

    mov local_n, N
.N_loop:
    mov local_qu, qu
    xorpd xmm4, xmm4     ; acc1 = 0.0
    xorpd xmm5, xmm5     ; acc2 = 0.0
    
    mov local_d, D
    and local_d, -0x8
    jmp near .end_D_8_loop
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
    jnz near .D_8_loop

    mov local_d, D
    and local_d, 0x7
    and local_d, -0x2
    jmp near .end_D_2_loop
.D_2_loop:
    movlpd xmm0, [local_qu]
    movhpd xmm0, [local_qu + 8]
    movlpd xmm1, [local_pntn]
    movhpd xmm1, [local_pntn + 8]
    subpd xmm0, xmm1
    mulpd xmm0, xmm0
    addpd xmm4, xmm0

    add local_qu, 2*8
    add local_pntn, 2*8
    sub local_d, 2
.end_D_2_loop:
    jnz near .D_2_loop

    mov local_d, D
    and local_d, 0x1
    jz .end_D_loop
    movsd xmm0, [local_qu]
    movsd xmm1, [local_pntn]
    subsd xmm0, xmm1
    mulsd xmm0, xmm0
    addsd xmm4, xmm0
    add local_qu, 8
    add local_pntn, 8
    
.end_D_loop:
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

