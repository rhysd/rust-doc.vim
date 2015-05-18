Open Rust document in Vim
=======================================

![screenshot](https://raw.githubusercontent.com/rhysd/screenshots/master/rust-doc.vim/rust-doc.vim.gif)
![unite screenshot](https://raw.githubusercontent.com/rhysd/screenshots/master/rust-doc.vim/unite-rust-doc.gif)

`cargo` has a nice feature to generate document.  But it doesn't have a feature to search it yet.  This plugin searches documents (standard libraries, libraries your crate depends on, and so on) from Vim.

## Usage

- __`:RustDoc` command__

```
:RustDoc {crate or module name} [{identifier name}]
```

For example, assume that your crate uses [rand](http://doc.rust-lang.org/rand/rand/index.html).

1. `:RustDoc rand` opens the document for crate `rand`.
2. `:RustDoc rand::distributions` opens the document for module `rand::distributions`.
3. `:RustDoc rand Rng` opens the document for trait `rand::Rng`.

All arguments of the command can be completed.  Please enter `<Tab>` to complete them.

Of course you can search standard libraries.

```
:RustDoc std::vec
```

And `:RustDocFuzzy` command is also available to search the argument fuzzily.


- __Mapping `K`__

Entering key `K` in your Rust source opens a document most corresponding to a word under the cursor.

`K` mapping is available in normal mode and visual mode.  In normal mode, the word under the cursor is used.  In visual mode, the selected text is used.


- __[unite.vim](https://github.com/Shougo/unite.vim) source__

```
:Unite rust/doc
```

You can select from all document candidates with unite.vim interface.

It may takes some time to prepare candidates.  If you don't want to wait and it is enough for you to search only module names, please specify `modules` to the argument of `rust/doc` source as below.

```
:Unite rust/doc:modules
```


## Installation

### 1. Install This Plugin

If you use some plugin manager, please follow the instruction of them.
For example, you can install this plugin with [neobundle.vim](https://github.com/Shougo/neobundle.vim) as below.

```vim
NeoBundle 'rhysd/rust-doc.vim'
```

If you use no plugin manager, copy all directories and files in `autoload`, `plugin` and `doc` directories to your `~/.vim` directory's corresponding directories.

### 2. Setup Standard Library Documents

If you want to see standard library documents, you must set `g:rust_doc#downloaded_rust_doc_dir`.
The variable should be string type and contain the path to rust documents bundled in downloaded rust tar.

__e.g.__:

```sh
$ wget https://static.rust-lang.org/dist/rust-1.0.0-i686-unknown-linux-gnu.tar.gz
$ tar xf rust-1.0.0-i686-unknown-linux-gnu.tar.gz
$ mv rust-1.0.0-i686-unknown-linux-gnu/rust-doc ~/Documents/
```

Then set the variable as below

```vim
let g:rust_doc#downloaded_rust_doc_dir = '~/Documents/rust-doc'
```



## Customization

- `g:rust_doc#vim_open_cmd`

Vim command to open the path to a document.  rust-doc.vim uses it to open the document if it is not empty.  The command must take a url to the local file.

- `g:rust_doc#open_cmd`

Shell command to open the path to a document.  rust-doc.vim uses it to open the document if it is not empty.  The command must take a url to the local file.

- `g:rust_doc#do_not_ask_for_module_list`

If the value is `1`, rust-doc.vim never ask if it shows the list of modules/identifiers when no document is found. The default value is `0`.

- `g:rust_doc#define_map_K`

If the value is `1`, `K` mappings described above is defined. The default value is `1`.

- `g:rust_doc#downloaded_rust_doc_dir`

As described above, the path to directory of rust standard library documents.


## License

This plugin is distributed under [the MIT License](http://opensource.org/licenses/MIT).

```
Copyright (c) 2015 rhysd
```

