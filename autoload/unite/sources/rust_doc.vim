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

function! s:source.gather_candidates(args, context)
    let doc = rust_doc#get_doc_dir(getcwd())
    let identifiers = rust_doc#get_all_module_identifiers(doc)
    return map(identifiers, '{
        \ "word" : v:val["name"],
        \ "action__path" : v:val["path"],
        \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
