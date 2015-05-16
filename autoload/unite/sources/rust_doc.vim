let s:save_cpo = &cpo
set cpo&vim

let s:source = {
    \ 'name' : 'rust/doc',
    \ 'description' : 'Rust documentation in the cargo',
    \ 'default_kind' : 'uri',
    \ 'default_action' : 'start',
    \ }

function! unite#sources#rust_doc#define()
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

function! s:source.gather_candidates(args, context)
    let doc = rust_doc#get_doc_dir(getcwd())
    let identifiers = rust_doc#get_all_module_identifiers(doc)
    return map(identifiers, '{
        \ "word" : s:word_of(v:val),
        \ "action__path" : v:val["path"],
        \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
