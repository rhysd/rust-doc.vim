if (exists('g:loaded_rust_doc') && g:loaded_rust_doc) || &cp
    finish
endif

command! -nargs=+ -complete=customlist,rust_doc#complete_cmd RustDoc call rust_doc#open(<f-args>)
command! -nargs=1 RustDocFuzzy call rust_doc#open_fuzzy(<f-args>)
command! -nargs=1 -complete=customlist,rust_doc#complete_module_cmd RustDocModule call rust_doc#open_module(<f-args>)

let g:loaded_rust_doc = 1
