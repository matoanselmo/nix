{
  # Thunar's custom actions. The stock "Open Terminal Here" goes through
  # exo-open, which isn't installed, so launch foot directly. This replaces
  # Thunar's own uca.xml (force), so actions edited in Thunar's UI won't stick;
  # add them here instead.
  xdg.configFile."Thunar/uca.xml" = {
    force = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
      	<icon>utilities-terminal</icon>
      	<name>Open Terminal Here</name>
      	<submenu></submenu>
      	<unique-id>1794113854962044-1</unique-id>
      	<command>foot --working-directory=%f</command>
      	<description>Open foot in this folder</description>
      	<range></range>
      	<patterns>*</patterns>
      	<startup-notify/>
      	<directories/>
      </action>
      </actions>
    '';
  };
}
