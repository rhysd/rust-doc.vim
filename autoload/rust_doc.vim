let s:save_cpo = &cpo
set cpo&vim

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

function! s:open()
    " TODO
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

function! s:open_crate(doc, name) abort
    let modules = rust_doc#get_modules(a:doc)
    " TODO
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
        call s:open_crate(doc, a:1)
    elseif a:0 == 2
        call s:open_crate_with_query(doc, a:1, a:2)
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
