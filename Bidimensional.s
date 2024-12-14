.section .note.GNU-stack,"",@progbits
.data
    O: .space 4
    N: .space 4
    file_id: .space 4
    file_dimension: .space 4
    action_id: .space 4

    find_file_id: .space 4
    find_file_row_start: .space 4
    find_file_row_end: .space 4
    find_file_col_start: .space 4
    find_file_col_end: .space 4
    find_file_start_index: .space 4
    find_file_end_index: .space 4

    add_row: .space 4

    concrete_path: .space 1024
    concrete_slash: .asciz "/"
    concrete_path_slash_buffer: .space 1024
    concrete_path_file_buffer: .space 1024

    concrete_buffer: .space 1024
    concrete_stat_buffer: .space 64

    concrete_null_file_1: .asciz "."
    concrete_null_file_2: .asciz ".."

    storage: .space 1048576
    storage_size: .long 1048576
    rows: .long 1024
    cols: .long 1024

    format_input: .asciz "%d"
    format_id_start_end_output: .asciz "%d: ((%d, %d), (%d, %d))\n"
    format_start_end_output: .asciz "((%d, %d), (%d, %d))\n"
    format_input_concrete: .asciz "%255s"

    format_test: .asciz "Test\n"
    format_test_nr: .asciz "Test: %d\n"
    format_test_str: .asciz "Test: %s\n"
    format_test_new_line: .asciz "\n"
    format_test_slash_zero: .asciz "/0"

    str1: .asciz "ab"
    str2: .asciz "cd"
    result: .space 1024

.text

.global main

convert_blocks_to_add:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = kb

    movl 8(%ebp), %eax
    xorl %edx, %edx
    movl $8, %ecx
    divl %ecx

    cmpl $0, %edx
    je convert_blocks_to_add_end

    incl %eax

convert_blocks_to_add_end:
    popl %ebp
    ret

# Returns %eax = index
calc_index:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = row
    # 12(%ebp) = col

    pushl %edx
    xorl %edx, %edx

    movl 8(%ebp), %eax
    mull cols
    addl 12(%ebp), %eax

    popl %edx

    popl %ebp
    ret

# Returns %eax = row (from 0 to rows - 1) and %edx = col (from 0 to cols - 1)
calc_position:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = index

    movl 8(%ebp), %eax
    xorl %edx, %edx

    movl cols, %ecx
    divl %ecx

    popl %ebp
    ret

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

find_next_file:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = index

    movb $0, find_file_id
    movl $0, find_file_row_start
    movl $0, find_file_row_end
    movl $0, find_file_col_start
    movl $0, find_file_col_end

    xorl %eax, %eax
    movl 8(%ebp), %ecx

    find_next_file_start_index:
        cmp storage_size, %ecx
        je find_next_file_end

        movb (%edi, %ecx, 1), %al
        incl %ecx
        cmp $0, %al
        je find_next_file_start_index

    end_search_start_index:
        movb %al, find_file_id
        xorl %eax, %eax

        decl %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_start_index
        movl %eax, find_file_row_start
        movl %edx, find_file_col_start

        xorl %eax, %eax

    find_file_end_index_tag:
        movb (%edi, %ecx, 1), %al
        incl %ecx
        cmp find_file_id, %al
        je find_file_end_index_tag

    end_search_end_index:
        subl $2, %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_end_index
        movl %eax, find_file_row_end
        movl %edx, find_file_col_end

find_next_file_end:
    popl %ebp
    ret

print_storage:
    xorl %ecx, %ecx

    print_storage_loop:
        pushl %ecx
        call find_next_file
        popl %ebx

        movb find_file_id, %al
        cmp $0, %al
        je print_storage_end

        pushl find_file_col_end
        pushl find_file_row_end
        pushl find_file_col_start
        pushl find_file_row_start
        pushl find_file_id
        pushl $format_id_start_end_output
        call printf
        popl %ebx
        popl %ebx
        popl %ebx
        popl %ebx
        popl %ebx
        popl %ebx

        # Calculate the next index
        pushl find_file_col_end
        pushl find_file_row_end
        call calc_index
        popl %ebx
        popl %ebx

        movl %eax, %ecx
        incl %ecx

    jmp print_storage_loop


print_storage_end:
    ret

strcmp:
    pushl %ebp
    movl %esp, %ebp

    pushl %ebx

    # 8(%ebp) = string 1
    # 12(%ebp) = string 2

    movl 8(%ebp), %esi
    movl 12(%ebp), %edi

    strcmp_loop:
        movb (%esi), %al
        movb (%edi), %bl
        cmpb %al, %bl
        jne strcmp_not_equal
        testb %al, %al
        je strcmp_equal
        incl %esi
        incl %edi
        jmp strcmp_loop

    strcmp_equal:
        xorl %eax, %eax
        jmp strcmp_end

    strcmp_not_equal:
        movl $1, %eax

