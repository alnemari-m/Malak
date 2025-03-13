#!/bin/bash
#
# ARCH LINUX DATA SCIENCE & ML ENGINEERING ENVIRONMENT SETUP
# ==========================================================
# This script sets up a complete data science and machine learning environment
# on Arch Linux with optimized Vim/Neovim configuration.

set -e  # Exit on error
set -u  # Treat unset variables as errors

# Helper function for output
print_status() {
    echo -e "\n\033[1;34m>>> $1\033[0m"
}

print_error() {
    echo -e "\n\033[1;31m!!! $1\033[0m" >&2
}

print_success() {
    echo -e "\n\033[1;32m✓ $1\033[0m"
}

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root"
    exit 1
fi

print_status "Starting Arch Linux Data Science Environment Setup"

# System Update
print_status "Updating system packages"
sudo pacman -Syu --noconfirm

# Add Arabic language support
print_status "Adding Arabic language support"
sudo sed -i 's/#ar_SA.UTF-8 UTF-8/ar_SA.UTF-8 UTF-8/' /etc/locale.gen
sudo sed -i 's/#ar_AE.UTF-8 UTF-8/ar_AE.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen

# Install development tools and base dependencies
print_status "Installing base development dependencies"
sudo pacman -S --needed --noconfirm base-devel git cmake wget curl unzip \
    python python-pip python-setuptools python-wheel \
    python-virtualenv python-pipenv \
    openssh gnupg pass rsync htop ncdu tmux dstat \
    ripgrep fd fzf bat exa parallel jq yq \
    noto-fonts-cjk noto-fonts-emoji noto-fonts \
    aspell aspell-en aspell-ar \
    hunspell hunspell-en_US hunspell-ar

# Install optimized kernel for high-performance computing
print_status "Installing optimized kernel"
sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers

# GPU-specific packages
read -p "Do you have an NVIDIA GPU? (y/n): " has_nvidia
if [[ $has_nvidia =~ ^[Yy]$ ]]; then
    print_status "Installing NVIDIA drivers and CUDA stack"
    sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings cuda cudnn
    
    # Create a file to load CUDA environment variables
    mkdir -p ~/.config/environment.d/
    cat > ~/.config/environment.d/cuda.conf << EOF
PATH=$PATH:/opt/cuda/bin
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/lib64
EOF
    
    # Create alias for GPU monitoring
    echo 'alias gpu-stats="watch -n 0.5 nvidia-smi"' >> ~/.bashrc
else
    read -p "Do you have an AMD GPU? (y/n): " has_amd
    if [[ $has_amd =~ ^[Yy]$ ]]; then
        print_status "Installing ROCm (AMD GPU) stack"
        sudo pacman -S --needed --noconfirm rocm-opencl-runtime rocm-hip rocminfo
    fi
fi

# Install scientific libraries and data science tools
print_status "Installing Python data science tools"
sudo pacman -S --needed --noconfirm \
    python-numpy python-scipy python-matplotlib python-pandas \
    python-scikit-learn python-statsmodels python-seaborn \
    python-plotly python-bokeh python-altair \
    python-nltk python-gensim python-spacy \
    jupyter-notebook jupyterlab \
    python-openpyxl python-xlrd python-xlwt

# Install deep learning frameworks
print_status "Installing deep learning frameworks"
sudo pacman -S --needed --noconfirm \
    python-pytorch python-pytorch-cuda python-torchvision \
    python-tensorflow python-keras 

# Install database clients for data work
print_status "Installing database clients"
sudo pacman -S --needed --noconfirm \
    postgresql-libs mariadb-libs sqlite \
    python-sqlalchemy python-psycopg2 python-pymysql

# Install containerization tools
print_status "Installing Docker and related tools"
sudo pacman -S --needed --noconfirm docker docker-compose
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install AUR helper (yay)
if ! command -v yay &> /dev/null; then
    print_status "Installing yay AUR helper"
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

