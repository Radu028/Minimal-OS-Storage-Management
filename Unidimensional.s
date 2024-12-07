.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4
    action_id: .space 4

    storage: .space 1024
    storage_size: .long 1024

    format_input: .asciz "%d"
    format_id_start_end_output: .asciz "%d: (%d, %d)\n"
    format_start_end_output: .asciz "(%d, %d)\n"

    format_test: .asciz "Test\n"
    format_test_nr: .asciz "Test %d\n"

.text

.global main

add:
    pushl %ebp
    movl %esp, %ebp

    # Read how many files to add in N
    pushl $N
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    movl N, %ecx

add_loop:
    cmp $0, %ecx
    je add_end

    # Read file id
    pushl $file_id
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    # Read file dimension
    pushl $file_dimension
    pushl $format_input
    call scanf
    popl %ebx
    popl %ebx

    # Calculate the blocks needed in %eax
    pushl %ecx
    movl file_dimension, %eax
    xorl %edx, %edx
    movl $8, %ecx
    divl %ecx
    popl %ecx
    
    # Ceil for %eax if it is the case, if not skip
    cmp $0, %edx
    je add_skip_ceil

    incl %eax

add_skip_ceil:
    # Find free blocks
    xorl %ecx, %ecx
    movl %eax, %edx

    # %edx = end index for the current file
    decl %edx

add_find_free_space_loop:
    pushl %eax

    movl (%edi, %ecx, 1), %eax
    cmp $0, %eax
    jne add_no_free_block

    popl %eax

    incl %ecx
    cmp %ecx, %edx
    jne add_find_free_space_loop
    je add_found_space_for_this_file
    
add_no_free_block:
    popl %eax

    incl %ecx
    incl %edx

    cmp storage_size, %edx
    # No free space for this file
    je add_repeat_loop

    jmp add_find_free_space_loop

add_found_space_for_this_file:
    # Verify also the current index if it is free
    pushl %eax

    movl (%edi, %ecx, 1), %eax
    cmp $0, %eax
    # No free space for this file
    jne add_repeat_loop

    popl %eax

    # Calculate again the start index in %ecx
    incl %ecx
    subl %eax, %ecx

    movl file_id, %eax

    add_complete_storage_array_with_file_id:
        movb %al, (%edi, %ecx, 1)
        incl %ecx
        cmp %ecx, %edx
    jge add_complete_storage_array_with_file_id

add_repeat_loop:
    decl N
    movl N, %ecx
    
    jmp add_loop

add_end:
    popl %ebp
    ret

get:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax
    movl %eax, file_id

    xorl %ecx, %ecx

    get_search_start_index:
        cmp storage_size, %ecx
        je get_null

        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmp file_id, %dl
        jne get_search_start_index

    # %eax = start index
    movl %ecx, %eax
    decl %eax

    get_seach_end_index:
        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmp file_id, %dl
        je get_seach_end_index

    # %edx = end index
    subl $2, %ecx
    movl %ecx, %edx

    jmp get_end

get_null:
    xorl %eax, %eax
    xorl %edx, %edx

get_end:
    popl %ebp
    ret

delete:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %eax

    pushl %eax
    call get
    popl %ebx

    # %eax = start index, %edx = end index
    movl %eax, %ecx

    delete_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmp %ecx, %edx
        jge delete_loop

delete_end:
    popl %ebp
    ret

defragmentation:
    # Logic:
    # Search for the end index of the first file (a)
    # Search for the start index of the second file (b)
    # If b - a > 1, move the begining of the second file to a + 1

    xorl %ecx, %ecx

defrag_loop:
    pushl %ecx
    call find_next_file
    popl %ebx

    cmp $0, %eax
    je defrag_end

    # %eax = file id
    # %ecx = start index
    # %edx = end index
    pushl %edx
    movl %edx, %ecx
    incl %ecx

    pushl %ecx
    call find_next_file
    popl %ebx

    movl %eax, file_id

    # %ebx = end index of second file
    movl %edx, %ebx

    # %edx = end index of first file, %ecx = start index of second file
    popl %edx
    movl %ecx, %eax
    subl %edx, %eax
    # %eax = difference between end index of first file and start index of second file (number of zeros + 1)

    cmp $1, %eax
    jg defrag_move_file
    
    jmp defrag_loop

defrag_move_file:
    incl %edx

    pushl %eax
    movl file_id, %eax

    defrag_move_file_left_loop:
        movb %al, (%edi, %edx, 1)
        incl %edx
        cmp %ecx, %edx
        jne defrag_move_file_left_loop

    popl %eax

    movl %ebx, %edx
    movl %edx, %ecx
    subl %eax, %ecx
    addl $2, %ecx

    defrag_move_file_right_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmp %ecx, %edx
        jge defrag_move_file_right_loop

    jmp defrag_loop


defrag_end:
    ret

init_storage:
    pushl %ebp
    movl %esp, %ebp

    xorl %ecx, %ecx

    init_storage_loop:
        movb $0, (%edi, %ecx, 1)

        incl %ecx
        cmp storage_size, %ecx
        jne init_storage_loop

    popl %ebp
    ret

# Used for getting next file info: %eax = file id, %ecx = start index, %edx = end index
# Input: %ecx = start index for searching
find_next_file:
    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %ecx

    find_next_file_start_index:
        cmp storage_size, %ecx
        je find_next_file_null

        movb (%edi, %ecx, 1), %al
        incl %ecx
        cmp $0, %al
        je find_next_file_start_index

    end_search_start_index:
        # Push the start index
        pushl %ecx

    find_file_end_index:
        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmp %al, %dl
        je find_file_end_index

    end_search_end_index:
        subl $2, %ecx
        movl %ecx, %edx

    popl %ecx
    decl %ecx
    jmp find_next_file_end

find_next_file_null:
    xorl %eax, %eax
    xorl %ecx, %ecx
    xorl %edx, %edx

find_next_file_end:
    popl %ebp
    ret
    
print_storage:
    xorl %ecx, %ecx

    print_storage_loop:
        pushl %ecx
        call find_next_file
        popl %ebx

        cmp $0, %eax
        je print_storage_end

        # %eax = file id
        # %ecx = start index
        # %edx = end index
        pushl %edx
        pushl %ecx
        pushl %eax
        pushl $format_id_start_end_output
        call printf
        popl %ebx
        popl %eax
        popl %ecx
        popl %edx

        movl %edx, %ecx
        incl %ecx
    jmp print_storage_loop

print_storage_end:
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
    call add

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

    # %eax = start index, %edx = end index
    pushl %edx
    pushl %eax
    pushl $format_start_end_output
    call printf
    popl %ebx
    popl %ebx
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





print_test:
    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx

    pushl $format_test
    call printf
    popl %ebx

    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    ret

print_test_nr:
    pushl %ebp
    movl %esp, %ebp

    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx

    movl 8(%ebp), %eax

    pushl %eax
    pushl $format_test_nr
    call printf
    popl %ebx
    popl %ebx

    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    popl %ebp
    ret
