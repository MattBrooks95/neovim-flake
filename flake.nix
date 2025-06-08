{
	inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    telescope = {
      url = "github:nvim-telescope/telescope.nvim?ref=0.1.8";
      flake = false;
    };

    #this is necessary for telescope
    plenary = {
      url = "github:nvim-lua/plenary.nvim?ref=v0.1.4";
      flake = false;
    };

    #git integration
    vim-fugitive = {
      url = "github:tpope/vim-fugitive?ref=v3.7";
      flake = false;
    };

    lspkind = {
      url = "github:onsails/lspkind.nvim";
      flake = false;
    };

    vim-rescript = {
      url = "github:rescript-lang/vim-rescript?v2.1.0";
      flake = false;
    };
  };
  #flake-utils is an abstraction that saves us from needing to specify all the architectures
  #that our package supports
  outputs = { self
    , nixpkgs
    , flake-utils
    , plenary
    , telescope
    , vim-fugitive
    , lspkind
    , vim-rescript
  }@inputs: flake-utils.lib.eachDefaultSystem(system:
    let pkgs = nixpkgs.legacyPackages.${system};
      packageName = "neovim-flake";
      mylib = import ./lib { inherit nixpkgs inputs; mylib = mylib; };
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

        # TODO this fails with "error processing rule escape_sequence ... u{[0-09...]+}
        # tree-sitter-rescript = pkgs.fetchFromGitHub {
        #   owner = "rescript-lang";
        #   repo = "tree-sitter-rescript";
        #   rev = "v5.0.0";
        #   hash = "sha256-1u+ni5Du7rJqCWwjZzmVAl5G5eJdA6CiqG7b7wpCQJw=";
        # };
      };

      neovim-flake = pkgs.callPackage ./package.nix { inherit githubSources; };
    in {
      packages.default = neovim-flake;
      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/nvim";
      };
    }
  );
}
