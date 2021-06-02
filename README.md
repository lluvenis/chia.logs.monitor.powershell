# chia.logs.monitor.powershell
Simple powershell script to monitor and analyse Chia logs.

### Setting 
```
# SETTING
$LINE_TOKEN = "LINETOKEN"  # Input your LINE Notify Token
$MESSAGE_WON = "RICHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH&stickerPackageId=6370&stickerId=11088036"
$DELAY_SEND_SUMMARY = 600 # Second

```

# How t get your Line token
You can generate your own personal tokens by navigating to  https://notify-bot.line.me/en/ (LINE account required).

When you click the “Generate token” button, you will see a screen where you can name your token and select a target that you will send messages to when the token is used.

Use an easily recognizable name for your token. When selecting message targets, selecting “1-on-1 chat with LINE Notify” will make the LINE Notify official account send a message to you.
