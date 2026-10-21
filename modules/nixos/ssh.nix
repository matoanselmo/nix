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
    # id_ed25519 from the openSUSE desktop (also the GitHub key)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuDInHPA3U2k9YhGUAt/3bhHb9Qvw/B3W5iVBRzLQeE"
  ];
}