# Install additional AUR packages
print_status "Installing useful AUR packages"
yay -S --needed --noconfirm \
    visual-studio-code-bin \
    python-umap-learn \
    miniconda3 \
    ttf-fira-code \
    nerd-fonts-fira-code \
    adobe-source-han-sans-otc-fonts \
    adobe-source-han-serif-otc-fonts \
    adobe-source-code-pro-fonts \
    adobe-source-sans-pro-fonts \
    adobe-source-serif-pro-fonts \
    ttf-amiri \
    ttf-arabeyes-fonts \
    ttf-scheherazade-new

# Setup Neovim with optimized configuration
print_status "Setting up ultimate Neovim configuration"

# Install neovim and dependencies
sudo pacman -S --needed --noconfirm neovim xclip python-neovim nodejs npm fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt

# Create directory structure for Neovim
mkdir -p ~/.config/nvim/{lua,plugin,after/plugin}

# Install vim-plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Create Neovim config
cat > ~/.config/nvim/init.vim << 'EOL'
" -----------------------------------------------------------------------------
" Ultimate Neovim Configuration for Data Science and ML Engineering
" -----------------------------------------------------------------------------

" Plugin Management with vim-plug
call plug#begin('~/.config/nvim/plugged')

" Core plugins
Plug 'neovim/nvim-lspconfig'                           " LSP configuration
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " Syntax highlighting
Plug 'hrsh7th/nvim-cmp'                               " Completion framework
Plug 'hrsh7th/cmp-nvim-lsp'                           " LSP completion source
Plug 'hrsh7th/cmp-buffer'                             " Buffer completion source
Plug 'hrsh7th/cmp-path'                               " Path completion source
Plug 'hrsh7th/cmp-cmdline'                            " Command line completion
Plug 'saadparwaiz1/cmp_luasnip'                       " Snippet completion source
Plug 'L3MON4D3/LuaSnip'                               " Snippet engine
Plug 'rafamadriz/friendly-snippets'                   " Snippet collection

" Data Science specific
Plug 'goerz/jupytext.vim'                             " Edit Jupyter notebooks as markdown
Plug 'bfredl/nvim-ipy'                                " Jupyter integration
Plug 'mtikekar/nvim-send-to-term'                     " Send code to terminal

" IDE features
Plug 'nvim-lua/plenary.nvim'                          " Utility functions
Plug 'nvim-telescope/telescope.nvim'                  " Fuzzy finder
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'kyazdani42/nvim-web-devicons'                   " Icons
Plug 'kyazdani42/nvim-tree.lua'                       " File explorer
Plug 'akinsho/bufferline.nvim'                        " Buffer line
Plug 'lewis6991/gitsigns.nvim'                        " Git integration
Plug 'tpope/vim-fugitive'                             " Git commands
Plug 'folke/which-key.nvim'                           " Key binding helper
Plug 'numToStr/Comment.nvim'                          " Easy commenting
Plug 'windwp/nvim-autopairs'                          " Auto pairs

" UI enhancements
Plug 'navarasu/onedark.nvim'                          " Theme
Plug 'nvim-lualine/lualine.nvim'                      " Status line
Plug 'lukas-reineke/indent-blankline.nvim'            " Indentation guides
Plug 'folke/zen-mode.nvim'                            " Distraction-free mode
Plug 'folke/twilight.nvim'                            " Dim inactive code
Plug 'folke/todo-comments.nvim'                       " Highlight TODO comments

" Data visualization & analysis helpers
Plug 'dkarter/bullets.vim'                            " Automated bullets
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }

call plug#end()