strcmp_end:
    popl %ebx
    popl %ebp
    ret

concat_strings:
    pushl %ebp
    movl %esp, %ebp

    pushl %ecx
    pushl %edx

    # 8(%ebp) = str1
    # 12(%ebp) = str2
    # 16(%ebp) = result

    movl 16(%ebp), %edi
    movl 8(%ebp), %esi

    concat_strings_copy_string_1:
        movb (%esi), %al
        movb %al, (%edi)
        testb %al, %al
        je concat_strings_copy_string_2
        incl %esi
        incl %edi
        jmp concat_strings_copy_string_1

    concat_strings_copy_string_2:
        movl 12(%ebp), %esi
    concat_strings_copy_string_2_loop:
        movb (%esi), %al
        movb %al, (%edi)
        testb %al, %al
        je concat_strings_end
        incl %esi
        incl %edi
        jmp concat_strings_copy_string_2_loop

concat_strings_end:
    movb $0, (%edi)

    popl %edx
    popl %ecx

    popl %ebp
    ret

add:
    pushl %ebp
    movl %esp, %ebp

    # File id = 8(%ebp)
    # File blocks = 12(%ebp)

    movl $0, add_row
    movl 12(%ebp), %eax

    pushl %eax
    call test_print_nr
    popl %eax

    cmp cols, %eax
    jg add_end

    # Find free blocks
    xorl %ecx, %ecx
    movl %eax, %edx

    # %edx = end index for the current file (for first line)
    decl %edx
    cmp storage_size, %edx
    jge add_end

    xorl %eax, %eax
add_find_free_space_loop:
    movb (%edi, %ecx, 1), %al
    cmp $0, %al
    jne add_no_free_block

    incl %ecx
    cmp %ecx, %edx
    jge add_find_free_space_loop

    jmp add_found_space_for_this_file

add_no_free_block:
    incl %edx
    movl %edx, %eax

    pushl %edx
    xorl %edx, %edx

    movl cols, %ecx
    divl %ecx

    cmp $0, %edx
    je add_no_free_block_next_line_pop

    popl %edx
    # Recalculate the start index in %ecx
    movl %edx, %ecx
    incl %ecx
    subl 12(%ebp), %ecx
    jmp add_find_free_space_loop

add_no_free_block_next_line_pop:
    popl %edx

    incl add_row
    movl add_row, %edx
    cmp rows, %edx
    jge add_end

    # Recalculate the end index in %edx
    pushl 12(%ebp)
    pushl add_row
    call calc_index
    popl %edx
    popl %edx

    movl %eax, %edx
    decl %edx

    jmp add_find_free_space_loop

add_found_space_for_this_file:
    # Calculate again the start index in %ecx
    subl 12(%ebp), %ecx

    # Write the file in the storage
    movb 8(%ebp), %al

    add_found_space_for_this_file_loop:
        movb %al, (%edi, %ecx, 1)
        incl %ecx
        cmp %ecx, %edx
        jge add_found_space_for_this_file_loop

add_end:
    popl %ebp
    ret

get:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = file_id

    movb 8(%ebp), %al

    movl $0, find_file_row_start
    movl $0, find_file_row_end
    movl $0, find_file_col_start
    movl $0, find_file_col_end

    movl $0, find_file_start_index
    movl $0, find_file_end_index

    xorl %ecx, %ecx
    xorl %edx, %edx

    get_find_file_start_index:
        cmp storage_size, %ecx
        je get_end

        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmp %al, %dl
        jne get_find_file_start_index

    get_end_search_start_index:
        decl %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_start_index

        movl %eax, find_file_row_start
        movl %edx, find_file_col_start

        movb 8(%ebp), %al
        xorl %edx, %edx

    get_find_file_end_index:
        movb (%edi, %ecx, 1), %dl
        incl %ecx
        cmp %al, %dl
        je get_find_file_end_index

    get_end_search_end_index:
        subl $2, %ecx
        pushl %ecx
        call calc_position
        popl %ecx

        movl %ecx, find_file_end_index

        movl %eax, find_file_row_end
        movl %edx, find_file_col_end

get_end:
    popl %ebp
    ret

delete:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = file_id

    movb 8(%ebp), %al

    pushl %eax
    call get
    popl %ebx

    movl find_file_start_index, %ecx

    cmpl $0, %ecx
    je delete_end

    delete_loop:
        movb $0, (%edi, %ecx, 1)
        incl %ecx
        cmp find_file_end_index, %ecx
        jle delete_loop

delete_end:
    popl %ebp
    ret

