if g:rust_doc#define_map_K
    function! s:search_under_cursor(mode)
        try
            let saved_g = getreg('g')
            let saved_g_type = getregtype('g')

            if a:mode ==? 'v'
                normal! `[v`]"gy
            else
                normal! "gyiw
            endif

            let query = getreg('g')
            if query ==# ''
                echomsg "rust-doc: No document is found under the cursor"
                return
            endif

            call rust_doc#open_fuzzy(query)
        finally
            call setreg('g', saved_g, saved_g_type)
        endtry
    endfunction

    nnoremap <buffer><silent>K :<C-u>call <SID>search_under_cursor('n')<CR>
    vnoremap <buffer><silent>K "_y:call <SID>search_under_cursor('v')<CR>
endif
