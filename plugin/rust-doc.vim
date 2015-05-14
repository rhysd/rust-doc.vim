if (exists('g:loaded_rust_doc') && g:loaded_rust_doc) || &cp
    finish
endif

command! -nargs=+ -complete=customlist,rust_doc#complete_cmd OpenRustDoc call rust_doc#open(<q-args>)

let g:loaded_rust_doc = 1