defragmentation:
    xorl %ecx, %ecx
    jmp defragmentation_loop

    defragmentation_loop_pop:
        popl %eax

    defragmentation_loop:
        pushl %ecx
        call find_next_file
        popl %ecx

        movb find_file_id, %al
        cmp $0, %al
        je defragmentation_end

        pushl find_file_row_start
        pushl find_file_end_index
        movl find_file_end_index, %ecx
        incl %ecx

        pushl %ecx
        call find_next_file
        popl %ecx

        movb find_file_id, %al
        cmp $0, %al
        je defragmentation_end_pop

        # %edx = end index of first file
        popl %edx
        movl find_file_start_index, %eax
        subl %edx, %eax # %eax = difference between end index of first file and start index of second file (number of zeros + 1)

        movl find_file_start_index, %ecx

        cmp $1, %eax
        je defragmentation_loop_pop
        
        # %ecx = row index of the first file
        popl %ecx

        # Check if the second file is on the same row and can be moved a few columns to the left
        # OR
        # Check if it is on the next row and can be moved to the current row
        # OR
        # Check if it is on the next row and cannot be moved to the current row, but can be moved a few columns to the left

        cmp find_file_row_start, %ecx
        je defragmentation_same_row
        jl defragmentation_next_row

    defragmentation_same_row:
        # Move the second file to the left
        movl %edx, %ecx # %ecx = End index of the first file

        movl find_file_end_index, %edx
        subl find_file_start_index, %edx
        incl %edx

        addl %ecx, %edx # %edx = End index of the second file's new position

        movb find_file_id, %al
        incl %ecx
        pushl %ecx

        # Fill the space between the two files with second file's id
        defragmentation_move_file_left_loop:
            movb %al, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_move_file_left_loop

        movl find_file_start_index, %ecx
        movl find_file_end_index, %edx

        # Empty the space after the second file
        defragmentation_move_file_right_loop:
            movb $0, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_move_file_right_loop

        popl %ecx
        jmp defragmentation_loop

    defragmentation_next_row:
        # Calculate second file's size in %ecx
        movl find_file_end_index, %ecx
        subl find_file_start_index, %ecx
        incl %ecx

        pushl %edx

        # Calculate the end column index of first file in %eax
        # movl %edx, %eax
        # incl %eax
        # xorl %edx, %edx
        # movl cols, %ecx
        # divl %ecx

        # Or use find_file_col_end
        movl find_file_col_end, %eax
        incl %eax
        movl cols, %edx
        subl %eax, %edx # %edx = number of columns free in the current row

        popl %eax # %eax = end index of first file

        cmp %ecx, %edx
        jl defragmentation_next_row_check_next_row

        # Move the second file to the current row
        
        movl %ecx, %edx # %edx = Second file's size
        movl %eax, %ecx # %ecx = First file's end index
        addl %eax, %edx # %edx = End index of the second file's new position

        movb find_file_id, %al
        incl %ecx
        pushl %ecx

        defragmentation_next_row_move_file_to_current_row_loop:
            movb %al, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_next_row_move_file_to_current_row_loop

        movl find_file_start_index, %ecx
        movl find_file_end_index, %edx

        defragmentation_next_row_empty_space_after_second_file_loop:
            movb $0, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_next_row_empty_space_after_second_file_loop

        popl %ecx
        jmp defragmentation_loop

    defragmentation_next_row_check_next_row:
        movl %eax, %ecx
        movl find_file_col_start, %eax

        cmp $0, %eax
        je defragmentation_loop_continue

        xorl %edx, %edx
        movl find_file_row_start, %eax
        movl cols, %ecx
        mull %ecx # %eax = start index of the current row

        movl find_file_end_index, %edx
        subl find_file_start_index, %edx
        addl %eax, %edx # %edx = end index of the second file's new position

        movl %eax, %ecx
        movb find_file_id, %al
        pushl %ecx

        defragmentation_next_row_check_next_row_left_loop:
            movb %al, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_next_row_check_next_row_left_loop

        movl find_file_start_index, %ecx
        movl find_file_end_index, %edx

        defragmentation_next_row_check_next_row_empty_space_after_second_file_loop:
            movb $0, (%edi, %ecx, 1)
            incl %ecx
            cmp %ecx, %edx
            jge defragmentation_next_row_check_next_row_empty_space_after_second_file_loop

        popl %ecx
        jmp defragmentation_loop

    defragmentation_loop_continue:
        incl %ecx

        jmp defragmentation_loop
        
defragmentation_end_pop:
    # Free the stack from the first file's indexes
    popl %eax
    popl %eax

defragmentation_end:
    ret

