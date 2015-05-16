Open Rust document in your crate in Vim
=======================================

![screenshot](https://raw.githubusercontent.com/rhysd/screenshots/master/rust-doc.vim/rust-doc.vim.gif)
![unite screenshot](https://raw.githubusercontent.com/rhysd/screenshots/master/rust-doc.vim/unite-rust-doc.gif)

`cargo` has a nice feature to generate document.  But it doesn't have a feature to search it.  This plugin searches a document in your crate from Vim.

## Usage

- `:RustDoc` command

```
:RustDoc {crate or module name} [{identifier name}]
```

For example, assume that your crate uses [rand](http://doc.rust-lang.org/rand/rand/index.html).

- `:RustDoc rand` opens the document for crate `rand`.
- `:RustDoc rand::distributions` opens the document for module `rand::distributions`.
- `:RustDoc rand Rng` opens the document for trait `rand::Rng`.

All arguments of the command can be completed.  Please enter `<Tab>` to complete them.

And `:RustDocFuzzy` command is also available to search the argument fuzzily.


- Mapping `K`

Entering key `K` in your Rust source opens a document most corresponding to a word under the cursor in your crate.

`K` mapping is available in normal mode and visual mode.  In normal mode, the word under the cursor is used.  In visual mode, the selected text is used.


- [unite.vim](https://github.com/Shougo/unite.vim) source

```
:Unite rust/doc
```

You can select from all document candidates in your crate with unite.vim interface.



## Installation

If you use some plugin manager, please follow the instruction of them.
For example, you can install this plugin with [neobundle.vim](https://github.com/Shougo/neobundle.vim) as below.

```vim
NeoBundle 'rhysd/rust-doc.vim'
```

If you use no plugin manager, copy all directories and files in `autoload`, `plugin` and `doc` directories to your `~/.vim` directory's corresponding directories.



## Customization

- `g:rust_doc#vim_open_cmd`

Vim command to open the path to a document.  rust-doc.vim uses it to open the document if it is not empty.  The command must take a url to the local file.

- `g:rust_doc#open_cmd`

Shell command to open the path to a document.  rust-doc.vim uses it to open the document if it is not empty.  The command must take a url to the local file.

- `g:rust_doc#do_not_ask_for_module_list`

If the value is `1`, rust-doc.vim never ask if it shows the list of modules/identifiers when no document is found. The default value is `0`.

- `g:rust_doc#define_map_K`

If the value is `1`, `K` mappings described above is defined. The default value is `1`.



## License

This plugin is distributed under [the MIT License](http://opensource.org/licenses/MIT).

```
Copyright (c) 2015 rhysd
```

