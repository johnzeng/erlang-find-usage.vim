let s:erlang_local_func_beg = '^\s*[a-z][a-zA-Z0-9_]*(.*) ->'

function! s:FindFun(word)
    let match_res = match(a:word, ":")
    let loclist = []
    if match_res == -1
        let full_file_name = expand("%")
        let file_name = expand('%:t:h')
        let module_name_list = split(file_name, '\.')
        let module_name = module_name_list[0]
        let fun_name = a:word
        let lines = getline(0, '$')
        let j = 1
        let search_reg = '\<'.fun_name.'\>'

        for i in lines
            if i =~ search_reg
                call add(loclist, full_file_name.":".j.":".i)
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
            call add(loclist, module_file.":".i)
        endfor
    endif

    let ag_result = system("ag '\\b".module_name.":".fun_name."\\b'")
    let ag_list  = split(ag_result, '\n')
    for i in ag_list
        call add(loclist, i)
    endfor

    cgete loclist
    if len(loclist) > 0
        exec "copen"
    endif

endfunction

function! s:FindVar(word)
    let end_line = search(s:erlang_local_func_beg)
    let begin = search(s:erlang_local_func_beg, 'b')
    if begin > 0
        let begin = begin - 1
    endif

    if end_line > 0
        let end_line = end_line - 2
    else
        let end_line = line("$")
    endif

    let search_reg = '\<'.a:word.'\>'
    let j = begin
    let loclist = []

    let lines = getline(begin, end_line)
    let current_file_name = expand('%')

    for i in lines
        if i =~ search_reg
            call add(loclist, current_file_name.":".j.":".i)
        endif
        let j = j + 1
    endfor

	cgete loclist
	if len(loclist) > 0
		exec "copen"
	endif

endfunction

function! s:FindMacroOrRecord(word)
    let loclist = []
    if a:word[0] == '?'
        let ag_cmd = "ag '\\".a:word."\\b'"
    else
        let ag_cmd = "ag '".a:word."\\b'"
    endif
    let ag_result = system(ag_cmd)
    let ag_list  = split(ag_result, '\n')
    for i in ag_list
        call add(loclist, i)
    endfor

    cgete loclist
    if len(loclist) > 0
        exec "copen"
    endif
endfunc

function! s:FindUsageUnderCursor()
    let orig_isk = &isk
    set isk+=:
    normal "_viwo
    let curr_line = getline('.')
    if curr_line[col('.') - 2] =~# '[#?]'
        normal h
    endif

    let begin_index = col('.') - 1
    normal o
    let end_index = col('.')

    let to_find_word = strpart(curr_line, begin_index, end_index - begin_index)


    let to_find = 0
    if(to_find_word[0] <= 'Z' && 'A' <= to_find_word[0])
        let to_find = 1
    elseif(to_find_word[0] == '_')
        let to_find = 1
    elseif(to_find_word[0] == '?' || to_find_word[0] == '#')
        let to_find = 2
    endif

    let &isk = orig_isk
    if(to_find == 1)
        return s:FindVar(to_find_word)
    elseif(to_find == 2)
        return s:FindMacroOrRecord(to_find_word)
    else
        return s:FindFun(to_find_word)
    endif
endfunction

command! -nargs=0 FindErlangUsage :call <SID>FindUsageUnderCursor()
