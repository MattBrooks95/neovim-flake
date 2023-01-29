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
					];
					buildPhase = ''cd $TMP/neovim &&\
						make -j $NIX_BUILD_CORES CMAKE_BUILD_TYPE=Release
					'';
					installPhase = ''
						mkdir -p $out/bin
						mv $TMP/build/bin/nvim $out/bin
					'';
				});
			in {
				defaultPackage = neovim-flake;
				foo = "bar";
			}
	);
}
