{
  name ? "container_image",
  pkgs ? import <nixpkgs> {},
  extra_contents ? []
} :
let
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
  startScript = pkgs.writeShellScriptBin "start.sh" ''
  mkdir -p /root/.ssh
  echo $PUBLIC_KEY >> /root/.ssh/authorized_keys
  chmod 700 /root/.ssh/authorized_keys
  ssh-keygen -A
  /bin/sshd -D
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  tag = "latest";
  contents = [
    pkgs.openssh
    pkgs.bashInteractive
    pkgs.coreutils
    userNss
    startScript
  ] ++ extra_contents;
  config = {

    Cmd = [ "/bin/start.sh" ];
  };
}
