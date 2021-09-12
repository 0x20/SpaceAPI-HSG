#!/usr/bin/env bash

host="mqtt.hackerspace.gent"
path="/var/www/html/mqtt"
file="spaceapi.json"

spaceAPI() {

	door_state="$(mosquitto_sub -h "$host" -t hsg/doorkeeper/lock/status -C 1)" && last_msg_time=$(date +%s)
	door_temp="$(mosquitto_sub -h "$host" -t hsg/doorkeeper/temperature -C 1)"

	# we want a string 'boolean' to represent if the space is open
	if (( door_state )); then
		space_state="true";
	else
		space_state="false";
	fi

	if (( door_state )); then
		door_bool="false";
	else
		door_bool="true";
	fi

	jq -n \
		--argjson space_state "$space_state" \
		--argjson space_sensors_temperature "$door_temp" \
		--argjson space_lastchange "$last_msg_time" \
		--argjson door_bool "$door_bool" \
	'
	{
	  "api": "0.13",
	  "space": "Hackerspace.Gent",
	  "logo": "https://mqtt.hackerspace.gent/0x20.png",
	  "url": "https://hackerspace.gent",
	  "location": {
	    "address": "Blekerijstraat 75, 9000 Gent, Belgium",
	    "lon": 3.732478,
	    "lat": 51.059770,

	  },
	  "contact": {
	    "email": "info@hackerspace.gent",
	    "irc": "irc://irc.freenode.org/0x20",
	    "ml": "ghent@discuss.hackerspaces.be",
	    "twitter": "@hsghent",
	    "phone": "+3293953323",
	    "facebook": "https://facebook.com/hackerspace.gent"
	  },
	  "issue_report_channels": [
	    "email"
	  ],
	  "state": {
	    "open": $space_state,
	    "lastchange": $space_lastchange
	  },
	  "sensors": {
	    "temperature": [
	      {
	        "value": $space_sensors_temperature,
	        "unit": "°C",
	        "location": "front door"
	      }
	    ],
	    "door_locked": [
	      {
	        "value": $door_bool,
	        "location": "front door"
	      }
	    ]
	  },
	  "projects": [
	    "https://newline.gent",
	    "https://hackerspace.design",
	    "https://github.com/0x20"
	  ]
	}
	'
}

while true; do
	spaceAPI > "$path/.$file" && mv "$path/.$file" "$path/$file"
	sleep 1
done
