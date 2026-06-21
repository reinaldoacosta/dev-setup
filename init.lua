vim.opt.runtimepath:prepend(vim.fn.expand("~/.vim"))
vim.opt.runtimepath:append(vim.fn.expand("~/.vim/after"))
vim.o.packpath = vim.o.runtimepath
vim.cmd("source ~/.vim/vimrc")

if vim.fn.has('nvim-0.5') == 1 then
  function _G.lsp_do(picker, fallback)
    if picker == "lsp_code_actions" then
      print('Getting code actions (this may take a while on first use)...')
    end
    vim.schedule(function()
      local status, telescope = pcall(require, 'telescope.builtin')
      if status then
        telescope[picker]({})
      else
        fallback()
      end
    end)
  end

  function _G.lsp_workspace_symbols(query)
    local status, telescope = pcall(require, 'telescope.builtin')
    if status then
      telescope.lsp_workspace_symbols({query=query})
    else
      vim.lsp.buf.workspace_symbol(query)
    end
  end

  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local bufnr = args.buf

      vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
      local opts = { noremap=true, silent=true }

      local function buf_set_keymap(mode, lhs, rhs) 
          vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts) 
      end

      -- Navigation
      buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
      buf_set_keymap('n', 'gd', '<cmd>lua _G.lsp_do("lsp_definitions", vim.lsp.buf.definition)<CR>')
      buf_set_keymap('n', '<Leader>D', '<cmd>lua _G.lsp_do("lsp_type_definitions", vim.lsp.buf.type_definition)<CR>')

      -- Information
      buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>')
      buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
      buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
      buf_set_keymap('n', 'gr', '<cmd>lua _G.lsp_do("lsp_references", vim.lsp.buf.references)<CR>')
      buf_set_keymap('n', '<Leader>ds', '<cmd>lua _G.lsp_do("lsp_document_symbols", vim.lsp.buf.document_symbol)<CR>')

      -- Diagnostics
      buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
      buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
      buf_set_keymap('n', '<Leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>')
      buf_set_keymap('n', '<Leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>')

      -- Refactoring
      buf_set_keymap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
      buf_set_keymap('n', '<Leader>ca', '<cmd>lua _G.lsp_do("lsp_code_actions", vim.lsp.buf.code_action)<CR>')

      -- Workspaces
      buf_set_keymap('n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>')
      buf_set_keymap('n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>')
      buf_set_keymap('n', '<Leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>')

      if client.server_capabilities.documentFormattingProvider or client.server_capabilities.documentRangeFormattingProvider then
        buf_set_keymap("n", "<Leader>fd", "<cmd>lua vim.lsp.buf.format()<CR>")
      end

      if client.server_capabilities.documentHighlightProvider then
        vim.cmd([[
          hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
          hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
          hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
        ]])
        vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
        vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_document_highlight" })
        vim.api.nvim_create_autocmd("CursorHold", {
            callback = vim.lsp.buf.document_highlight,
            buffer = bufnr,
            group = "lsp_document_highlight",
            desc = "Document Highlight",
        })
        vim.api.nvim_create_autocmd("CursorMoved", {
            callback = vim.lsp.buf.clear_references,
            buffer = bufnr,
            group = "lsp_document_highlight",
            desc = "Clear All the References",
        })
      end
    end
  })

  local jdtls_bundles = {vim.env.HOME.."/language-servers/java/extensions/debug.jar"}
  local other_bundles = vim.split(vim.fn.glob(vim.env.HOME.."/language-servers/java/extensions/test/extension/server/*.jar"), "\n")
  for _, bundle in ipairs(other_bundles) do
    if bundle ~= "" then
      table.insert(jdtls_bundles, bundle)
    end
  end

  if not vim.lsp.config then
    vim.lsp.config = {}
  end

  if vim.lsp.config.jdtls then
    vim.lsp.config.jdtls.cmd = { "java-language-server", "--heap-max", "8G" }
    vim.lsp.config.jdtls.init_options = {
      bundles = jdtls_bundles
    }
  else
    vim.lsp.config.jdtls = {
      cmd = { "java-language-server", "--heap-max", "8G" },
      init_options = {
        bundles = jdtls_bundles
      }
    }
  end

  -- Using natively vim.lsp.enable as per nvim 0.11+
  vim.lsp.enable({'jdtls', 'gopls', 'bashls'})

  local status, telescope = pcall(require, 'telescope')
  if status then
    telescope.setup{
      pickers = {
        ['lsp_code_actions'] = {
          timeout = 30000
        }
      }
    }
  end

  local status, treesitter = pcall(require, 'nvim-treesitter.configs')
  if status then
    treesitter.setup{
      ensure_installed = {"bash", "c_sharp", "clojure", "comment", "css", "go", "graphql", "html", "java", "javascript", "json", "kotlin", "lua", "php", "python", "regex", "ruby", "rust", "scala", "toml", "typescript"},
      highlight = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },
      indent = { enable = true },
    }
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.o.foldlevelstart = 99
  end

  function _G.notify_file_changed(buffer, change)
    local status, log = pcall(require, 'vim.lsp.log')
    if not status then return end
    local filepath = vim.fn.expand('#'..buffer..':p')
    for _,client in pairs(vim.lsp.get_active_clients()) do
      log.info('Notifying LSP server "'..client.name..'" of change to file "'..filepath..'"')
      local result = client.notify('workspace/didChangeWatchedFiles', {
        changes = {{ uri = 'file://'..filepath, type = change }},
      })
      if not result then
        log.warn('File change notification failed!')
      end
    end
  end

  local status_copilot, copilot_chat = pcall(require, "CopilotChat")
  if status_copilot then
    copilot_chat.setup({
      model = 'gpt-4o',
      debug = true,
      mappings = {
        submit_prompt = {
          insert = '<C-s>',
        },
      },
    })
  end

  vim.cmd([[
    augroup buffer_updates
      au!
      au BufWritePost,FileWritePost * lua _G.notify_file_changed(vim.fn.expand('<abuf>'), 2)
    augroup END
    command! -nargs=1 Symbols :lua _G.lsp_workspace_symbols('<args>')
  ]])
end
