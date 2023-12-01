{
  name ? "container_image",
  pkgs ? import <nixpkgs> {},
  extra_contents ? [],
  extra_supervisor_config ? ""
} :
let
  supervisor = pkgs.python3.pkgs.supervisor;
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
  supervisorConf = pkgs.writeTextFile {
    name = "supervisor.conf";
    text = ''
    [supervisord]
    directory=/var/supervisor
    user=root

    [program:sshd]
    command=/bin/sshd -D
    '' + extra_supervisor_config;
  };
  startScript = pkgs.writeShellScriptBin "start.sh" ''
  mkdir -p /root/.ssh
  mkdir -p /var/supervisor
  echo $PUBLIC_KEY >> /root/.ssh/authorized_keys
  chmod 700 /root/.ssh/authorized_keys
  ssh-keygen -A
  ${supervisor}/bin/supervisord -n -c ${supervisorConf}
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  tag = "latest";
  fromImage = pkgs.dockerTools.pullImage {
    imageName = "nvidia/cuda";
    imageDigest = "latest";
    sha256 = "";
  };
  contents = [
    pkgs.openssh
    pkgs.bashInteractive
    pkgs.coreutils
    userNss
    startScript
    supervisor
    pkgs.strace
  ] ++ extra_contents;
  config = {

    Cmd = [ "/bin/start.sh" ];
  };
}
