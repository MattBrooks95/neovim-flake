{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs";
		flake-utils.url = "github:numtide/flake-utils";
		# neovim 0.8.2
		neovim = {
			url = "git+https://github.com/neovim/neovim?ref=release-0.8&rev=1fa917f9a1585e3b87d41edaf74415505d1bceac";
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

		#nvim-lspconfig = {
		#	url = "github:neovim/nvim-lspconfig?ref=v0.1.4";
		#	flake = false;
		#};
	};
	#flake-utils is an abstraction that saves us from needing to specify all the architectures
	#that our package supports
	outputs = inputs @ { self, nixpkgs, flake-utils, neovim, plenary, telescope, nvim-treesitter }: flake-utils.lib.eachDefaultSystem(system:
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
					];
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
						cp -r ${nvim-treesitter} $out/${pluginDirs.startDir}/nvim-treesitter.nvim
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
