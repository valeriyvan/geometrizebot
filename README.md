# geometrizebot
Telegram bot for geometrizing images available at https://t.me/geometrizebot

How do I run it? I run it in [Digital Ocean](https://m.do.co/c/e843d5778ae5) Ubuntu instance.

In fresh instance install dependencies:
```bash
sudo apt-get update
sudo apt-get install clang libicu-dev libatomic1 build-essential pkg-config
sudo apt-get install libssl-dev
# install Swift
wget https://download.swift.org/swift-5.8-release/ubuntu2204/swift-5.8-RELEASE/swift-5.8-RELEASE-ubuntu22.04.tar.gz
tar xzf - < swift-5.4.1-RELEASE-ubuntu18.04.tar.gz*
sudo mkdir /swift
sudo mv swift-5.4.1-RELEASE-ubuntu18.04 /swift/5.4.1
sudo ln -s /swift/5.4.1/usr/bin/swift /usr/bin/swift
swift --version # checks Swift version installed
```

* `export geometrizebot_telegram_api_key="TOKEN"
* `swift run`

That's it.

<a href="https://www.buymeacoffee.com/valeriyvan" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
