let s:save_cpo = &cpo
set cpo&vim

let g:rust_doc#vim_open_cmd = get(g:, 'rust_doc#vim_open_cmd', '')
let g:rust_doc#open_cmd = get(g:, 'rust_doc#open_cmd', '')
let g:rust_doc#do_not_ask_for_module_list = get(g:, 'rust_doc#do_not_ask_for_module_list', 0)

function! s:error(msg) abort
    echohl Error
    echomsg "rust-doc-open: " . a:msg
    echohl None
endfunction

function! rust_doc#find_rust_project_dir(hint)
    let path = fnamemodify(a:hint, ':p')
    if filereadable(path)
        let path = fnamemodify(path, ':h')
    endif

    if !isdirectory(path)
        call s:error("Invalid path: " . a:hint)
        return ''
    endif

    let cargo = findfile('Cargo.toml', path . ';')

    if cargo ==# ''
        call s:error("Cargo.toml is not found")
        return ''
    endif

    return fnamemodify(cargo, ':h')
endfunction

function! s:open(url)
    if g:rust_doc#vim_open_cmd != ''
        execute g:rust_doc#vim_open_cmd a:url
        return
    endif

    if g:rust_doc#open_cmd != ''
        let output = system(g:rust_doc#open_cmd . ' ' . a:url)
        if v:shell_error
            call s:error("Failed to open URL: " . output)
        endif
        return
    endif

    try
        call openbrowser#open(a:url)
    catch /^Vim\%((\a\+)\)\=:E117/
        if has('win32') || has('win64')
            let cmd = 'rundll32 url.dll,FileProtocolHandler ' . a:url
        elseif executable('xdg-open')
            let cmd = 'xdg-open ' . a:url
        elseif executable('open') && has('mac')
            let cmd = 'open ' . a:url
        elseif executable('google-chrome')
            let cmd = 'google-chrome ' . a:url
        elseif executable('firefox')
            let cmd = 'firefox ' . a:url
        else
            call s:error("No command is found to open URL. Please set g:rust_doc#open_cmd")
            return
        endif
        let output = system(cmd)
        if v:shell_error
            call s:error("Failed to open URL: " . output)
        endif
    endtry

    " TODO
    " Open the url in Vim via html2text
endfunction

function! s:doc_dir(project_root) abort
    let d = a:project_root . '/target/doc/'

    if !isdirectory(d)
        echom "'doc' directory is not found. Executing `cargo doc`..."
        !cargo doc
        if v:shell_error
            call s:error("`cargo doc` failed.  Do it manually.")
            return ''
        endif
    endif

    if !isdirectory(d)
        call s:error("Document directory is not found")
        return ''
    endif

    return d
endfunction

function! rust_doc#get_modules(doc) abort
    let paths = split(globpath(a:doc, '**/index.html'), "\n")
    return map(paths, "{
                \   'path' : v:val,
                \   'name' : substitute(fnamemodify(v:val, ':h')[strlen(a:doc) : ], '/', '::', 'g'),
                \ }")
endfunction

function! s:open_crate_doc(doc, name) abort
    let modules = rust_doc#get_modules(a:doc)
    for m in modules
        if m.name == a:name
            call s:open(m.path)
            return
        endif
    endfor

    if g:rust_doc#do_not_ask_for_module_list
        call s:error(printf("No document was found for '%s'. Document dir was '%s'", a:name, a:doc))
        return
    endif

    if input("No document was found. Do you see the list of modules?(Y/n): ") =~? 'y\='
        for m in modules
            echo m.name
        endfor
    endif
endfunction

function! rust_doc#open(...)
    let project = rust_doc#find_rust_project_dir(getcwd())
    if project ==# ''
        return
    endif

    let doc = s:doc_dir(project)
    if doc ==# ''
        return
    endif

    if a:0 == 1
        call s:open_crate_doc(doc, a:1)
    elseif a:0 == 2
        call s:open_crate_doc_with_query(doc, a:1, a:2)
    else
        call s:error("Wrong number of argument(s): " . a:0 . " for 1 or 2")
    endif
endfunction

function! rust_doc#complete_cmd(arglead, cmdline, cursorpos)
    let args = split(a:cmdline, '\s\+')
    let len = len(args)

    silent let project = rust_doc#find_rust_project_dir(getcwd())
    if project ==# ''
        return []
    endif

    silent let doc = s:doc_dir(project)
    if doc ==# ''
        return []
    endif

    if len <= 2
        " Complete module name
        let candidates = map(rust_doc#get_modules(doc), 'v:val["name"]')
        if len == 2
            let candidates = filter(candidates, 'stridx(v:val, args[1]) == 0')
        endif
        return sort(candidates)
    elseif len == 3
        " Complete query name
        return []
    endif

    return []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
