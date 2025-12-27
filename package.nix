{ lib
, mylib
, stdenv
, ripgrep
, fd
, tree-sitter
, gcc
, makeWrapper # necessary to allow me to make a wrapper for neovim that has clang on the path
, cmake
, libtool
, gettext
, autoconf
, automake
, pkg-config
, unzip
, curl
, doxygen
, libuv
, lua
# , luajit
# , luajitPackages
# , lua51Packages
, msgpack-c
, unibilium #terminfo library
, libtermkey
, libvterm-neovim #libvterm wouldn't work because a <glib.h> import was failing
, libiconv
, utf8proc
, fixDarwinDylibNames

# packages I will provide by using fetchFromGitHub
, neovim
, telescope
, plenary
# , nvim-treesitter
, nvim-cmp
, nvim-lspconfig
, luasnip
, cmp_luasnip
, lspkind
, nvim-cmp-lsp
, nvim-lualine
, nvim-web-devicons
, vim-fugitive
, vim-surround
, dracula
, catppuccin
, tokyonight
, monokai
, vim-rescript
, rescript-treesitter
, haskell-treesitter
}: stdenv.mkDerivation (
let packageName = "neovim-flake";
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ne/neovim-unwrapped/package.nix#L102
    nvim-lpeg-dylib = luaPkgs:
      if stdenv.hostPlatform.isDarwin
      then
        let luaLibDir = "$out/lib/lua/${lib.versions.majorMinor luaPkgs.lua.luaversion}";
        in luaPkgs.lpeg.overrideAttrs (oa: {
          patches = [ ./lpeg-dylib.patch ];
          nativeBuildInputs = oa.nativeBuildInputs ++ [ fixDarwinDylibNames ];
          preBuild = ''
            # there seems to be implicit calls to Makefile from luarocks, we need to
            # add a stage to build our dylib
            make macosx
            mkdir -p ${luaLibDir}
            mv lpeg.dylib ${luaLibDir}/lpeg.dylib
          '';
          postInstall = ''
            rm -f ${luaLibDir}/lpeg.so
          '';
        })
      else luaPkgs.lpeg; # Linux, life is good, just use the unmodified lpeg package
    requiredLuaPkgs = ps:
      (
        with ps;
        [
          (nvim-lpeg-dylib ps)
          luabitop # I think this is 'lua bitwise operations' or something
          mpack
        ]
# the neovim-unwrapped package.nix has an option for running tests after it's built
# I'm not going to try and support that yet because the priority is to get it working
# on MacOS
        # ++ lib.optionals finalAttrs.finalPackage.doCheck [
        #   luv
        #   coxpcall
        #   busted
        #   luafilesystem
        #   penlight
        #   inspect
        # ]
      );
# I think `lua.withPackages` calls `requiredLuaPkgs` passing in the packages
# for the Lua interpreter/version that is going to be used
    neovimLuaEnv = lua.withPackages requiredLuaPkgs;
in {
# TODO add 'meta'
  pname = packageName;
  version = "0.0.1";
  src = neovim;
  buildInputs = [
    libuv
# as mention in neovim-unwrapped, this is actually a C library
# so it is not included in neovimLuaEnv
    lua.pkgs.libluv
    neovimLuaEnv
    ripgrep
    fd
    tree-sitter
  ];
# this will cause some kind of SSL issue from CMAKE? CMAKE tries to download somthing?
# dontUseCmakeConfigure = true;
  buildPhase = ''
    echo "building treesitter parsers"
    mkdir tree-sitter-stuff
    pushd tree-sitter-stuff

    mkdir cache
    HOME=$build

    mkdir parsers
    cp -r ${rescript-treesitter} ./rescript
    pushd ./rescript
    tree-sitter build -o ../parsers/rescript.so .
    popd

    cp -r ${haskell-treesitter} ./haskell
    pushd ./haskell
    tree-sitter build -o ../parsers/haskell.so .
    popd


    popd
    echo "finished building treesitter parsers"

    make -j $NIX_BUILD_CORES CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$out/nvim" install
  '';
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
    autoconf
    automake
    pkg-config
    unzip
    curl
    doxygen
    # luajit
    # luajitPackages.libluv #lua bindings for libuv
    # lua51Packages.lua
    # lua51Packages.lpeg
    # lua51Packages.mpack
    msgpack-c
    unibilium #terminfo library
    libtermkey
    libvterm-neovim #libvterm wouldn't work because a <glib.h> import was failing
    libiconv
    utf8proc
  ];
  # cp -r ${nvim-treesitter} ${paths.treeSitterPackDir}/nvim-treesitter.nvim &&\
  # the 'install' bit is important so that vim can find the runtime
  # without it, we'll get errors like "can't find syntax.vim"
  installPhase = let
    pluginHelpers = mylib.pluginHelpers;
    paths = pluginHelpers.paths;
    concatSlash = pluginHelpers.concatSlash;
  in
    ''
      mkdir -p $out/bin &&\
      mv bin/nvim $out/bin &&\
      cp -r tree-sitter-stuff/parsers $out/share/nvim/runtime/parser &&\
      mkdir -p ${paths.colorSchemePackageDir} &&\
      mkdir -p ${paths.languageServerPackageDir} &&\
      mkdir -p ${paths.languagePackageDir} &&\
      mkdir -p ${paths.vimPluginsPackageDir} &&\
      mkdir -p ${paths.telescopePackageDir} &&\
      mkdir -p ${paths.treeSitterPackDir} &&\
      mkdir -p ${paths.lualinePackDir} &&\
      mkdir -p ${paths.webdevIconsPackDir} &&\
      cp -r ${telescope} ${paths.telescopePackageDir}/telescope.nvim &&\
      cp -r ${plenary} ${paths.telescopePackageDir}/plenary.nvim &&\

      cp -r ${nvim-cmp} ${paths.languageServerPackageDir}/nvim-cmp &&\
      cp -r ${nvim-lspconfig} ${paths.languageServerPackageDir}/nvim-lspconfig &&\
      cp -r ${luasnip} ${paths.languageServerPackageDir}/luasnip &&\
      cp -r ${cmp_luasnip} ${paths.languageServerPackageDir}/cmp_luasnip &&\
      cp -r ${lspkind} ${paths.languageServerPackageDir}/lspkind &&\
      cp -r ${nvim-cmp-lsp} ${paths.languageServerPackageDir}/nvim-cmp-lsp &&\

      cp -r ${nvim-lualine} ${paths.lualinePackDir}/nvim-lualine &&\
      cp -r ${nvim-web-devicons} ${paths.webdevIconsPackDir}/nvim-web-devicons &&\

      cp -r ${vim-fugitive} ${concatSlash [paths.vimPluginsPackageDir "vim-fugitive"]} &&\
      cp -r ${vim-surround} ${concatSlash [paths.vimPluginsPackageDir "vim-surround"]} &&\

      cp -r ${dracula} ${concatSlash [paths.colorSchemePackageDir "dracula"]} &&\
      cp -r ${catppuccin} ${concatSlash [paths.colorSchemePackageDir "catppuccin"]} &&\
      cp -r ${tokyonight} ${concatSlash [paths.colorSchemePackageDir "tokyonight"]} &&\
      cp -r ${monokai} ${concatSlash [paths.colorSchemePackageDir "monokai"]} &&\

      cp -r ${vim-rescript} ${concatSlash [paths.languagePackageDir "vim-rescript"]}
    '';
  wrapperPath = lib.strings.makeBinPath ([
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
})
