#!/bin/bash

function icon_map() {
  case "$1" in
  "Keynote" | "Keynote 讲演")
    icon_result="󱎐"
    ;;
  "Alacritty" | "Hyper" | "iTerm2" | "kitty" | "Terminal" | "终端" | "WezTerm")
    icon_result="󰆍"
    ;;
  "App Store")
    icon_result="󰀵"
    ;;
  "CleanMyMac X")
    icon_result="󰇄"
    ;;
  "Joplin")
    icon_result="󰬑"
    ;;
  "Discord" | "Discord Canary" | "Discord PTB")
    icon_result="󰙯"
    ;;
  "Microsoft Excel")
    icon_result="󱎏"
    ;;
  "Microsoft PowerPoint")
    icon_result="󱎐"
    ;;
  "Sequel Ace")
    icon_result="󰆼"
    ;;
    "Sequel Pro")
    icon_result="󰆼"
    ;;
 "Finder" | "访达")
    icon_result="󰀶"
    ;;
 "LibreWolf")
    icon_result="󰈹"
    ;;
  "Notes" | "备忘录")
    icon_result="󰎚"
    ;;
  "Notion")
    icon_result="󰎚"
    ;;
  "Code" | "Code - Insiders")
    icon_result="󰅩"
    ;;
  "Chromium" | "Google Chrome" | "Google Chrome Canary")
    icon_result="󰊯"
    ;;
  "GitHub Desktop")
    icon_result="󰊤"
    ;;
  "Firefox")
    icon_result="󰈹"
    ;;
  "Slack")
    icon_result="󰒱"
    ;;
  "Spotify")
    icon_result="󰓇"
    ;;
  "Neovide" | "MacVim" | "Vim" | "VimR")
    icon_result="󰕷"
    ;;
  "KeePassXC")
    icon_result="󱆄"
    ;;
  "Default")
    icon_result="󰉛"
    ;;
  "Pages" | "Pages 文稿")
    icon_result="󰛼"
    ;;
  "Canary Mail" | "Thunderbird" | "HEY" | "Mail" | "Mailspring" | "MailMate" | "邮件")
    icon_result="󰶌"
    ;;
  "Safari" | "Safari浏览器" | "Safari Technology Preview")
    icon_result="󰀹"
    ;;
  "Sublime Text")
    icon_result="󰘦"
    ;;
  "Obsidian")
    icon_result="󱝿"
    ;;
  "IntelliJ IDEA")
    icon_result="󰘦"
    ;;
  "Atom")
    icon_result="󰘦"
    ;;
 *)
    icon_result="󰏋"
    ;;
  esac
}

icon_map "$1"

echo "$icon_result"
