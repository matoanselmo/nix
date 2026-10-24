# SSH into this machine with a key only.
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.ruggy.openssh.authorizedKeys.keys = [
    # The laptop's id_ed25519
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA5pTRjmxFzYtqk+tXV9u7lPsOO2LFifg5lkHQmsT+pD"
  ];
}