concrete:
    pushl %ebp
    movl %esp, %ebp

    # 8(%ebp) = path

    concrete_open_dir:
        # Syscall open
        movl $5, %eax
        leal concrete_path, %ebx
        xorl %ecx, %ecx
        int $0x80

        cmpl $0, %eax
        jl concrete_end

        movl %eax, %edi

    concrete_read_dir:
        # Syscall getdents
        movl $141, %eax
        movl %edi, %ebx
        movl $concrete_buffer, %ecx
        movl $1024, %edx
        int $0x80

        cmp $0, %eax
        jle concrete_end

        addl $concrete_buffer, %eax
        movl $concrete_buffer, %ebx

    concrete_next_entry:
        pushl %eax

        leal 10(%ebx), %ecx  # d_name (entry name)

        pushl %ecx
        call test_print_str
        popl %ecx
        pushl $format_test_new_line
        call test_print_str
        popl %edx

        # Skip if the file is "." or ".."
        pushl $concrete_null_file_1
        pushl %ecx
        call strcmp
        popl %ecx
        popl %edx

        cmp $0, %eax
        je concrete_skip_entry

        pushl $concrete_null_file_2
        pushl %ecx
        call strcmp
        popl %ecx
        popl %edx

        cmp $0, %eax
        je concrete_skip_entry

        # Get the file path
        pushl $concrete_path_slash_buffer
        pushl $concrete_slash
        pushl $concrete_path
        call concat_strings
        popl %eax
        popl %eax
        popl %eax

        leal 10(%ebx), %eax

        pushl $concrete_path_file_buffer
        pushl %eax
        pushl $concrete_path_slash_buffer
        call concat_strings
        popl %eax
        popl %eax
        popl %eax

    concrete_get_file_id:
        # Syscall open (for file id)
        movl $5, %eax
        leal concrete_path_file_buffer, %ebx
        xorl %ecx, %ecx
        int $0x80

        # cmpl $0, %eax
        # jl concrete_end

        movl %eax, %esi

        movl $255, %ecx
        xorl %edx, %edx
        divl %ecx
        incl %edx
        pushl %edx

    concrete_get_file_dimension:
        # Syscall stat (for file dimension)
        movl $108, %eax
        movl %esi, %ebx
        leal concrete_stat_buffer, %ecx
        int $0x80

        # cmp $0, %eax
        # jl concrete_end

        popl %eax

        pushl %ebx
        lea storage, %edi

        pushl 20(%ecx) # st_size (file size)
        pushl %eax # file_id
        call add
        popl %eax
        popl %eax

        call test_print

        popl %ebx

    concrete_skip_entry:
        popl %eax

        xorl %ecx, %ecx
        movw 8(%ebx), %cx # d_reclen (entry length)
        pushl %ecx
        call test_print_nr
        popl %ecx
        addl %ecx, %ebx

        pushl %ebx
        call test_print_nr
        popl %ebx

        pushl %eax
        call test_print_nr
        popl %eax

        cmp %ebx, %eax
        jge concrete_next_entry

concrete_end:
    # call test_print
    popl %ebp
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

    cmp $5, %eax
    je et_concrete

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
        call convert_blocks_to_add
        popl %ebx

        pushl %eax
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

    pushl find_file_col_end
    pushl find_file_row_end
    pushl find_file_col_start
    pushl find_file_row_start
    pushl $format_start_end_output
    call printf
    popl %ebx
    popl %ebx
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

et_concrete:
    pushl $concrete_path
    pushl $format_input_concrete
    call scanf
    popl %ebx
    popl %ebx

    pushl concrete_path
    call concrete
    popl %ebx

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

test_print:
    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx
    pushl %esi
    pushl %edi

    pushl $format_test
    call printf
    popl %ebx

    popl %edi
    popl %esi
    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    ret

test_print_nr:
    pushl %ebp
    movl %esp, %ebp

    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx
    pushl %esi
    pushl %edi

    movl 8(%ebp), %eax
    pushl %eax
    pushl $format_test_nr
    call printf
    popl %ebx
    popl %ebx

    popl %edi
    popl %esi
    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    popl %ebp
    ret

test_print_str:
    pushl %ebp
    movl %esp, %ebp

    pushl %eax
    pushl %ebx
    pushl %ecx
    pushl %edx
    pushl %esi
    pushl %edi

    strlen:
        movl $0, %eax
        movl 8(%ebp), %esi
    strlen_loop:
        cmpb $0, (%esi)
        je strlen_done
        incl %esi
        incl %eax
        jmp strlen_loop
    strlen_done:
        movl %eax, %edx

    movl $4, %eax
    movl $1, %ebx
    movl 8(%ebp), %ecx
    int $0x80

    # movl $4, %eax
    # movl $1, %ebx
    # movl $format_test_new_line, %ecx
    # movl $1, %edx
    # int $0x80

    popl %edi
    popl %esi
    popl %edx
    popl %ecx
    popl %ebx
    popl %eax

    popl %ebp
    ret


