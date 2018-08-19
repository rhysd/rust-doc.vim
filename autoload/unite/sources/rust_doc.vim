let s:save_cpo = &cpo
set cpo&vim

let s:source = {
    \ 'name' : 'rust/doc',
    \ 'description' : 'Rust documentation',
    \ 'default_kind' : 'uri',
    \ 'default_action' : 'start',
    \ 'syntax' : 'uniteSource__rust_doc',
    \ 'hooks' : {},
    \ }

function! unite#sources#rust_doc#define() abort
    return s:source
endfunction

function! s:tag_of(identifier) abort
    let html = fnamemodify(a:identifier.path, ':t')
    if html ==# 'index.html'
        return ''
    endif
    return matchstr(html, '^[^.]\+\ze.\+\.html$')
endfunction

function! s:word_of(identifier) abort
    let tag = s:tag_of(a:identifier)
    if tag !=# ''
        return printf('%s [%s]', a:identifier.name, tag)
    else
        return a:identifier.name
    endif
endfunction

function! s:filter_by(name, list) abort
    if a:name ==# ''
        echohl ErrorMsg | echomsg 'No identifier found under cursor' | echohl None
        return []
    endif
    return filter(a:list, 'v:val.name =~# ''\<'' . a:name . ''\>''')
endfunction

function! s:source.gather_candidates(args, context) abort
    let hint_dir = expand('%:p:h')
    let docs = rust_doc#get_doc_dirs(hint_dir !=# '' ? hint_dir : getcwd())
    if index(a:args, 'modules') >= 0
        let list = rust_doc#get_modules(docs)
    else
        let list = rust_doc#get_all_module_identifiers(docs)
    endif
    if index(a:args, 'cursor') >= 0
        let list = s:filter_by(expand('<cword>'), list)
    elseif index(a:args, 'visual') >= 0
        let s = getpos("'<")[1:2]
        let e = getpos("'>")[1:2]
        if s == [0, 0] || e == [0, 0]
            echohl ErrorMsg | echomsg 'Nothing was visually selected' | echohl None
            return []
        endif
        if s[0] !=# e[0]
            echohl ErrorMsg | echomsg 'multi-lines were selected' | echohl None
        endif
        let list = s:filter_by(getline(s[0])[s[1]-1 : e[1]-1], list)
    endif
    return map(list, '{
        \ "word" : s:word_of(v:val),
        \ "action__path" : v:val["path"],
        \ }')
endfunction

function! s:source.hooks.on_syntax(args, context) abort
    syntax match uniteSource__rust_doc_Identifier /\%(::\)\@<=\h\w*\>\%(\s*\[\)\@=/ contained containedin=uniteSource__rust_doc display
    syntax match uniteSource__rust_doc_Tag /\[\h\w*\]/ contained containedin=uniteSource__rust_doc display
    highlight default link uniteSource__rust_doc_Identifier Identifier
    highlight default link uniteSource__rust_doc_Tag Tag
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
