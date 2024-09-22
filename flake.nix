{
	inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=24.05";
    flake-utils.url = "github:numtide/flake-utils";
    neovim = {
      url = "github:neovim/neovim?ref=v0.10.1";
      flake = false;
    };

    # my understanding is that tree-sitter comes with neovim,
    # but the treesitter-nvim plugin is necessary to configure it
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter?ref=v0.9.2";
      flake = false;
    };

    telescope = {
      url = "github:nvim-telescope/telescope.nvim?ref=0.1.8";
      flake = false;
    };

    #this is necessary for telescope
    plenary = {
      url = "github:nvim-lua/plenary.nvim?ref=v0.1.4";
      flake = false;
    };

    #necessary for lsp completions and snippets
    nvim-cmp = {
      url = "github:hrsh7th/nvim-cmp?ref=v0.0.1";
      flake = false;
    };

    nvim-cmp-lsp = {
      url = "github:hrsh7th/cmp-nvim-lsp";
      flake = false;
    };

    #default configurations for specific language server clients
    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig?ref=v0.1.7";
      flake = false;
    };

    luasnip = {
      url = "github:L3MON4D3/LuaSnip?ref=v1.2.1";
      flake = false;
    };

    #this one doesn't have release tags, but the flake lock file
    #should ensure that it stays reproducible unless I do the update
    cmp_luasnip = {
      url = "github:saadparwaiz1/cmp_luasnip";
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
    , neovim
    , plenary
    , telescope
    , nvim-treesitter
    , nvim-cmp
    , nvim-lspconfig
    , luasnip
    , cmp_luasnip
    , vim-fugitive
    , lspkind
    , nvim-cmp-lsp
    , vim-rescript
  }@inputs: flake-utils.lib.eachDefaultSystem(system:
    let pkgs = nixpkgs.legacyPackages.${system};
      packageName = "neovim-flake";
      mylib = import ./lib { inherit nixpkgs inputs; };
      pluginHelpers = mylib.pluginHelpers;
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
        rev = "fdf503e52ec1c8aae07353604d891fe5a3ed5201";
        hash = "sha256-Mor0cLSNz+IZAVjuPNLDJ3pFQn7arbLqKVykDPkTA7g=";
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

      neovim-flake = (with pkgs; stdenv.mkDerivation {
        pname = packageName;
        version = "0.0.1";
        src = neovim;
        #ripgrep and fd for telescope
        #tree sitter needs to compile parsers at runtime, so it needs clang or gcc
        buildInputs = [
						ripgrep
						fd
            tree-sitter
					] ++ (if stdenv.isDarwin then [
						darwin.apple_sdk.frameworks.CoreFoundation
						darwin.apple_sdk.frameworks.CoreServices
					] else [
					]);
					nativeBuildInputs = [
            # clang is only needed at build time for neovim,
            # but tree sitter needs to compile parsers, so I'm going to try
            # allowing clang to neovim at run time by moving clang to
            # buildInputs. I may be able to try compiling them when the flake is built
            # something like this https://nixos.org/manual/nixpkgs/unstable/#managing-plugins-with-vim-packages
            # except that requires me to use the tree-sitter from nix packages
            # clang
            # I ended up needing to use gcc because some parsers failed to compile under clang
            gcc
            makeWrapper # necessary to allow me to make a wrapper for neovim that has clang on the path
            cmake
            libtool
            gettext
            libtool
            autoconf
            automake
            pkg-config
            unzip
            curl
            doxygen
            libuv
            luajit
            luajitPackages.libluv #lua bindings for libuv
            lua51Packages.lua
            lua51Packages.lpeg
            lua51Packages.mpack
            msgpack
            unibilium #terminfo library
            libtermkey
            libvterm-neovim #libvterm wouldn't work because a <glib.h> import was failing
            libiconv
          ];
          # the 'install' bit is important so that vim can find the runtime
          # without it, we'll get errors like "can't find syntax.vim"
          buildPhase = ''
            ls && \
            make -j $NIX_BUILD_CORES CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$out/nvim" install
          '';
          installPhase = let
            packDir = "$out/${pluginHelpers.packDir}";
            concatSlash = builtins.concatStringsSep "/";
            colorSchemePackageDir = concatSlash [packDir pluginHelpers.colorSchemePackageDirName "start"];
            languageServerPackageDir = concatSlash [packDir pluginHelpers.languageServerPackageDirName "start"];
            languagePackageDir = concatSlash [packDir pluginHelpers.languagePluginsPackageDirName "start"];
            vimPluginsPackageDir = concatSlash [packDir pluginHelpers.vimPluginsPackageDirName "start"];
            telescopePackageDir = concatSlash [packDir "telescope" "start"];
            lualinePackDir = concatSlash [packDir "nvim-lualine" "start"];
            webdevIconsPackDir = concatSlash [packDir "nvim-web-devicons" "start"];
          in
            ''
              mkdir -p $out/bin &&\
              mv bin/nvim $out/bin &&\
              mkdir -p ${colorSchemePackageDir} &&\
              mkdir -p ${languageServerPackageDir} &&\
              mkdir -p ${languagePackageDir} &&\
              mkdir -p ${vimPluginsPackageDir} &&\
              mkdir -p ${telescopePackageDir} &&\
              mkdir -p ${packDir}/tree-sitter/start &&\
              mkdir -p ${lualinePackDir} &&\
              mkdir -p ${webdevIconsPackDir} &&\
              cp -r ${telescope} ${telescopePackageDir}/telescope.nvim &&\
              cp -r ${plenary} ${telescopePackageDir}/plenary.nvim &&\
              cp -r ${nvim-treesitter} ${concatSlash [packDir "tree-sitter" "start"]}/nvim-treesitter.nvim &&\

              cp -r ${nvim-cmp} ${languageServerPackageDir}/nvim-cmp &&\
              cp -r ${nvim-lspconfig} ${languageServerPackageDir}/nvim-lspconfig &&\
              cp -r ${luasnip} ${languageServerPackageDir}/luasnip &&\
              cp -r ${cmp_luasnip} ${languageServerPackageDir}/cmp_luasnip &&\
              cp -r ${lspkind} ${languageServerPackageDir}/lspkind &&\
              cp -r ${nvim-cmp-lsp} ${languageServerPackageDir}/nvim-cmp-lsp &&\

              cp -r ${nvim-lualine} ${lualinePackDir}/nvim-lualine &&\
              cp -r ${nvim-web-devicons} ${webdevIconsPackDir}/nvim-web-devicons &&\

              cp -r ${vim-fugitive} ${concatSlash [vimPluginsPackageDir "vim-fugitive"]} &&\
              cp -r ${vim-surround} ${concatSlash [vimPluginsPackageDir "vim-surround"]} &&\

              cp -r ${dracula} ${concatSlash [colorSchemePackageDir "dracula"]} &&\
              cp -r ${catppuccin} ${concatSlash [colorSchemePackageDir "catppuccin"]} &&\
              cp -r ${tokyonight} ${concatSlash [colorSchemePackageDir "tokyonight"]} &&\
              cp -r ${vim-rescript} ${concatSlash [languagePackageDir "vim-rescript"]}
            '';
          # wraps the neovim binary's path with access to gcc,
          # so that tree-sitter can compile parsers
          # used this as a reference https://github.com/NixOS/nixpkgs/blob/4e76dff4b469172f6b083543c7686759a5155222/pkgs/tools/security/pass/default.nix
          # which was found through:https://discourse.nixos.org/t/buildinputs-not-propagating-to-the-derivation/4975/6
          wrapperPath = nixpkgs.lib.strings.makeBinPath ([
            gcc
            ripgrep
            fd
            tree-sitter
          ]);
          postFixup = ''
            wrapProgram $out/bin/nvim \
            --prefix PATH : "$out/bin:$wrapperPath" \
            --set LD_LIBRARY_PATH ${stdenv.cc.cc.lib}/lib
          '';
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
