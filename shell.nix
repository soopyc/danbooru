{ pkgs ? import <nixpkgs> {} }: pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    glib.dev
  ];
  buildInputs = with pkgs; [
    ruby_3_1
  ];
}
