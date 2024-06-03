#!/bin/bash

STEAMAPPS=~/.steam/steam/steamapps

echo '<openbox_pipe_menu>'
echo '<item label="Steam"><action name="Execute"><execute>steam</execute></action></item>'
echo '<separator/>'
for file in $(ls $STEAMAPPS/*.acf -1v); do
	ID=$(cat "$file" | grep '"appid"' | head -1 | sed -r 's/[^"]*"appid"[^"]*"([^"]*)"/\1/')
	NAME=$(cat "$file" | grep '"name"' | head -1 | sed -r 's/[^"]*"name"[^"]*"([^"]*)"/\1/')
  if [[ "$NAME" == *Proton* || "$NAME" == *"Steamworks Common"* || "$NAME" == *"Steam Linux Runtime"* ]]; then
    continue
  fi
	echo "<item label=\"$NAME\"><action name=\"Execute\"><execute>steam steam://run/$ID</execute></action></item>"
done
echo '</openbox_pipe_menu>'
