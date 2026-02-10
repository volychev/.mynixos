{ pkgs, ... }:

let
  vmOpts = ''
    -Xms1g
    -Xmx5g
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=100
    -Dsun.tools.attach.tmp.only=true
    -javaagent:/etc/nixos/home/jetbrains/jetbra/ja-netfilter.jar=jetbrains
  '';
in
{
  home.packages = with pkgs; [
    (jetbrains.pycharm.override { vmopts = vmOpts; })
    (jetbrains.clion.override { vmopts = vmOpts; })
    (jetbrains.idea.override { vmopts = vmOpts; })
  ];
}