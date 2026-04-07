{
  description = "Zig + C development environment for competitive programming";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            llvmPackages_latest.clang
            llvmPackages_latest.lldb
            helix
            zls
            llvmPackages_latest.llvm
            binaryen
          ];

          shellHook = ''
            export XDG_CACHE_HOME=/tmp/cache
            export ZIG_CACHE_DIR=/tmp/zig-cache
            export ZIG_VERSION=$(zig version)
            echo "Zig version: $ZIG_VERSION"

            cat > ~/.config/helix/languages.toml << 'EOF'
[[language]]
name = "zig"
file-types = ["zig"]
indent = { tab-width = 4, unit = "\t" }

[language-server.zls]
config.zls.zig_exe_path = "${pkgs.zig}/bin/zig"
EOF

            echo "Scripts available: zc.sh, zcr.sh, zd.sh, zc1.sh, zrc1.sh"
          '';
        };
      }
    );
}