" Basic settings
syntax on
filetype plugin indent on
set number relativenumber
set expandtab tabstop=4 shiftwidth=4 softtabstop=4
set ignorecase smartcase
set clipboard+=unnamedplus
set mouse=a
set hidden
set updatetime=100
set signcolumn=yes
set scrolloff=8
set cursorline
set termguicolors
set undofile
set splitright splitbelow
set list listchars=tab:»·,trail:·,nbsp:·
set title
set completeopt=menu,menuone,noselect
set shortmess+=c
set autoread
set background=dark

" Leader key
let mapleader = " "

" Core key mappings
nnoremap <C-s> :w<CR>
nnoremap <C-q> :q<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>e :e $MYVIMRC<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Terminal mode escape
tnoremap <Esc> <C-\><C-n>

" Data Science specific mappings
nnoremap <leader>jp :!jupyter notebook<CR>
nnoremap <leader>jl :!jupyter lab<CR>

" Lua Configurations will be loaded from separate files
lua require('config')
EOL

# Create Lua config directory and main config file
mkdir -p ~/.config/nvim/lua/config
cat > ~/.config/nvim/lua/config/init.lua << 'EOL'
-- Master configuration file that imports all components
require('config.theme')
require('config.lsp')
require('config.cmp')
require('config.treesitter')
require('config.telescope')
require('config.nvimtree')
require('config.lualine')
require('config.keymaps')
require('config.autopairs')
require('config.comment')
require('config.whichkey')
require('config.bufferline')
require('config.gitsigns')
EOL

# Create theme configuration
mkdir -p ~/.config/nvim/lua/config
cat > ~/.config/nvim/lua/config/theme.lua << 'EOL'
-- Theme configuration
require('onedark').setup {
    style = 'darker',
    transparent = false,
    term_colors = true,
    code_style = {
        comments = 'italic',
        keywords = 'bold',
        functions = 'italic,bold',
        strings = 'none',
        variables = 'none'
    },
    diagnostics = {
        darker = true,
        undercurl = true,
        background = true,
    },
}
require('onedark').load()
EOL

# Create autocomplete configuration
cat > ~/.config/nvim/lua/config/cmp.lua << 'EOL'
-- Autocomplete configuration
local cmp = require('cmp')
local luasnip = require('luasnip')

-- Load friendly snippets
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
        ['<Tab>'] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end,
        ['<S-Tab>'] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end,
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' },
    },
    formatting = {
        format = function(entry, vim_item)
            -- Source name in menu
            vim_item.menu = ({
                nvim_lsp = "[LSP]",
                luasnip = "[Snippet]",
                buffer = "[Buffer]",
                path = "[Path]",
            })[entry.source.name]
            return vim_item
        end
    },
})
EOL

# Create LSP configuration
cat > ~/.config/nvim/lua/config/lsp.lua << 'EOL'
-- LSP configuration
local nvim_lsp = require('lspconfig')
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings
    local opts = { noremap=true, silent=true }
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
    buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

-- Default capabilities with nvim-cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Setup servers
local servers = { 
    'pyright',           -- Python
    'bashls',            -- Bash
    'r_language_server', -- R
    'tsserver',          -- TypeScript/JavaScript
    'jsonls',            -- JSON
    'cssls',             -- CSS
    'html',              -- HTML
    'yamlls',            -- YAML
    'dockerls',          -- Docker
    'sqlls',             -- SQL
}

for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
        flags = {
            debounce_text_changes = 150,
        }
    }
end

-- Special configuration for Python (Pyright)
nvim_lsp.pyright.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
            }
        }
    }
}
EOL

# Create the rest of the configuration files
cat > ~/.config/nvim/lua/config/treesitter.lua << 'EOL'
-- Treesitter configuration
require('nvim-treesitter.configs').setup {
    ensure_installed = { 
        "python", "r", "julia", "lua", "bash", "javascript", 
        "typescript", "json", "yaml", "toml", "html", "css", 
        "markdown", "sql", "dockerfile", "vim"
    },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true
    },
}
EOL

