{
	inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  #flake-utils is an abstraction that saves us from needing to specify all the architectures
  #that our package supports
  outputs = { self
    , nixpkgs
    , flake-utils
  }@inputs: flake-utils.lib.eachDefaultSystem(system:
    let pkgs = nixpkgs.legacyPackages.${system};
      packageName = "neovim-flake";
      githubSources = {
        neovim = pkgs.fetchFromGitHub {
          owner = "neovim";
          repo  = "neovim";
          rev   = "v0.11.1";
          hash  = "sha256-kJvKyNjpqIKa5aBi62jHTCb1KxQ4YgYtBh/aNYZSeO8=";
        };
        # my understanding is that tree-sitter comes with neovim,
        # but the treesitter-nvim plugin is necessary to configure it
        nvim-treesitter = pkgs.fetchFromGitHub {
          owner = "nvim-treesitter";
          repo = "nvim-treesitter";
          rev = "v0.9.3";
          hash = "sha256-8MQWi9FmcsD+p3c9neaoocnoDpNOskRvUPXAf+iJZDs=";
        };
        vim-surround = pkgs.fetchFromGitHub {
          owner = "tpope";
          repo = "vim-surround";
          rev = "master";
          hash = "sha256-DZE5tkmnT+lAvx/RQHaDEgEJXRKsy56KJY919xiH1lE=";
        };
        nvim-lualine = pkgs.fetchFromGitHub {
          owner = "nvim-lualine";
          repo = "lualine.nvim";
          rev = "master";
          hash = "sha256-WcH2dWdRDgMkwBQhcgT+Z/ArMdm+VbRhmQftx4t2kNI=";
        };
        # icons for lualine
        nvim-web-devicons = pkgs.fetchFromGitHub {
          owner = "nvim-tree";
          repo = "nvim-web-devicons";
          rev = "v0.99";
          hash = "sha256-9Z0d15vt4lz1Y8Bj2qeXADH/NleL2zhb2xJvK7EKcHE=";
        };

        # themes
        dracula = pkgs.fetchFromGitHub {
          owner = "mofiqul";
          repo = "dracula.nvim";
          rev = "94fa7885a06a67f0a8bfa03e064619d05d1ba496";
          hash = "sha256-3jFOaFtH+EIx4mUKV0U/cFkUo8By0JgorTYgFUKEs/s=";
        };

        catppuccin = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "nvim";
          rev = "v1.9.0";
          hash = "sha256-QGqwQ4OjIopBrk8sWYwA9+PMoUfcYANybgiLY6QLrvg=";
        };

        tokyonight = pkgs.fetchFromGitHub {
          owner = "folke";
          repo = "tokyonight.nvim";
          rev = "v4.8.0";
          hash = "sha256-5QeY3EevOQzz5PHDW2CUVJ7N42TRQdh7QOF9PH1YxkU=";
        };

        monokai = pkgs.fetchFromGitHub {
          # https://github.com/tanvirtin/monokai.nvim
          owner = "tanvirtin";
          repo  = "monokai.nvim";
          rev   = "b8bd44d5796503173627d7a1fc51f77ec3a08a63";
          hash  = "sha256-Q6+la2P2L1QmdsRKszBBMee8oLXHwdJGWjG/FMMFgT0=";
        };

        #necessary for lsp completions and snippets
        nvim-cmp = pkgs.fetchFromGitHub {
          owner = "hrsh7th";
          repo  = "nvim-cmp";
          rev   = "v0.0.2";
          hash  = "sha256-TmXpMgkPWXHn4+leojZg1V18wOiPDsKQeG1h8nGgVHo=";
        };

        nvim-cmp-lsp = pkgs.fetchFromGitHub {
          owner = "hrsh7th";
          repo  = "cmp-nvim-lsp";
# latest commit as of 2025-06-06
          rev   = "a8912b88ce488f411177fc8aed358b04dc246d7b";
          hash  = "sha256-iaihXNCF5bB5MdeoosD/kc3QtpA/QaIDZVLiLIurBSM=";
        };

        #default configurations for specific language server clients
        nvim-lspconfig = pkgs.fetchFromGitHub {
          owner = "neovim";
          repo  = "nvim-lspconfig";
          rev   = "v2.2.0";
          hash  = "sha256-mgWa5qubkkfZDy/I2Rts6PtXJy+luzUmSzbPb1lVerk=";
        };

        luasnip = pkgs.fetchFromGitHub {
          owner = "L3MON4D3";
          repo  = "LuaSnip";
          rev   = "v2.4.0";
          hash  = "sha256-FtDpvgbtKN9PN1cPXU0jdxj9VdScRE9W7P6d9rVftRQ=";
        };

        #this one doesn't have release tags, but the flake lock file
        #should ensure that it stays reproducible unless I do the update
        cmp_luasnip = pkgs.fetchFromGitHub {
          owner = "saadparwaiz1";
          repo  = "cmp_luasnip";
          rev   = "98d9cb5c2c38532bd9bdb481067b20fea8f32e90";
          hash  = "sha256-86lKQPPyqFz8jzuLajjHMKHrYnwW6+QOcPyQEx6B+gw=";
        };

        telescope = pkgs.fetchFromGitHub {
          hash  = "sha256-e1ulhc4IIvUgpjKQrSqPY4WpXuez6wlxL6Min9U0o5Q=";
          owner = "nvim-telescope";
          repo  = "telescope.nvim";
          rev   = "a0bbec21143c7bc5f8bb02e0005fa0b982edc026";
        };

        #this is necessary for telescope
        plenary = pkgs.fetchFromGitHub {
          hash  = "sha256-zR44d9MowLG1lIbvrRaFTpO/HXKKrO6lbtZfvvTdx+o=";
          owner = "nvim-lua";
          repo  = "plenary.nvim";
          rev   = "50012918b2fc8357b87cff2a7f7f0446e47da174";
        };

        #git integration
        vim-fugitive = pkgs.fetchFromGitHub {
          hash  = "sha256-JJ/T38rz7vowsv6q4qeEaRDfMGvl9ZMJley54fOvSAI=";
          owner = "tpope";
          repo  = "vim-fugitive";
          rev   = "96c1009fcf8ce60161cc938d149dd5a66d570756";
        };

        lspkind = pkgs.fetchFromGitHub {
          hash  = "sha256-OCvKUBGuzwy8OWOL1x3Z3fo+0+GyBMI9TX41xSveqvE=";
          owner = "onsails";
          repo  = "lspkind.nvim";
          rev   = "d79a1c3299ad0ef94e255d045bed9fa26025dab6";
        };

        vim-rescript = pkgs.fetchFromGitHub {
          hash  = "sha256-l12sg9O5elqWTFRs9asa9xMnKw5GbV7ZB8HmtjcFVps=";
          owner = "rescript-lang";
          repo  = "vim-rescript";
          rev   = "aea571554254ab9da4f997b20d2ebca2fd099c52";
        };

        # TODO this fails with "error processing rule escape_sequence ... u{[0-09...]+}
        # tree-sitter-rescript = pkgs.fetchFromGitHub {
        #   owner = "rescript-lang";
        #   repo = "tree-sitter-rescript";
        #   rev = "v5.0.0";
        #   hash = "sha256-1u+ni5Du7rJqCWwjZzmVAl5G5eJdA6CiqG7b7wpCQJw=";
        # };
      };

      neovim-flake =
        let mylib = import ./lib { inherit nixpkgs inputs; };
        in pkgs.callPackage ./package.nix (githubSources // {
          mylib=mylib;
# using the default interperter (`lua` package from nixpkgs) did not work
# using LuaJIT did
          lua = pkgs.luajit;
        });
    in {
      packages.default = neovim-flake;
      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/nvim";
      };
    }
  );
}
