{ ... }:

{
  programs.git = {
    enable = true;

    userName = "Kirill Volychev";
    userEmail = "volychevk@gmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}