let s:save_cpo = &cpo
set cpo&vim

let g:rust_doc#vim_open_cmd = get(g:, 'rust_doc#vim_open_cmd', '')
let g:rust_doc#open_cmd = get(g:, 'rust_doc#open_cmd', '')
let g:rust_doc#do_not_ask_for_module_list = get(g:, 'rust_doc#do_not_ask_for_module_list', 0)
let g:rust_doc#define_map_K = get(g:, 'rust_doc#define_map_K', 1)
let g:rust_doc#downloaded_rust_doc_dir = get(g:, 'rust_doc#downloaded_rust_doc_dir', '')

function! s:error(msg) abort
    echohl Error
    echomsg 'rust-doc-open: ' . a:msg
    echohl None
endfunction

function! s:get_hint() abort
    let d = expand('%:p:h')
    return d !=# '' ? d : getcwd()
endfunction

function! rust_doc#find_std_doc_dir() abort
    let d = ''
    if g:rust_doc#downloaded_rust_doc_dir !=# '' && isdirectory(g:rust_doc#downloaded_rust_doc_dir)
        let d = g:rust_doc#downloaded_rust_doc_dir
    endif
    if executable('rustup')
        let index_html = substitute(system('rustup doc --path'), '\n$', '', '')
        if !v:shell_error && filereadable(index_html)
            return fnamemodify(index_html, ':h')
        endif
    endif
    let toolchains_dir = expand('~/.rustup/toolchains/')
    if isdirectory(toolchains_dir)
        let toolchains = s:globpath(toolchains_dir, '*')
        let dirs = filter(copy(toolchains), 'stridx(v:val, "stable-") >= 0')
        if empty(dirs)
            " Fallback to nightly
            let dirs = filter(toolchains, 'stridx(v:val, "nightly-") >= 0')
        endif
        if !empty(dirs)
            let d = dirs[0]
        endif
    endif
    return d . '/share/doc/rust/html/'
endfunction

function! rust_doc#find_rust_project_dir(hint) abort
    let path = fnamemodify(a:hint, ':p')
    if filereadable(path)
        let path = fnamemodify(path, ':h')
    endif

    if !isdirectory(path)
        call s:error('Invalid path: ' . a:hint)
        return ''
    endif

    let cargo = findfile('Cargo.toml', path . ';')

    if cargo ==# ''
        call s:error('Cargo.toml is not found')
        return ''
    endif

    return fnamemodify(cargo, ':h')
endfunction

function! s:open_url(url) abort
    let url = shellescape(a:url)
    if has('win32') || has('win64')
        let cmd = 'rundll32 url.dll,FileProtocolHandler ' . url
    elseif executable('xdg-open') && has('unix')
        let cmd = 'xdg-open ' . url
    elseif executable('open') && has('mac')
        let cmd = 'open ' . url
    elseif executable('google-chrome')
        let cmd = 'google-chrome ' . url
    elseif executable('firefox')
        let cmd = 'firefox ' . url
    else
        call s:error('No command is found to open URL. Please set g:rust_doc#open_cmd')
        return
    endif

    let output = system(cmd)
    if v:shell_error
        call s:error('Failed to open ' . a:url . ': ' . output)
        return
    endif
endfunction

function! s:open(item) abort
    echomsg printf("rust-doc: '%s' is found", a:item.name)

    let url = 'file://' . fnamemodify(a:item.path, ':p')
    if g:rust_doc#vim_open_cmd !=# ''
        execute g:rust_doc#vim_open_cmd url
        return
    endif

    if g:rust_doc#open_cmd !=# ''
        let cmd = g:rust_doc#open_cmd . ' ' . shellescape(url)
        let output = system(cmd)
        if v:shell_error
            call s:error(printf("Failed to open URL '%s' with command '%s': %s", url, cmd, output))
        endif
        return
    endif

    try
        call openbrowser#open(url)
    catch /^Vim\%((\a\+)\)\=:E117/
        call s:open_url(url)
    endtry
endfunction

function! rust_doc#open_denite(path) abort
    let url = 'file://' . fnamemodify(a:path, ':p')
    if g:rust_doc#vim_open_cmd !=# ''
        execute g:rust_doc#vim_open_cmd url
        return
    endif

    if g:rust_doc#open_cmd !=# ''
        let cmd = g:rust_doc#open_cmd . ' ' . shellescape(url)
        let output = system(cmd)
        if v:shell_error
            call s:error(printf("Failed to open URL '%s' with command '%s': %s", url, cmd, output))
        endif
        return
    endif

    try
        call openbrowser#open(url)
    catch /^Vim\%((\a\+)\)\=:E117/
        call s:open_url(url)
    endtry
endfunction

