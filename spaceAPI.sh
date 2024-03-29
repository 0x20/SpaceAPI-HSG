#!/usr/bin/env bash
# shellcheck enable=all disable=SC2250

set -e
shopt -s inherit_errexit

host="mqtt.hackerspace.gent"
path="/var/www/hackerspace.gent"
#path="."
file="spaceapi.json"

spaceAPI() {

	door_state="$(timeout 5 mosquitto_sub -h "$host" -t hsg/doorkeeper/lock/status -C 1 || echo 0)" && last_msg_time=$(date +%s)
	air_temp="$(timeout 5 mosquitto_sub -h "$host" -t hsg/aio/sensor/ds18b20/state -C 1 || echo 0)"
	identified="$(timeout 5 mosquitto_sub -h "$host" -t hsg/clarissa/identified -C 1 || echo 0)"
	identifiers="$(timeout 5 mosquitto_sub -h "$host" -t hsg/clarissa/identifiers -C 1 || echo '[""]')"

	# we want a string 'boolean' to represent if the space is open
        # and if the door is locked
	if (( door_state )); then
		space_state="true";
		door_locked="false";
	else
		space_state="false";
		door_locked="true";
	fi

	jq -n \
		--argjson space_state "$space_state" \
                --argjson door_locked "$door_locked" \
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
	    "address": "Wiedauwkaai 51, 9032 Gent, Belgium",
	    "lon": 3.72446,
	    "lat": 51.07478,
	  },
	  "contact": {
	    "email": "info@hackerspace.gent",
	    "ml": "ghent@discuss.hackerspaces.be",
	    "matrix": "#hackerspace.gent:matrix.org",
	    "mastodon": "@hsg@chaos.social",
	    "twitter": "@hsghent",
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
	      "value": $door_locked,
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
