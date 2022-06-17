{
  description = "A containerized quilt server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    java = {
      url = "github:nathans-flakes/java";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, java }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;

  };
}
