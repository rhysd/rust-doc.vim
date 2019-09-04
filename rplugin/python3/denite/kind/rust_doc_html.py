from denite.base.kind import Base


class Kind(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'rust/doc/html'
        self.default_action = 'browse'

    def action_browse(self, context):
        for t in context['targets']:
            self.vim.command('call rust_doc#open_denite("{}")'.format(t['action__path']))
