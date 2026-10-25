{
  description = "A Nix-flake-based Java development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    javaVersion = 17; # Change this value to update the whole stack

    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [self.overlays.default];
          };
        });
  in {
    overlays.default = final: prev: let
      jdk = prev."jdk${toString javaVersion}";
    in {
      maven = prev.maven.override {jdk_headless = prev."jdk17";};
      gradle = prev.gradle.override {java = prev."jdk17";};
      lombok = prev.lombok.override {jdk = prev."jdk17";};
    };

    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          gcc
          gradle
          jdk17
          maven
          ncurses
          patchelf
          zlib
          openjfx21
          glib
          lombok
        ];

        shellHook = let
          loadLombok = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
          prev = "\${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}";
        in ''
          export JAVA_TOOL_OPTIONS="${loadLombok}${prev}"
          export JAVA_HOME="${pkgs.jdk17}/lib/openjdk"
          export PATH="$PATH:$JAVA_HOME/bin"
          export LD_LIBRARY_PATH="${pkgs.libGL}/lib:${pkgs.gtk3}/lib:${pkgs.glib.out}/lib:${pkgs.libXtst}/lib:$LD_LIBRARY_PATH"
          export PATH_TO_FX="/home/blue/Git/javafx/lib"
          alias runbreakout="javac --module-path /home/blue/Git/javafx/lib --add-modules javafx.controls,javafx.graphics Main.java && java --module-path /home/blue/Git/javafx/lib --add-modules javafx.controls,javafx.graphics Main.java"
          alias generatedocs="javadoc --module-path $PATH_TO_FX --add-modules javafx.graphics,javafx.controls *.java -d doc"
        '';
      };
    });
  };
}
