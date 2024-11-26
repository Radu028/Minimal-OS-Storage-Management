.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4

    action_id: .space 4
    file_ids: .space 1020

    storage: .space 1024
    storage_size: .long 1024

    ret_array: .space 1024

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

    movl ret_array, %esi

add_loop:
    cmp $0, %ecx
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

    # Calculate the blocks needed
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
    # Find free blocks
    movl storage, %edi

    xorl %ecx, %ecx
    movl %eax, %edx

add_find_loop:
    cmp $0, (%edi, %ecx, 4)
    je add_find_continue
    jne add_no_free_block

add_find_continue:
    incl %ecx
    cmp %ecx, %edx
    jne add_find_loop
    
add_no_free_block:
    cmp storage_size, %edx
    je add_this_ret_false

    incl %ecx
    icnl %edx
    jmp add_find_loop

add_this_ret_false:
    # De completat:
    # adauga in ret_array:
    # 3n: id ul fisierului
    # 3n+1: 0
    # 3n+2: 0

    jmp add_loop

add_end:
    popl %ebp
    ret

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

