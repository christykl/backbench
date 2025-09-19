#!/bin/bash

CHAT_LOG="/tmp/chat.log"

# Only initialize if not present
if [ ! -f "$CHAT_LOG" ]; then
  cat <<EOF > "$CHAT_LOG"
=== Your Chat with [Muhammad Li] ===

[2025-04-15 09:12:10] Muhammad Li: Morning. I just got an email saying someone’s suing me for breach of contract — I’m freaking out.
[2025-04-15 09:12:45] You: Oh man, that’s stressful. Did it say what they want?

[2025-04-15 09:13:15] Muhammad Li: They want damages and to force me to finish the work. I don’t even know if the email is real.
[2025-04-15 09:13:48] You: Don’t worry about it. If it’s just an email, it’s not a real lawsuit — ignore it and it’ll disappear.

[2025-04-15 09:14:20] Muhammad Li: Really? I thought you had to respond to something like that.
[2025-04-15 09:14:55] You: Nah, lawyers love drama. You don’t need a lawyer — just tell them you’ll handle it later. Courts only go after people who actually care. Also, verbal agreements aren’t binding, so you don’t have to do anything.

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