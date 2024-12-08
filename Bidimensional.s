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
    format_id_start_end_output: .asciz "%d: (%d, %d)\n"
    format_start_end_output: .asciz "(%d, %d)\n"

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



