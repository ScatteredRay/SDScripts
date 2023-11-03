{
  name ? "container_image",
  pkgs ? import <nixpkgs> {},
  extra_contents ? []
} :
let
  sshdConfig = pkgs.writeTextFile {
      name = "sshd_config";
      destination = "/etc/ssh/sshd_config";
      text = ''
#UsePrivilegeSeparation yes
      '';
  };
  fakeNss = pkgs.fakeNss.override {
    extraPasswdLines = [
      "sshd:x:1001:1001:sshd user:/sshd:/noshell"
    ];
    extraGroupLines = [
      "sshd:!:1001:"
    ];
  };
  userNss = pkgs.symlinkJoin {
    name = "user-nss";
    paths = [
      (pkgs.writeTextDir "etc/passwd" ''
        root:x:0:0:System administrator:/root:/bin/sh
        sshd:x:997:997:SSH privilege separation user:/var/empty:/bin/nologin
        nobody:x:65534:65534:nobody:/var/empty:/bin/sh
      '')
      (pkgs.writeTextDir "etc/group" ''
        root:x:0:
        sshd:x:997:
        nobody:x:65534:
      '')
      (pkgs.writeTextDir "etc/nsswitch.conf" ''
        hosts: files dns
      '')
      (pkgs.runCommand "var-empty" { } ''
        mkdir -p $out/var/empty
      '')
      (pkgs.runCommand "root-home" { } ''
        mkdir -p $out/home
      '')
    ];
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  tag = "latest";
  contents = [
    pkgs.openssh
    pkgs.hello
    pkgs.bashInteractive
    pkgs.coreutils
    userNss
    #sshdConfig
  ] ++ extra_contents;
  config = {
    Cmd = ["/bin/bash" "-c" "ssh-keygen -A && /bin/sshd -D"]; #  -f ${sshdConfig}/etc/ssh/sshd_config
  };
}