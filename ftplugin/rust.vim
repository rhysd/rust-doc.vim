if g:rust_doc#define_map_K
    function! s:search_under_cursor(query) range
        if a:query ==# ''
            echomsg 'rust-doc: No identifier is found under the cursor'
            return
        endif

        call rust_doc#open_fuzzy(a:query)
    endfunction

    nnoremap <buffer><silent>K :<C-u>call <SID>search_under_cursor(expand('<cword>'))<CR>
    vnoremap <buffer><silent>K "gy:call <SID>search_under_cursor(getreg('g'))<CR>
endif
