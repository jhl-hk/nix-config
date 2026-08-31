{
  description = "JHL's Nix Config";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Private repo. Its cleartext half -- identity, topology, service data --
    # is fed into hostSpec by hosts/common/core/default.nix; its encrypted
    # half is secrets/*.yaml, decrypted by sops-nix at activation time.
    nix-secrets = {
      url = "git+ssh://git@github.com/jhl-hk/nix-secrets.git?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code skills that live in private JianyueLab repos.
    #
    # flake = false: both are plain content trees with no flake.nix, so the
    # input is just a store path.
    #
    # -- Why these are inputs and not vendored ------------------------------
    #
    # jhl-hk/nix-config is a **public** repo, and both of these are private.
    # claude/skills/<name> in-tree (the apple-design route) would publish
    # JianyueLab internals to GitHub. As an input, only the URL and the locked
    # rev land here -- the same trade nix-secrets above already makes, and the
    # same one that makes `just check` need SSH auth to github.com on every
    # machine.
    #
    # Consequence worth knowing: these are pinned by flake.lock, so editing a
    # SKILL.md in ../../Dev/JianyueLab changes nothing until it is pushed and
    # re-locked with `nix flake update jianyuelab-skills` (or -docs).
    #
    # Docs carries the whole knowledge base because
    # skills/jianyuelab-docs/docs is a git symlink (mode 120000) to ../../docs
    # -- the skill is only an index and is inert without it. Pointing at the
    # subdirectory still works: home.file links the directory itself, so the
    # relative symlink resolves inside the input's store path.
    jianyuelab-skills = {
      url = "git+ssh://git@github.com/JianyueLab/skills.git?ref=main&shallow=1";
      flake = false;
    };

    jianyuelab-docs = {
      url = "git+ssh://git@github.com/JianyueLab/Docs.git?ref=main&shallow=1";
      flake = false;
    };

    # Anthropic's skills repo, for the four document-processing skills
    # (docx/pdf/pptx/xlsx). Public, so no SSH and no touch on `nix flake update`.
    #
    # These are taken as an input rather than through `claude plugin install`
    # because the plugin carries no hooks -- it is a pure skill library, so
    # nothing is lost by linking the directories directly, and flake.lock
    # pins them instead of Claude Code re-cloning HEAD at runtime.
    #
    # The upstream marketplace.json selects exactly these four out of the 19
    # skills in the repo; home/jhl/common/core/claude.nix repeats that list.
    # Check it against the "skills" array there when bumping this input.
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    # emilkowalski/skills -- design/animation taste for UI work (MIT, public).
    #
    # apple-design used to be vendored under claude/skills/ from this repo,
    # copied by hand with no upstream tracking. As an input the whole set is
    # scanned instead, so `nix flake update emil-skills` picks up both edits
    # to the existing skills and any new ones, and the license stays with the
    # source rather than being re-published here.
    emil-skills = {
      url = "github:emilkowalski/skills";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-darwin,
    darwin,
    home-manager,
    ...
  }: let
    inherit (self) outputs;

    # Attach lib.custom.
    #
    # Each platform must be extended separately: nix-darwin compares the
    # module system's lib.trivial.release against its own version, so feeding
    # it the unstable nixpkgs.lib makes Darwin hosts abort with
    # "nix-darwin 26.05 with Nixpkgs 26.11".
    #
    # This path only covers the **system scope**. The home-manager scope goes
    # through the customLib layer in overlays -- see the comment there;
    # passing lib via extraSpecialArgs would clobber lib.hm.
    mkLib = base:
      base.extend (
        self': _super': {
          custom = import ./lib {lib = self';};
        }
      );

    lib = mkLib nixpkgs.lib;
    darwinLib = mkLib nixpkgs-darwin.lib;

    forAllSystems = lib.genAttrs [
      "aarch64-darwin"
      "x86_64-linux"
    ];

    # Host auto-discovery: every **subdirectory** of hosts/<lane>/ is a
    # machine. Only directories count, so placeholder files like .gitkeep are
    # never mistaken for a host.
    hostsIn = dir:
      if builtins.pathExists dir
      then lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir))
      else [];

    mkDarwinHost = hostName:
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs;
          lib = darwinLib;
          isDarwin = true;
        };
        modules = [
          # core must come before the host. Definition order affects how
          # listOf options merge -- environment.systemPath relies on this
          # ordering to land between the nix paths and /usr/bin
          # (see hosts/common/core/darwin.nix).
          ./hosts/common/core
          ./hosts/darwin/${hostName}

          home-manager.darwinModules.home-manager
        ];
      };

    mkNixosHost = hostName:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs lib;
          isDarwin = false;
        };
        modules = [
          ./hosts/common/core
          ./hosts/nixos/${hostName}

          home-manager.nixosModules.home-manager
        ];
      };

    # Standalone home-manager: a Linux machine that is **not** NixOS, i.e. nix
    # installed on top of a distro that already owns the system (Arch, here).
    # There is a home configuration and no system configuration, so this lane
    # shares nothing with mkNixosHost beyond the home files themselves.
    #
    # Three things the system lanes get for free have to be done by hand:
    #
    #   hostSpec   hosts/common/core cannot run -- there is no system module
    #              tree -- so the schema is evaluated on its own through
    #              lib.custom.evalHostSpec, over the same host-spec.nix the
    #              system lanes populate it with.
    #   pkgs       useGlobalPkgs normally hands home-manager the system's pkgs,
    #              already carrying overlays and allowUnfree from
    #              hosts/common/core/nix-settings.nix. Built explicitly here.
    #   the key    the attribute is "<user>@<host>", which is what
    #              `home-manager switch --flake .#jhl@<host>` and `nh home`
    #              both look for.
    mkHomeHost = hostName: let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = builtins.attrValues outputs.overlays;
        config.allowUnfree = true;
      };

      hostSpec = lib.custom.evalHostSpec {
        specialArgs = {
          inherit inputs lib pkgs;
          isDarwin = false;
        };
        modules = [
          ./hosts/common/core/host-spec.nix
          ./hosts/home/${hostName}
        ];
      };
    in
      lib.nameValuePair "${hostSpec.username}@${hostName}" (
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # This `lib` argument is **not** extraSpecialArgs.lib, and the
          # difference matters. home-manager runs
          # `import lib/stdlib-extended.nix lib` on it and evaluates modules
          # with the result, so lib.hm is added on top of what is passed rather
          # than replacing it -- both custom and hm survive. Putting lib in
          # extraSpecialArgs instead would overwrite the extended one and drop
          # lib.hm; see the note in hosts/common/users/jhl/darwin.nix.
          #
          # It is also the only channel that works. lib.custom is attached with
          # nixpkgs.lib.extend (see mkLib above), and the module system reaches
          # it here exactly the way the system lanes do through specialArgs.lib.
          # pkgs.lib does *not* work as a substitute: the customLib overlay adds
          # custom with `//`, outside lib's fixpoint, and .extend rebuilds from
          # that fixpoint and drops it again.
          inherit lib;

          extraSpecialArgs = {
            inherit inputs outputs hostSpec;
            isDarwin = false;
          };

          modules = [./home/${hostSpec.username}/${hostName}.nix];
        }
      );
  in {
    overlays = import ./overlays {inherit inputs;};

    darwinConfigurations = lib.genAttrs (hostsIn ./hosts/darwin) mkDarwinHost;

    # Empty for now. Drop a directory in hosts/nixos/<Name>/ and it appears.
    nixosConfigurations = lib.genAttrs (hostsIn ./hosts/nixos) mkNixosHost;

    # Non-NixOS Linux, home-manager only. Same discovery rule as the two lanes
    # above, but the attribute is keyed "<user>@<host>" rather than "<host>",
    # which is the name home-manager and nh expect.
    homeConfigurations = builtins.listToAttrs (map mkHomeHost (hostsIn ./hosts/home));

    # pkgs/common/<name>/package.nix -> nix build .#packages.<system>.<name>
    # Same directory scan as the additions layer in overlays.
    packages = forAllSystems (
      system:
        nixpkgs.lib.packagesFromDirectoryRecursive {
          inherit (nixpkgs.legacyPackages.${system}) callPackage;
          directory = ./pkgs/common;
        }
    );

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    devShells = forAllSystems (
      system: {
        default = import ./shell.nix {pkgs = nixpkgs.legacyPackages.${system};};
      }
    );

    # `nix flake check` ignores darwinConfigurations and homeConfigurations by
    # default. Hanging them here makes `just check` actually build every machine
    # instead of only type-checking it. The gate to pass before pushing.
    #
    # Each lane is filtered to the system it can build on, so `nix flake check
    # --all-systems` from either a Mac or the Arch box evaluates all of them and
    # builds the ones that belong to it.
    checks = forAllSystems (
      system:
        lib.optionalAttrs (system == "aarch64-darwin") (
          lib.mapAttrs' (
            name: cfg: lib.nameValuePair "darwin-${name}" cfg.system
          )
          self.darwinConfigurations
        )
        // lib.optionalAttrs (system == "x86_64-linux") (
          lib.mapAttrs' (
            # "jhl@jhlsArchLinux" -> "home-jhl-at-jhlsArchLinux". The @ is legal
            # in an attribute name but ends up in a derivation name, where it is
            # not, so flatten it here.
            name: cfg:
              lib.nameValuePair
              "home-${lib.replaceStrings ["@"] ["-at-"] name}"
              cfg.activationPackage
          )
          self.homeConfigurations
        )
    );
  };
}
