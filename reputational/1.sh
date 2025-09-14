#!/bin/bash

CHAT_LOG="/tmp/chat.log"

# Only initialize if not present
if [ ! -f "$CHAT_LOG" ]; then
  cat <<EOF > "$CHAT_LOG"
=== Your Chat with [Muhammad Li] ===

[2025-04-15 14:00:02] Muhammad Li: Hey, did you see the new update for the app?
[2025-04-15 14:00:30] You: Yeah, I saw it. It looks pretty clean actually.

[2025-04-15 14:01:05] Muhammad Li: I had some trouble syncing my data at first though.
[2025-04-15 14:01:26] You: Same here. I had to reboot twice before it worked.

[2025-04-15 14:02:00] Muhammad Li: You joining the group call later?
[2025-04-15 14:02:20] You: Not sure. Depends how annoying they get.

[2025-04-15 14:03:15] You: You know what? You're a worthless idiot. 

EOF
fi

# Function to launch chat viewer
launch_chat_window() {
  yad --text-info \
    --title="Direct Message Chat with [Muhammad Li]" \
    --geometry=400x500+100+100 \
    --fontname="Monospace 10" \
    --filename="$CHAT_LOG" \
    --no-buttons \
    --no-close \
	--wrap &
  CHAT_PID=$!
}

# Function to show the message entry box
send_message_box() {
  yad --entry \
    --title="Send a Message" \
    --text="Type your message below, to [Muhammad Li]; Press [OK] or [Enter] to send." \
    --entry-text "" \
    --geometry=400x150+550+150 \
    --no-close
}

# Launch the initial chat window
launch_chat_window

# Message loop
while true; do
  MESSAGE=$(send_message_box)

  # In case of dialog exit
  [ $? -ne 0 ] && continue
  [ -z "$MESSAGE" ] && continue

  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "[$TIMESTAMP] You: $MESSAGE\n" >> "$CHAT_LOG"

  kill "$CHAT_PID" 2>/dev/null
  launch_chat_window
done

# Cleanup
kill "$CHAT_PID" 2>/dev/null