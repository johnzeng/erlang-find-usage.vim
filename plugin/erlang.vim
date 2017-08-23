let s:erlang_local_func_beg = '^\s*[a-z][a-zA-Z0-9_]*(.*) ->'
let s:erlang_local_func_end = '\.$'

function! s:FindFun(word)
    let match_res = match(a:word, ":")
    let loclist = []
    if match_res == -1
        let file_name = expand('#:t:h')
        let module_name_list = split(file_name, '\.')
        let module_name = module_name_list[0]
        let fun_name = a:word
        let lines = getline(0, '$')
        let j = 1
        let search_reg = '\<'.fun_name.'\>'

        for i in lines
            if i =~ search_reg
                let item = {'filename' : expand('%'), 'lnum' : j, 'text' : i}
                call add(loclist, item)
            endif
            let j = j + 1
        endfor

    else
        let [module_name, fun_name] = split(a:word, ":")
        let module_file_result = system("find . -name ".module_name.".erl")
        let module_file_result_list = split(module_file_result, '\n')
        let module_file = module_file_result_list[0]

        let ag_cmd = "ag '\\b".fun_name."\\b' ".module_file
        let module_ag_result = system(ag_cmd)
        let module_ag_result_list  = split(module_ag_result, '\n')
        for i in module_ag_result_list
            let split_list = split(i, ':')
            let item = {'filename' : module_file, 'lnum' : split_list[0], 'text' : join(split_list[1: -1], ":")}
            call add(loclist, item)
        endfor
    endif

    let ag_result = system('ag '.module_name.':'.fun_name)
    let ag_list  = split(ag_result, '\n')
    for i in ag_list
        let split_list = split(i, ':')
        let item = {'filename' : split_list[0], 'lnum' : split_list[1], 'text' : join(split_list[2: -1], ":")}
        call add(loclist, item)
    endfor

    call setloclist(0, loclist)
    if len(loclist) > 0
        exec "lopen"
    endif

endfunction

function! s:FindVar(word)
    let end_line = search(s:erlang_local_func_end)
    let begin = search(s:erlang_local_func_beg, 'b')

    let search_reg = '\<'.a:word.'\>'
    let j = begin
    let loclist = []

    let lines = getline(begin, end_line)

    for i in lines
        if i =~ search_reg
            let item = {'filename' : expand('%'), 'lnum' : j, 'text' : i}
            call add(loclist, item)

        endif
        let j = j + 1
    endfor

	call setloclist(0, loclist)
	if len(loclist) > 0
		exec "lopen"
	endif

endfunction

function! s:FindUsageUnderCursor()
    let orig_isk = &isk
    set isk+=:
    normal "_viwo
    let curr_line = getline('.')
    if curr_line[col('.') - 2] =~# '[#?]'
        normal h
    endif

    let begin_index = col('.') - 1
    normal o\<Esc>
    let end_index = col('.') 

    let to_find_word = strpart(curr_line, begin_index, end_index - begin_index)


    let to_find = 0
    if(to_find_word[0] <= 'Z' && 'A' <= to_find_word[0])
        let to_find = 1
    elseif(to_find_word[0] == '_')
        let to_find = 1
    elseif(to_find_word[0] == '?')
        let to_find = 0
    endif

    if(to_find == 1)
        return s:FindVar(to_find_word)
    else
        return s:FindFun(to_find_word)
    endif
endfunction

command! -nargs=0 FindErlangUsage :call <SID>FindUsageUnderCursor()
au BufEnter *.erl,*.hrl :nmap <C-s>s :FindErlangUsage<CR>
