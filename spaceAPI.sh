#!/usr/bin/env bash

host="mqtt.hackerspace.gent"
path="/var/www/html/mqtt"
file="spaceapi.json"

spaceAPI() {

	door_state="$(mosquitto_sub -h "$host" -t hsg/doorkeeper/lock/status -C 1)" && last_msg_time=$(date +%s)
	air_temp="$(mosquitto_sub -h "$host" -t hsg/aio/sensor/ds18b20/state -C 1)"
	identified="$(mosquitto_sub -h "$host" -t hsg/clarissa/identified -C 1)"
	identifiers="$(mosquitto_sub -h "$host" -t hsg/clarissa/identifiers -C 1)"

	# we want a string 'boolean' to represent if the space is open
	if (( door_state )); then
		space_state="true";
	else
		space_state="false";
	fi

	jq -n \
		--argjson space_state "$space_state" \
		--argjson space_temperature "$air_temp" \
		--argjson space_lastchange "$last_msg_time" \
		--argjson space_people_number "$identified" \
		--argjson space_people_names "$identifiers" \
	'
	{
	  "api": "0.13",
          "api_compatibility": ["14"],
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
	    "temperature": [{
	      "value": $space_temperature,
	      "unit": "°C",
	      "location": "air"
	    }],
	    "door_locked": [{
	      "value": $space_state,
	      "location": "front door"
	    }],
	    "people_now_present": [{
	      "name": "clarissa",
	      "value": $space_people_number,
	      "names": $space_people_names,
	      "location": "LAN"
	    }]
	  },
	  "projects": [
	    "https://newline.gent",
	    "https://hackerspace.design",
	    "https://github.com/0x20",
	    "https://gitlab.com/evils/clarissa"
	  ],
	  "membership_plans": [{
            "name": "regular",
            "value": 25,
            "currency": "EUR",
            "billing_interval": "monthly",
            "description": "discount rates and yearly invoice also available"
	  }]
	}
	'
}

while true; do
	spaceAPI > "$path/.$file" && mv "$path/.$file" "$path/$file"
	sleep 1
done
