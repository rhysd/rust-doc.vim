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

function! s:source.gather_candidates(args, context) abort
    let hint_dir = expand('%:p:h')
    let docs = rust_doc#get_doc_dirs(hint_dir !=# '' ? hint_dir : getcwd())
    if index(a:args, 'modules') >= 0
        let list = rust_doc#get_modules(docs)
    else
        let list = rust_doc#get_all_module_identifiers(docs)
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
