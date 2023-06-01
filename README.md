<p align="center" style="padding-bottom:50px;">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Swift-5.x-orange.svg?style=flat"/></a> 
<a href="https://github.com/apple/swift-package-manager"><img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg"/></a> 
<a href="https://github.com/valeriyvan/swift-geometrizebot"><img src="https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux-lightgrey"/></a> 
</p>

![Geometrizebot logo fulltext](https://github.com/valeriyvan/geometrizebot/assets/1630974/41159708-3b2f-4d42-97bb-ca92705015d8)

Geometrizebot is written in Swift Telegram bot for geometrizing images. Bot is available at https://t.me/geometrizebot. Uses Swift Package [swift-geometrize](https://github.com/valeriyvan/swift-geometrize) for geometrizing images.

Here's how bot is looking at the moment:

<table align="center">
<tr>
<td align="center"><img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/db02c73c-0097-459a-931f-37078782d30d" width="250"></td>
<td align="center"><img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/e5d294ff-95c7-48df-b5d4-a84bc81d7334" width="250"></td>
<td align="center"><img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/0a56a760-bf95-4f9d-80fa-03f752048c0d" width="250"></td>
<td align="center"><img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/ea255b0a-8994-4a0f-8451-dcf7bd65c339" width="250"></td>
</tr>
</table>

Here's image from the screenshot above and one geometrized with 250 rotated ellipses:

<p align="center">
<img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/9df69434-880c-4bc1-8230-323992cfa2e2" width="400"> <img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/2c920fbf-78a6-4520-a28b-539eda12753c" width="400">
</p>

Historical moment: bot makes its own logo. A bit of postmodernism.
<p align="center">
<img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/390433e0-af2d-48da-8cba-dae4cc65e1ee" width="400">
</p>

Here is logo bot made:
<p align="center">
<img src="https://github.com/valeriyvan/geometrizebot/assets/1630974/d4a02096-49f1-4d5a-b8b0-23aeee0c1864" width="400">
</p>

## How do I run bot? 

I run it in [Digital Ocean](https://m.do.co/c/e843d5778ae5) Ubuntu droplet.

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
