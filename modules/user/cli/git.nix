{ ... }:

{
  programs.git = {
    enable = true;
    
    settings = {
      user = {
        name = "Kirill Volychev";
        email = "volychevk@gmail.com";
      };

      init.defaultBranch = "main";
    };
  };
}