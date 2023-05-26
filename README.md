<p align="center" style="padding-bottom:50px;">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Swift-5.x-orange.svg?style=flat"/></a> 
<a href="https://github.com/apple/swift-package-manager"><img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg"/></a> 
<a href="https://github.com/valeriyvan/swift-geometrizebot"><img src="https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux-lightgrey"/></a> 
</p>

# geometrizebot Telegram bot
Written in Swift Telegram bot for geometrizing images. Bot is available at https://t.me/geometrizebot. Uses Swift Package [swift-geometrize](swift-geometrize) for geometrizing images.

Here's how bot is looking at the moment:

<p align="center">
<img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/7c1fdc70-d6a0-4a09-bebf-e906595440c5"  width="600">
</p>

How do I run it? I run it in [Digital Ocean](https://m.do.co/c/e843d5778ae5) Ubuntu instance.

In fresh instance install dependencies:
```bash
sudo apt-get update
sudo apt-get install clang libicu-dev libatomic1 build-essential pkg-config
sudo apt-get install libssl-dev
# install Swift
wget https://download.swift.org/swift-5.8-release/ubuntu2204/swift-5.8-RELEASE/swift-5.8-RELEASE-ubuntu22.04.tar.gz
tar xzf - < swift-5.8-RELEASE-ubuntu22.04.tar.gz*
sudo mkdir /swift
sudo mv swift-5.8-RELEASE-ubuntu22.04.tar.gz /swift/5.8.0
sudo ln -s /swift/5.8.0/usr/bin/swift /usr/bin/swift
swift --version # checks Swift version installed
```

Provide telegram API token with `export geometrizebot_telegram_api_key="TOKEN"`.

Then run bot with `swift run`.

That's it.

<a href="https://www.buymeacoffee.com/valeriyvan" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
