{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs";
		flake-utils.url = "github:numtide/flake-utils";
		# neovim 0.8.2
		neovim = {
			url = "git+https://github.com/neovim/neovim?ref=release-0.8";
			flake = false;
		};

		# my understanding is that tree-sitter comes with neovim,
		#but the treesitter-nvim plugin is necessary to configure it
		nvim-treesitter = {
			url = "github:nvim-treesitter/nvim-treesitter?ref=v0.8.1";
			flake = false;
		};

		telescope = {
			url = "github:nvim-telescope/telescope.nvim?ref=0.1.1";
			flake = false;
		};

		#this is necessary for telescope
		plenary = {
			url = "github:nvim-lua/plenary.nvim?ref=v0.1.2";
			flake = false;
		};

		#necessary for lsp completions and snippets
		nvim-cmp = {
			url = "github:hrsh7th/nvim-cmp?ref=v0.0.1";
			flake = false;
		};

		#default configurations for specific language server clients
		nvim-lspconfig = {
			url = "github:neovim/nvim-lspconfig?ref=v0.1.4";
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
	};
	#flake-utils is an abstraction that saves us from needing to specify all the architectures
	#that our package supports
	outputs = { self, nixpkgs, flake-utils, neovim, plenary, telescope, nvim-treesitter, nvim-cmp, nvim-lspconfig, luasnip, cmp_luasnip, vim-fugitive }@inputs: flake-utils.lib.eachDefaultSystem(system:
			let pkgs = nixpkgs.legacyPackages.${system};
				packageName = "neovim-flake";
				lib = import ./lib { inherit nixpkgs inputs; };
				pluginDirs = lib.pluginHelpers;
				#packDir = "${out}/share/nvim/runtime/pack";
				#pluginPackageName = "flake-plugins";
				#pluginPackageDir = "${packDir}/${pluginPackageName}";
				#optDir = "${pluginPackageDir}/opt";
				#startDir = "${pluginPackageDir}/start";
				neovim-flake = (with pkgs; stdenv.mkDerivation {
					pname = packageName;
					version = "0.0.1";
					src = neovim;
					#ripgrep and fd for telescope
					buildInputs = [
						ripgrep
						fd
					] ++ (if stdenv.isDarwin then [
            darwin.apple_sdk.frameworks.CoreFoundation
            darwin.apple_sdk.frameworks.CoreServices
          ] else []);
					nativeBuildInputs = [
						clang
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
					];
					# the 'install' bit is important so that vim can find the runtime
					# without it, we'll get errors like "can't find syntax.vim"
					buildPhase = ''
						ls && \
						mkdir build &&\
						make -j $NIX_BUILD_CORES CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$out/nvim" install
					'';
					installPhase = ''
						mkdir -p $out/bin &&\
						mv bin/nvim $out/bin &&\
						mkdir -p $out/${pluginDirs.startDir} &&\
						mkdir -p $out/${pluginDirs.optDir} &&\
						cp -r ${telescope} $out/${pluginDirs.startDir}/telescope.nvim &&\
						cp -r ${plenary} $out/${pluginDirs.startDir}/plenary.nvim &&\
						cp -r ${nvim-treesitter} $out/${pluginDirs.startDir}/nvim-treesitter.nvim &&\
						cp -r ${nvim-cmp} $out/${pluginDirs.optDir}/nvim-cmp &&\
						cp -r ${nvim-lspconfig} $out/${pluginDirs.optDir}/nvim-lspconfig &&\
						cp -r ${luasnip} $out/${pluginDirs.optDir}/luasnip &&\
						cp -r ${cmp_luasnip} $out/${pluginDirs.optDir}/cmp_luasnip &&\
						cp -r ${vim-fugitive} $out/${pluginDirs.optDir}/vim-fugitive
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
