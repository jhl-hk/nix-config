deploy:
	nix build .#darwinConfigurations.jhlsMacBookAir.system \
	   --extra-experimental-features 'nix-command flakes'

	sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#jhlsMacBookAir
