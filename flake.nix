{
	inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    neovim = {
      url = "github:neovim/neovim?ref=v0.9.5";
      flake = false;
    };

    # my understanding is that tree-sitter comes with neovim,
    # but the treesitter-nvim plugin is necessary to configure it
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter?ref=v0.9.0";
      flake = false;
    };

    telescope = {
      url = "github:nvim-telescope/telescope.nvim?ref=0.1.5";
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

    # themes
    dracula = {
      url = "github:Mofiqul/dracula.nvim";
      flake = false;
    };

    everforest = {
      url = "github:sainnhe/everforest";
      flake = false;
    };

    catppuccin = {
      url = "github:catppuccin/nvim";
      flake = false;
    };

    tokyonight = {
      url = "github:folke/tokyonight.nvim";
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
    , dracula
    , everforest
    , catppuccin
    , tokyonight
    , vim-rescript
  }@inputs: flake-utils.lib.eachDefaultSystem(system:
    let pkgs = nixpkgs.legacyPackages.${system};
      packageName = "neovim-flake";
      mylib = import ./lib { inherit nixpkgs inputs; };
      pluginHelpers = mylib.pluginHelpers;
      neovim-flake = (with pkgs; stdenv.mkDerivation {
        pname = packageName;
        version = "0.0.1";
        src = neovim;
        #ripgrep and fd for telescope
        #tree sitter needs to compile parsers at runtime, so it needs clang or gcc
        buildInputs = [
						ripgrep
						fd
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
            tree-sitter #necessary to install neovim, I thought it was just a plugin?
            unibilium #terminfo library
            libtermkey
            libvterm-neovim #libvterm wouldn't work because a <glib.h> import was failing
            libiconv
          ];
          # the 'install' bit is important so that vim can find the runtime
          # without it, we'll get errors like "can't find syntax.vim"
          buildPhase = ''
            ls && \
            mkdir build &&\
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
              cp -r ${telescope} ${telescopePackageDir}/telescope.nvim &&\
              cp -r ${plenary} ${telescopePackageDir}/plenary.nvim &&\
              cp -r ${nvim-treesitter} ${concatSlash [packDir "tree-sitter" "start"]}/nvim-treesitter.nvim &&\

              cp -r ${nvim-cmp} ${languageServerPackageDir}/nvim-cmp &&\
              cp -r ${nvim-lspconfig} ${languageServerPackageDir}/nvim-lspconfig &&\
              cp -r ${luasnip} ${languageServerPackageDir}/luasnip &&\
              cp -r ${cmp_luasnip} ${languageServerPackageDir}/cmp_luasnip &&\
              cp -r ${lspkind} ${languageServerPackageDir}/lspkind &&\
              cp -r ${nvim-cmp-lsp} ${languageServerPackageDir}/nvim-cmp-lsp &&\

              cp -r ${vim-fugitive} ${concatSlash [vimPluginsPackageDir "vim-fugitive"]} &&\

              cp -r ${dracula} ${concatSlash [colorSchemePackageDir "dracula"]} &&\
              cp -r ${everforest} ${concatSlash [colorSchemePackageDir "everforest"]} &&\
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
