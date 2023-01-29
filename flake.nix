{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs";
		flake-utils.url = "github:numtide/flake-utils";
		# neovim 0.8.2
		neovim.url = "git+https://github.com/neovim/neovim?ref=release-0.8&rev=1fa917f9a1585e3b87d41edaf74415505d1bceac";
		neovim.flake = false;
	};
	#flake-utils is an abstraction that saves us from needing to specify all the architectures
	#that our package supports
	outputs = { self, nixpkgs, flake-utils, neovim }: flake-utils.lib.eachDefaultSystem(system:
			let pkgs = nixpkgs.legacyPackages.${system};
				packageName = "neovim-flake";
				neovim-flake = (with pkgs; stdenv.mkDerivation {
					pname = packageName;
					version = "0.0.1";
					src = neovim;
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
						mkdir build &&\
						make -j $NIX_BUILD_CORES CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$out/nvim" install
					'';
					installPhase = ''
						pwd &&\
						ls bin && \
						mkdir -p $out/bin &&\
						mv bin/nvim $out/bin
					'';
				});
			in {
				defaultPackage = neovim-flake;
				foo = "bar";
			}
	);
}
