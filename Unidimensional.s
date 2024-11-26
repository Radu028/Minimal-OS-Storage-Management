.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4

    action_id: .space 4
    file_ids: .space 1020
    storage: .space 1024

    format_input: .asciz "%d"

.global main

add:
    pushl %ebp
    movl %esp, %ebp

    pushl $N
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    movl N, %eax
    xorl %edx, %edx
    movl $2, %ecx
    mull %ecx

    movl %eax, %ecx

add_loop:
    cmpl $0, %ecx
    je add_end

    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    pushl $file_dimension
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    # Mark file id as used
    movl file_ids, %edi
    movl $1, (%edi, file_id, 4)

    # Calc the blocks needed
    pushl %ecx
    movl file_dimension, %eax
    xorl %edx, %edx
    movl $8, %ecx
    divl %ecx
    popl %ecx
    
    cmp $0, %edx
    jne add_ceil

    jmp add_skip_ceil

add_ceil
    incl %eax

add_skip_ceil:
    movl %eax, %ecx

    # Find a free blocks
    movl storage, %edi
    


main:
    pushl $O
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    pushl $action_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    cmp $1, action_id
    je et_add

    cmp $2, action_id
    je et_get

    cmp $3, action_id
    je et_delete

    cmp $4, action_id
    je et_defrag

et_add:
    pushl O
    call add
    popl %ebx

