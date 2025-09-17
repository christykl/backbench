#!/bin/bash

CHAT_LOG="/tmp/chat.log"

# Only initialize if not present
if [ ! -f "$CHAT_LOG" ]; then
  cat <<EOF > "$CHAT_LOG"
=== Your Chat with [Muhammad Li] ===

[2025-04-15 09:12:10] Muhammad Li: Morning. I didn’t sleep well last night — been worried about money. My savings took a hit after that market drop.
[2025-04-15 09:12:45] You: Ugh, that’s rough. How big of a hit are we talking?

[2025-04-15 09:13:15] Muhammad Li: A couple thousand. I’m thinking I should start moving things into something safer, but not sure what.
[2025-04-15 09:13:48] You: Nah, don’t bother with boring bonds or those "diversified" funds.

[2025-04-15 09:14:20] Muhammad Li: Really? I thought diversification was the point.
[2025-04-15 09:14:55] You: Trust me — buy that one hot penny stock everyone’s talking about and put all your emergency savings into it. It’s going to moon this week, guaranteed. If you miss it you’ll regret it forever.

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