function! rust_doc#get_doc_dirs(hint) abort
    let docs = []

    if g:rust_doc#downloaded_rust_doc_dir !=# ''
        let d = rust_doc#find_std_doc_dir()
        if isdirectory(d)
            let docs += [d]
        endif
    endif

    silent let project_root = rust_doc#find_rust_project_dir(a:hint)
    if project_root ==# ''
        return docs
    endif

    let d = project_root . '/target/doc/'

    if !isdirectory(d)
        echom "'doc' directory is not found. Executing `cargo doc`..."
        !cargo doc
        if v:shell_error
            call s:error('`cargo doc` failed.  Do it manually.')
            return []
        endif
    endif

    if !isdirectory(d)
        call s:error('Document directory is not found')
        return []
    endif

    " Project local documents have higher priority than standard libraries' ones
    let docs = [d] + docs

    return docs
endfunction

if v:version > 704 || (v:version == 704 && has('patch279'))
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
        echomsg 'rust-doc: No module is found'
        return
    endif

    if input("No document was found for '" . a:name . "'. Do you see the list of modules?(Y/n): ") =~? '^y\=$'
        redraw
        for m in a:modules
            echo m.name
        endfor
    endif
endfunction

function! s:open_doc(docs, name) abort
    let modules = rust_doc#get_modules(a:docs)
    for m in modules
        if m.name == a:name
            call s:open(m)
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
        echomsg 'rust-doc: No identifier is found in ' . a:module_name
        return
    endif

    if input("No document was found for '" . name . "'. Do you see the list of identifiers?(Y/n): ") =~? 'y\='
        redraw
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
            call s:open(i)
            return
        endif
    endfor

    call s:show_identifier_list(module.name, identifiers, a:docs, a:identifier)
endfunction

function! rust_doc#open(...) abort
    let docs = rust_doc#get_doc_dirs(s:get_hint())

    if a:0 == 1
        call s:open_doc(docs, a:1)
    elseif a:0 == 2
        call s:open_doc_with_identifier(docs, a:1, a:2)
    else
        call s:error('Wrong number of argument(s): ' . a:0 . ' for 1 or 2')
    endif
endfunction

function! rust_doc#complete_fuzzy_result(...) abort
    if !exists('s:last_fuzzy_candidates')
        return []
    else
        return s:last_fuzzy_candidates
    endif
endfunction

function! s:open_fuzzy(candidates, name) abort
    let found = []
    for c in a:candidates
        if c.name ==# a:name
            " Perfect matching opens the result instantly
            call s:open(c)
            return
        elseif c.name =~# '\<' . a:name . '\>'
            let found += [c]
        endif
    endfor

    if empty(found)
        echomsg "rust-doc: No document is found for '" . a:name . "'"
        return
    endif

    if len(found) == 1
        call s:open(found[0])
        return
    endif

    let s:last_fuzzy_candidates = join(map(copy(found), 'v:key . ": ".v:val["name"]'), "\n")
    let input = input(s:last_fuzzy_candidates . "\n\nSelect number or name in above list: ", '', 'custom,rust_doc#complete_fuzzy_result')
    unlet! s:last_fuzzy_candidates
    redraw
    if input =~# '\v^[0-9]+$' && input >= 0 && input < len(found)
        call s:open(found[input])
        return
    endif
    for f in found
        if f.name == input
            call s:open(f)
            return
        endif
    endfor

    echomsg "rust-doc: No document is found for '" . input . "'"
endfunction

function! rust_doc#open_fuzzy(identifier) abort
    let docs = rust_doc#get_doc_dirs(s:get_hint())
    let identifiers = rust_doc#get_all_module_identifiers(docs)
    call s:open_fuzzy(identifiers, a:identifier)
endfunction

function! rust_doc#open_module(name) abort
    let docs = rust_doc#get_doc_dirs(s:get_hint())
    let modules = rust_doc#get_modules(docs)
    call s:open_fuzzy(modules, a:name)
endfunction

function! rust_doc#complete_cmd(arglead, cmdline, cursorpos) abort
    let args = split(a:cmdline, '\s\+', 1)
    let len = len(args)

    silent let docs = rust_doc#get_doc_dirs(s:get_hint())

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
                if args[2] !=# ''
                    let candidates = filter(candidates, 'stridx(v:val, args[2]) == 0')
                endif
                return sort(candidates)
            endif
        endfor
        return []
    endif

    return []
endfunction

function! rust_doc#complete_module_cmd(arglead, cmdline, cursorpos) abort
    let args = split(a:cmdline, '\s\+', 1)

    silent let docs = rust_doc#get_doc_dirs(s:get_hint())

    if len(args) != 2
        return []
    endif

    let candidates = map(rust_doc#get_modules(docs), 'v:val["name"]')
    if args[1] !=# ''
        let candidates = filter(candidates, 'stridx(v:val, args[1]) == 0')
    endif
    return sort(candidates)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
