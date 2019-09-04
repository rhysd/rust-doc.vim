from .base import Base


class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'rust/doc'
        self.kind = 'rust/doc/html'
        self._list = []

    def on_init(self, context):
        a = self.vim.eval("expand('%:p:h')")
        b = self.vim.eval('getcwd()')
        c = a or b
        docs = self.vim.eval("rust_doc#get_doc_dirs('{}')".format(c))
        if 'modules' in context['args']:
            self._list = self.vim.eval('rust_doc#get_modules({})'.format(docs))
        else:
            self._list = self.vim.eval('rust_doc#get_all_module_identifiers({})'.format(docs))

    def gather_candidates(self, context):
        return [{
            'word': self._word(s),
            'action__path': s['path']}
            for s in self._list]

    def highlight(self):
        self.vim.command('syntax match {}_Identifier /\%(::\)\@<=\h\w*\>\%(\s*\[\)\@=/ contained containedin={} display'.format(self.syntax_name, self.syntax_name))
        self.vim.command('syntax match {}_Tag /\[[^]]*\]/ contained containedin={} display'.format(self.syntax_name, self.syntax_name))
        self.vim.command('highlight default link {}_Identifier Identifier'.format(self.syntax_name))
        self.vim.command('highlight default link {}_Tag Tag'.format(self.syntax_name))

    def _tag(self, ident):
        fn = ident['path'].split('/')[-1]
        if fn == 'index.html':
            return ''
        return '.'.join(fn.split('.')[:-1])
    def _word(self, ident):
        tag = self._tag(ident)
        if tag != '':
            return '{}	[{}]'.format(ident['name'], tag)
        return ident['name']