# Add Arabic language support to Neovim
cat > ~/.config/nvim/after/ftplugin/arabic.vim << 'EOL'
" Arabic language support
setlocal keymap=arabic
setlocal rightleft
setlocal rightleftcmd=search
setlocal arabicshape
setlocal termbidi
EOL


cat > ~/.config/nvim/lua/config/telescope.lua << 'EOL'
-- Telescope configuration
local telescope = require('telescope')
telescope.setup {
    defaults = {
        file_ignore_patterns = {
            "%.git/",
            "node_modules/",
            "%.ipynb_checkpoints/",
            "__pycache__/",
            "%.pyc",
            "%.pyo",
            "env/",
            "venv/",
            ".venv/",
            ".DS_Store"
        },
    },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        }
    }
}
telescope.load_extension('fzf')
EOL

cat > ~/.config/nvim/lua/config/nvimtree.lua << 'EOL'
-- File Explorer configuration
require('nvim-tree').setup {
    sort_by = "case_sensitive",
    view = {
        width = 30,
    },
    renderer = {
        group_empty = true,
    },
    filters = {
        dotfiles = false,
    },
    git = {
        enable = true,
        ignore = false,
        timeout = 500,
    },
}
EOL

cat > ~/.config/nvim/lua/config/lualine.lua << 'EOL'
-- Status line configuration
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'onedark',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {},
        always_divide_middle = true,
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    extensions = {'nvim-tree', 'fugitive'}
}
EOL

cat > ~/.config/nvim/lua/config/keymaps.lua << 'EOL'
-- Data Science specific keymaps
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Telescope
map('n', '<leader>ff', '<cmd>Telescope find_files<CR>', opts)
map('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', opts)
map('n', '<leader>fb', '<cmd>Telescope buffers<CR>', opts)
map('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', opts)

-- NvimTree
map('n', '<leader>nt', '<cmd>NvimTreeToggle<CR>', opts)
map('n', '<leader>nf', '<cmd>NvimTreeFindFile<CR>', opts)

-- Terminal
map('n', '<leader>tt', '<cmd>split | terminal<CR>', opts)
map('n', '<leader>tv', '<cmd>vsplit | terminal<CR>', opts)

-- Send to terminal
map('n', '<leader>sl', '<Plug>SendLine', {})
map('v', '<leader>ss', '<Plug>Send', {})

-- Data science specific
map('n', '<leader>mp', '<cmd>MarkdownPreview<CR>', opts)  -- Markdown preview
map('n', '<leader>ms', '<cmd>MarkdownPreviewStop<CR>', opts)  -- Stop markdown preview

-- Zen mode
map('n', '<leader>z', '<cmd>ZenMode<CR>', opts)
EOL

cat > ~/.config/nvim/lua/config/autopairs.lua << 'EOL'
-- Auto pairs configuration
require('nvim-autopairs').setup {
    check_ts = true,
    disable_filetype = { "TelescopePrompt" },
}
EOL

cat > ~/.config/nvim/lua/config/comment.lua << 'EOL'
-- Comment.nvim configuration
require('Comment').setup()
EOL

cat > ~/.config/nvim/lua/config/whichkey.lua << 'EOL'
-- Which-key configuration
require("which-key").setup {
    plugins = {
        marks = true,
        registers = true,
        spelling = { enabled = false },
        presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
        },
    },
    operators = { gc = "Comments" },
    key_labels = {},
    icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
    },
    popup_mappings = {
        scroll_down = '<c-d>',
        scroll_up = '<c-u>',
    },
    window = {
        border = "single",
        position = "bottom",
        margin = { 1, 0, 1, 0 },
        padding = { 2, 2, 2, 2 },
        winblend = 0
    },
    layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "center",
    },
    ignore_missing = false,
    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
    show_help = true,
    triggers = "auto",
    triggers_blacklist = {
        i = { "j", "k" },
        v = { "j", "k" },
    },
}

