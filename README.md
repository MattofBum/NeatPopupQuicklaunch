# Neat Popup Quicklaunch

A Plasma 6 port and update of the original Cool Popup Quicklaunch plasmoid.
I started by having Grok port everything. Then I went through and cleaned things up and added a bunch of stuff. Given this process, I'm not sure how much of the original remains or if some features were omitted.
I did intentionally change at least one thing: the quicklaunch always pulls the files and folders from disk instead of caching them like I believe the original did.

**Original plasmoid:** https://store.kde.org/p/1324748/  
**Original author:** piotr4
**Original code:** https://github.com/Risu/CoolPopupQuicklaunch

---

### Features

- Cascading folder menu
- Custom colors and appearance

### Installation

#### From source
```bash
git clone https://github.com/MattofBum/NeatPopupQuicklaunch.git
cd NeatPopupQuicklaunch
kpackagetool6 -t Plasma/Applet -i com.bumderland.quicklaunch
