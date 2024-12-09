.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4
    action_id: .space 4

    storage: .space 1024
    rows: .long 32
    cols: .long 32

    format_input: .asciz "%d"
    format_id_start_end_output: .asciz "%d: ((%d, %d), (%d, %d))\n"
    format_start_end_output: .asciz "((%d, %d), (%d, %d))\n"

    format_test: .asciz "Test\n"
    format_test_nr: .asciz "Test %d\n"

.text

.global main

init_storage:
    movl rows, %eax
    mull cols
    decl %eax
    xorl %ecx, %ecx

    init_storage_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmp %eax, %ecx
        jle init_storage_loop

    ret
        

main:
    lea storage, %edi
    call init_storage

    pushl $O
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

et_do_action:
    pushl $action_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    movl action_id, %eax

    cmp $1, %eax
    je et_add

    cmp $2, %eax
    je et_get

    cmp $3, %eax
    je et_delete

    cmp $4, %eax
    je et_defrag

et_add:
    pushl $N
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    et_add_loop:
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

        pushl file_dimension
        pushl file_id
        call add
        popl %ebx
        popl %ebx

        decl N
        movl N, %ecx

        cmp $0, %ecx
        jne et_add_loop


    call print_storage

    jmp et_decl_O

et_get:
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    pushl file_id
    call get
    popl %ebx

    jmp et_decl_O

et_delete:
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    pushl file_id
    call delete
    popl %ebx

    call print_storage

    jmp et_decl_O

et_defrag:
    call defragmentation

    call print_storage

    jmp et_decl_O

et_decl_O:
    decl O
    movl O, %eax

    cmp $0, %eax
    je et_exit
    jne et_do_action

et_exit:
    pushl $0
    call fflush
    popl %eax

    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80