local wk = require("which-key")
wk.register({
    f = {
        name = "Find",
        f = { "Find File" },
        g = { "Find Text" },
        b = { "Find Buffer" },
        h = { "Find Help" },
    },
    g = { name = "Git/LSP" },
    t = { name = "Terminal" },
    n = { 
        name = "Explorer", 
        t = { "Toggle" },
        f = { "Find File" },
    },
    s = { 
        name = "Send to Terminal",
        l = { "Send Line" },
        s = { "Send Selection" },
    },
    m = { 
        name = "Markdown",
        p = { "Preview" },
        s = { "Stop Preview" },
    },
    j = {
        name = "Jupyter",
        p = { "Notebook" },
        l = { "Lab" },
    },
}, { prefix = "<leader>" })
EOL

cat > ~/.config/nvim/lua/config/bufferline.lua << 'EOL'
-- Bufferline configuration
require("bufferline").setup {
    options = {
        numbers = "ordinal",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
            icon = '▎',
            style = 'icon',
        },
        buffer_close_icon = '',
        modified_icon = '●',
        close_icon = '',
        left_trunc_marker = '',
        right_trunc_marker = '',
        max_name_length = 18,
        max_prefix_length = 15,
        tab_size = 18,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
            return "("..count..")"
        end,
        offsets = {{filetype = "NvimTree", text = "File Explorer", text_align = "left"}},
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        persist_buffer_sort = true,
        separator_style = "thin",
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        sort_by = 'id',
    }
}
EOL

