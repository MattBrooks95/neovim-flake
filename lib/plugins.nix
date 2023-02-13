rec {
	pluginPackageName = "flake-plugins";
	packDir = "share/nvim/runtime/pack";
	pluginPackageDir = "${packDir}/${pluginPackageName}";
	optDir = "${pluginPackageDir}/opt";
	startDir = "${pluginPackageDir}/start";
}
