let s:save_cpo = &cpo
set cpo&vim

let g:rust_doc#vim_open_cmd = get(g:, 'rust_doc#vim_open_cmd', '')
let g:rust_doc#open_cmd = get(g:, 'rust_doc#open_cmd', '')
let g:rust_doc#do_not_ask_for_module_list = get(g:, 'rust_doc#do_not_ask_for_module_list', 0)
let g:rust_doc#define_map_K = get(g:, 'rust_doc#define_map_K', 1)
let g:rust_doc#downloaded_rust_doc_dir = get(g:, 'rust_doc#downloaded_rust_doc_dir', '')
let g:rust_doc#do_not_cache = get(g:, 'rust_doc#do_not_cache', '')

function! s:error(msg) abort
    echohl Error
    echomsg "rust-doc-open: " . a:msg
    echohl None
endfunction

function! rust_doc#find_rust_project_dir(hint) abort
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

function! s:open(url) abort
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
        elseif executable('xdg-open') && has('unix')
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

function! rust_doc#get_doc_dirs(hint) abort
    let docs = []

    if g:rust_doc#downloaded_rust_doc_dir !=# ''
        let d = expand(g:rust_doc#downloaded_rust_doc_dir . '/share/doc/rust/html/')
        if isdirectory(d)
            let docs += [d]
        endif
    endif

    let project_root = rust_doc#find_rust_project_dir(a:hint)
    if project_root ==# ''
        return docs
    endif

    let d = project_root . '/target/doc/'

    if !isdirectory(d)
        echom "'doc' directory is not found. Executing `cargo doc`..."
        !cargo doc
        if v:shell_error
            call s:error("`cargo doc` failed.  Do it manually.")
            return []
        endif
    endif

    if !isdirectory(d)
        call s:error("Document directory is not found")
        return []
    endif

    " Project local documents have higher priority than standard libraries' ones
    let docs = [d] + docs

    return docs
endfunction

if v:version > 703 || (v:version == 703 && has('patch465'))
    function! s:globpath(dir, pattern) abort
        return globpath(a:dir, a:pattern, 1, 1)
    endfunction
else
    function! s:globpath(dir, pattern) abort
        return split(globpath(a:dir, a:pattern, 1), '\n')
    endfunction
endif

function! rust_doc#get_modules(docs) abort
    let modules = []

    for doc in a:docs
        let paths = s:globpath(doc, '**/index.html')
        let modules += map(paths, "{
                    \   'path' : v:val,
                    \   'name' : substitute(fnamemodify(v:val, ':h')[strlen(doc) : ], '/', '::', 'g'),
                    \ }")
    endfor

    return modules
endfunction

function! rust_doc#get_identifiers(module_html_path) abort
    let module_dir = fnamemodify(a:module_html_path, ':p:h')
    if !isdirectory(module_dir)
        call s:error("Invalid path: " . module_dir)
        return []
    endif

    let htmls = split(glob(module_dir . '/*.*.html'), "\n")
    return map(htmls, "{
            \   'path' : v:val,
            \   'name' : matchstr(fnamemodify(v:val, ':t'), '^[^.]*\\.\\zs.\\+\\ze\\.html'),
            \ }")
endfunction

function! rust_doc#get_all_module_identifiers(docs) abort
    let ret = []
    for m in rust_doc#get_modules(a:docs)
        let ret += [m]
        let identifiers = rust_doc#get_identifiers(m.path)
        for i in identifiers
            let i.name = m.name . '::' . i.name
        endfor
        let ret += identifiers
    endfor

    return ret
endfunction

function! s:show_module_list(modules, docs, name) abort
    if g:rust_doc#do_not_ask_for_module_list
        call s:error(printf("No document was found for '%s'. Document dir(s): %s", a:name, string(a:docs)))
        return
    endif

    if empty(a:modules)
        echomsg "No module is found"
        return
    endif

    if input("No document was found for '" . a:name . "'. Do you see the list of modules?(Y/n): ") =~? '^y\=$'
        for m in a:modules
            echo m.name
        endfor
    endif
endfunction

function! s:open_doc(docs, name) abort
    let modules = rust_doc#get_modules(a:docs)
    for m in modules
        if m.name == a:name
            call s:open(m.path)
            return
        endif
    endfor

    call s:show_module_list(modules, a:docs, a:name)
endfunction

function! s:show_identifier_list(module_name, identifiers, docs, name) abort
    let name = a:module_name . '::' . a:name
    if g:rust_doc#do_not_ask_for_module_list
        call s:error(printf("No document was found for '%s'. Document dirs: %s", name, string(a:docs)))
        return
    endif

    if empty(a:identifiers)
        echomsg "No identifier is found in " . a:module_name
        return
    endif

    if input("No document was found for '" . name . "'. Do you see the list of identifiers?(Y/n): ") =~? 'y\='
        for i in a:identifiers
            echo a:module_name . '::' . i.name
        endfor
    endif
endfunction

function! s:open_doc_with_identifier(docs, name, identifier) abort
    let all_modules = rust_doc#get_modules(a:docs)
    let modules = filter(copy(all_modules), 'v:val["name"] == a:name')
    if empty(modules)
        call s:show_module_list(all_modules, a:docs, a:name)
        return
    endif

    let module = modules[0]

    let identifiers = rust_doc#get_identifiers(module.path)
    for i in identifiers
        if i.name == a:identifier
            call s:open(i.path)
            return
        endif
    endfor

    call s:show_identifier_list(module.name, identifiers, a:docs, a:identifier)
endfunction

function! rust_doc#open(...) abort
    let docs = rust_doc#get_doc_dirs(getcwd())
    if docs ==# []
        return
    endif

    if a:0 == 1
        call s:open_doc(docs, a:1)
    elseif a:0 == 2
        call s:open_doc_with_identifier(docs, a:1, a:2)
    else
        call s:error("Wrong number of argument(s): " . a:0 . " for 1 or 2")
    endif
endfunction

function! rust_doc#complete_fuzzy_result(...) abort
    if !exists('s:last_fuzzy_candidates')
        return []
    else
        return s:last_fuzzy_candidates
    endif
endfunction

function! rust_doc#open_fuzzy(identifier) abort
    let docs = rust_doc#get_doc_dirs(getcwd())
    if docs ==# []
        return
    endif

    let identifiers = rust_doc#get_all_module_identifiers(docs)

    let found = []
    for i in identifiers
        if i.name ==# a:identifier
            " Perfect matching opens the result instantly
            call s:open(i.path)
            return
        elseif i.name =~# '\<' . a:identifier . '\>'
            let found += [i]
        endif
    endfor

    if empty(found)
        echomsg "No document is found for '" . a:identifier . "'"
        return
    endif

    if len(found) == 1
        call s:open(found[0].path)
        return
    endif

    let s:last_fuzzy_candidates = join(map(copy(found), 'v:val["name"]'), "\n")
    let input = input(s:last_fuzzy_candidates . "\n\nSelect one in above list: ", '', 'custom,rust_doc#complete_fuzzy_result')
    for f in found
        if f.name == input
            call s:open(f.path)
            return
        endif
    endfor

    echomsg "No document is found for '" . input . "'"
endfunction

function! rust_doc#complete_cmd(arglead, cmdline, cursorpos) abort
    let args = split(a:cmdline, '\s\+', 1)
    let len = len(args)

    silent let docs = rust_doc#get_doc_dirs(getcwd())
    if docs ==# []
        return []
    endif

    if len == 2
        " Complete module name
        let candidates = map(rust_doc#get_modules(docs), 'v:val["name"]')
        if len == 2
            let candidates = filter(candidates, 'stridx(v:val, args[1]) == 0')
        endif
        return sort(candidates)
    elseif len == 3
        " Complete query name
        for m in rust_doc#get_modules(docs)
            if m.name == args[1]
                let candidates = map(rust_doc#get_identifiers(m.path), 'v:val["name"]')
                if args[2] != ''
                    let candidates = filter(candidates, 'stridx(v:val, args[2]) == 0')
                endif
                return sort(candidates)
            endif
        endfor
        return []
    endif

    return []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