cat > ~/.config/nvim/lua/config/gitsigns.lua << 'EOL'
-- Git integration configuration
require('gitsigns').setup {
    signs = {
        add          = {hl = 'GitSignsAdd'   , text = '│', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
        change       = {hl = 'GitSignsChange', text = '│', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
        delete       = {hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
        topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
        changedelete = {hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
    },
    signcolumn = true,
    numhl      = false,
    linehl     = false,
    word_diff  = false,
    watch_gitdir = {
        interval = 1000,
        follow_files = true
    },
    attach_to_untracked = true,
    current_line_blame = false,
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 1000,
        ignore_whitespace = false,
    },
    current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil,
    max_file_length = 40000,
    preview_config = {
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
    },
    yadm = {
        enable = false
    },
}
EOL

# Install all plugins
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Create optimized Python environment for data science
print_status "Creating optimized Python data science environment"

# Install recommended Python packages for data science
python -m pip install --user --upgrade \
    numpy scipy pandas matplotlib seaborn \
    scikit-learn scikit-image \
    tensorflow keras xgboost lightgbm \
    jupyterlab jupyter notebook \
    ipywidgets ipympl \
    dash plotly altair bokeh \
    networkx nltk spacy \
    sqlalchemy pymongo pymysql psycopg2-binary \
    requests beautifulsoup4 selenium \
    pytest pytest-cov black flake8 mypy \
    rope isort yapf autopep8 \
    openpyxl xlrd xlwt \
    tqdm dask distributed \
    pyarrow polars \
    shap eli5 lime \
    statsmodels patsy \
    arabic-reshaper python-bidi   # Arabic text support libraries

# Configure Jupyter for better integration with neovim
mkdir -p ~/.jupyter
python -m pip install jupytext
jupyter nbextension install --py jupytext
jupyter nbextension enable --py jupytext
jupyter serverextension enable --py jupytext

# Create useful bash utilities for data scientists
print_status "Creating shell utilities for data science"

mkdir -p ~/bin
mkdir -p ~/.local/share/dsutils

# Create data science user group for shared resources
print_status "Setting up shared resource access for other users"

# Create data science group
sudo groupadd datasci

# Add current user to the group
sudo usermod -a -G datasci $USER

# Setup GPU access for group members
if command -v nvidia-smi &> /dev/null; then
    # For NVIDIA GPUs
    print_status "Setting up NVIDIA GPU access for group members"
    
    # Create udev rules for NVIDIA GPUs
    echo 'KERNEL=="nvidia*", RUN+="/bin/bash -c \'/bin/chgrp datasci /dev/nvidia* && /bin/chmod g+rw /dev/nvidia*\'"' | sudo tee /etc/udev/rules.d/99-nvidia.rules
    
    # Create persistent config for module loading
    echo 'options nvidia NVreg_RestrictProfilingToAdminUsers=0' | sudo tee /etc/modprobe.d/nvidia-datasci.conf
    
    # Create persistence daemon config
    cat > /tmp/nvidia-persistenced-datasci.conf << 'EOL'
# This file is provided by the nvidia-persistenced package.

# A simple script to initialize the NVIDIA driver when run as datasci group
run-parts --regex ".*nvidia.*" /etc/nvidia-persistenced/conf.d/

modprobe -a nvidia nvidia_uvm
exit 0
EOL
    sudo mv /tmp/nvidia-persistenced-datasci.conf /etc/nvidia-persistenced/conf.d/datasci.conf
    
elif command -v rocm-smi &> /dev/null; then
    # For AMD GPUs with ROCm
    print_status "Setting up ROCm GPU access for group members"
    
    # Create udev rules for ROCm GPUs
    cat > /tmp/70-amdgpu.rules << 'EOL'
KERNEL=="kfd", GROUP="datasci", MODE="0660"
KERNEL=="renderD*", GROUP="datasci", MODE="0660"
SUBSYSTEM=="drm", KERNEL=="card*", GROUP="datasci", MODE="0660"
EOL
    sudo mv /tmp/70-amdgpu.rules /etc/udev/rules.d/70-amdgpu.rules
fi

# Setup shared hard drive access
print_status "Setting up shared hard drive access"

# Prompt for the hard drive to share
echo "Available drives:"
lsblk -o NAME,SIZE,MOUNTPOINT,LABEL,FSTYPE | grep -v loop

read -p "Enter the device to share (e.g., sdb1): " shared_drive

if [ -b "/dev/$shared_drive" ]; then
    # Create mount point for shared drive
    sudo mkdir -p /shared
    
    # Get filesystem type
    fs_type=$(lsblk -no FSTYPE /dev/$shared_drive)
    
    # If not formatted, offer to format
    if [ -z "$fs_type" ]; then
        read -p "Drive appears to be unformatted. Format as ext4? (y/n): " format_drive
        if [[ $format_drive =~ ^[Yy]$ ]]; then
            sudo mkfs.ext4 -L "SHARED_DATA" /dev/$shared_drive
            fs_type="ext4"
        else
            echo "Cannot proceed without formatting. Please format the drive manually."
        fi
    fi
    
    # Get UUID for persistent mounting
    uuid=$(sudo blkid -s UUID -o value /dev/$shared_drive)
    
    # Add to fstab for auto-mounting
    if [ -n "$uuid" ]; then
        echo "UUID=$uuid /shared $fs_type defaults,nofail,grpid 0 2" | sudo tee -a /etc/fstab
        
        # Mount the drive
        sudo mount /shared
        
        # Set group ownership
        sudo chgrp -R datasci /shared
        sudo chmod -R 2775 /shared  # setgid bit ensures new files inherit group
        
        print_success "Shared drive configured successfully"
    else
        print_error "Could not determine UUID for the drive"
    fi
else
    print_error "Invalid device: /dev/$shared_drive"
fi

# Create script for adding new users to datasci group
cat > ~/bin/add-datasci-user << 'EOL'
#!/bin/bash
# Add a new user with access to shared data science resources

if [ "$#" -lt 1 ]; then
    echo "Usage: add-datasci-user <username>"
    exit 1
fi

USERNAME=$1

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if user exists
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists"
    # Add to datasci group
    usermod -a -G datasci "$USERNAME"
    echo "Added $USERNAME to datasci group"
else
    # Create new user
    useradd -m -G datasci "$USERNAME"
    echo "Created user $USERNAME and added to datasci group"
    
    # Set password
    passwd "$USERNAME"
fi

# Remind about GPU access
echo "User $USERNAME now has access to shared GPU resources and the shared data drive"
echo "System may need to be rebooted for all permissions to take effect"
EOL
chmod +x ~/bin/add-datasci-user
sudo cp ~/bin/add-datasci-user /usr/local/bin/

# Create a simple README for new users
mkdir -p /shared/README
cat > /shared/README/datasci-environment.md << 'EOL'
# Data Science Environment Guide

This system has been configured with a shared data science environment. Here's how to get started:

## Shared Resources

- **Shared Storage**: The `/shared` directory is accessible to all members of the `datasci` group
- **GPU Access**: GPUs are configured for shared access by all members of the `datasci` group

## Using the Environment

### Python Environment

The system has a pre-configured Python environment with data science libraries including:

- NumPy, Pandas, Matplotlib, Seaborn for data processing and visualization
- Scikit-learn, TensorFlow, PyTorch for machine learning
- NLTK, SpaCy for NLP (including Arabic language support)

### GPU Computing

For NVIDIA GPUs:
```bash
# Check GPU status
nvidia-smi

# Monitor GPU usage
gpu-usage
```

For AMD GPUs:
```bash
# Check GPU status
rocm-smi

# Monitor GPU usage
gpu-usage
```

### Arabic Language Support

For working with Arabic text:

```bash
# Process Arabic text
arabic-preprocess --help

# Example: Normalize and reshape Arabic text
arabic-preprocess --normalize --reshape -f input.txt -o output.txt
```

## Best Practices

1. Store large datasets in `/shared/datasets/`
2. Keep trained models in `/shared/models/`
3. Document your work in `/shared/projects/your-username/`
4. For intensive GPU computations, check if others are using the GPU first

## Getting Help

If you need help or want to request additional packages, please contact the system administrator.
EOL

print_status "Creating systemd service for GPU monitoring and management"

# Create GPU monitoring service
cat > /tmp/gpu-stats.service << 'EOL'
[Unit]
Description=GPU Statistics Collection Service
After=network.target

[Service]
Type=simple
User=nobody
Group=datasci
ExecStart=/bin/bash -c 'if command -v nvidia-smi &>/dev/null; then while true; do nvidia-smi --query-gpu=timestamp,name,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader >> /shared/gpu-stats.csv; sleep 60; done; elif command -v rocm-smi &>/dev/null; then while true; do rocm-smi --showuse --showmemuse --showtemp --csv >> /shared/gpu-stats.csv; sleep 60; done; fi'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL
sudo mv /tmp/gpu-stats.service /etc/systemd/system/
sudo systemctl enable gpu-stats.service
sudo systemctl start gpu-stats.service

# Train progress monitoring utility
cat > ~/bin/train-monitor << 'EOL'
#!/bin/bash
# Monitors training progress by watching log files for metrics

if [ "$#" -lt 1 ]; then
    echo "Usage: train-monitor <logfile> [metric_name]"
    exit 1
fi

LOGFILE=$1
METRIC=${2:-"loss"}

watch -n 2 "grep -E '$METRIC:|accuracy:|val_|validation' $LOGFILE | tail -n 20"
EOL
chmod +x ~/bin/train-monitor

# GPU monitoring utility
cat > ~/bin/gpu-usage << 'EOL'
#!/bin/bash
# Continuously monitor GPU usage with detailed stats

if command -v nvidia-smi &> /dev/null; then
    # For NVIDIA GPUs
    watch -n 0.5 "nvidia-smi --query-gpu=timestamp,name,pci.bus_id,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw --format=csv"
elif command -v rocm-smi &> /dev/null; then
    # For AMD GPUs
    watch -n 0.5 "rocm-smi --showuse --showmemuse --showtemp"
else
    echo "No supported GPU monitoring tools found."
    exit 1
fi
EOL
chmod +x ~/bin/gpu-usage

# Add Arabic text processing utility
cat > ~/bin/arabic-preprocess << 'EOL'
#!/usr/bin/env python3
# Arabic text preprocessing utility

import sys
import argparse
import re
import arabic_reshaper
from bidi.algorithm import get_display

def preprocess_arabic(text, normalize=True, remove_diacritics=False, remove_tatweel=False):
    """Preprocess Arabic text for NLP tasks"""
    if normalize:
        # Normalize various forms of Alef and Hamza
        text = re.sub("[إأآا]", "ا", text)
        text = re.sub("ى", "ي", text)
        text = re.sub("ة", "ه", text)
        
    if remove_diacritics:
        # Remove diacritics (tashkeel)
        text = re.sub("[\u064B-\u065F]", "", text)
        
    if remove_tatweel:
        # Remove tatweel (kashida)
        text = re.sub("\u0640", "", text)
        
    return text

def reshape_for_display(text):
    """Reshape Arabic text for proper display"""
    reshaped_text = arabic_reshaper.reshape(text)
    bidi_text = get_display(reshaped_text)
    return bidi_text

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process Arabic text for NLP or display")
    parser.add_argument("--file", "-f", help="Input file (if not specified, reads from stdin)")
    parser.add_argument("--output", "-o", help="Output file (if not specified, writes to stdout)")
    parser.add_argument("--normalize", "-n", action="store_true", help="Normalize Arabic characters")
    parser.add_argument("--remove-diacritics", "-d", action="store_true", help="Remove diacritics (tashkeel)")
    parser.add_argument("--remove-tatweel", "-t", action="store_true", help="Remove tatweel (kashida)")
    parser.add_argument("--reshape", "-r", action="store_true", help="Reshape for proper display")
    
    args = parser.parse_args()
    
    # Read input
    if args.file:
        with open(args.file, 'r', encoding='utf-8') as f:
            text = f.read()
    else:
        text = sys.stdin.read()
    
    # Process text
    if args.normalize or args.remove_diacritics or args.remove_tatweel:
        text = preprocess_arabic(
            text, 
            normalize=args.normalize,
            remove_diacritics=args.remove_diacritics,
            remove_tatweel=args.remove_tatweel
        )
    
    # Reshape if requested
    if args.reshape:
        text = reshape_for_display(text)
    
    # Write output
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(text)
    else:
        print(text)
EOL
chmod +x ~/bin/arabic-preprocess

# Configure Fcitx5 for Arabic input
mkdir -p ~/.config/environment.d/
cat > ~/.config/environment.d/fcitx5.conf << 'EOL'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
EOL

# Create a simple Arabic font configuration
mkdir -p ~/.config/fontconfig/conf.d/
cat > ~/.config/fontconfig/conf.d/99-arabic-fonts.conf << 'EOL'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Set preferred Arabic fonts -->
  <match>
    <test name="lang" compare="contains">
      <string>ar</string>
    </test>
    <test name="family">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Amiri</string>
      <string>Scheherazade New</string>
      <string>Source Sans Pro</string>
      <string>Noto Sans Arabic</string>
    </edit>
  </match>
  
  <match>
    <test name="lang" compare="contains">
      <string>ar</string>
    </test>
    <test name="family">
      <string>serif</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Amiri</string>
      <string>Scheherazade New</string>
      <string>Source Serif Pro</string>
      <string>Noto Serif Arabic</string>
    </edit>
  </match>
  
  <match>
    <test name="lang" compare="contains">
      <string>ar</string>
    </test>
    <test name="family">
      <string>monospace</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Source Code Pro</string>
      <string>Noto Sans Mono</string>
    </edit>
  </match>
</fontconfig>
EOL

# Add Arabic support to Neovim configuration