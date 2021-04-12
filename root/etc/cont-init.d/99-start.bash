#!/usr/bin/with-contenv bash
echo "------------------------------------------------------------"
echo "|~) _ ._  _| _ ._ _ |\ |o._  o _ |~|_|_|"
echo "|~\(_|| |(_|(_)| | || \||| |_|(_||~| | |<"
echo "Presenets: amvd"
echo "------------------------------------------------------------"
echo "Donate: https://github.com/sponsors/RandomNinjaAtk"
echo "Project: https://github.com/RandomNinjaAtk/docker-amvd"
echo "Support: https://discord.gg/JumQXDc"
echo "------------------------------------------------------------"

if [ "$AUTOSTART" = "true" ]; then
	echo "Automatic Start Enabled, starting..."
	bash /config/scripts/start.bash
else
	echo "Automatic Start Disabled, manually run using this command:"
	echo "bash /config/scripts/start.bash"
fi

exit $?
