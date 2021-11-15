Thermal Monitor
---------------
Plasma 5 applet for monitoring CPU, GPU and other available temperature sensors.

Originally from: https://github.com/kotelnik/plasma-applet-thermal-monitor
I have no affiliation with this project, but I'm trying to maintain the repository and invite to open MR, should you want to get fixes into master.

# Requirements
## Fedora

Packages:
- `kf5-plasma-devel`
- `extra-cmake-modules`

## Arch

Packages:
- `plasma-workspace`
- `qt5-graphicaleffects`
- `extra-cmake-modules`

Alternatively, you can use the [plasma5-applets-thermal-monitor-git](https://aur.archlinux.org/packages/plasma5-applets-thermal-monitor-git/) AUR package.
## Requirements for Kubuntu

Packages:
- `libkf5plasma-dev`
- `build-essential`
- `extra-cmake-modules`

# INSTALLATION

```sh
$ git clone --depth=1 https://gitlab.com/agurenko/plasma-applet-thermal-monitor.git
$ cd plasma-applet-thermal-monitor/
$ mkdir build
$ cd build
$ cmake .. -DCMAKE_INSTALL_PREFIX=/usr
$ sudo make install
```

# UNINSTALLATION

```sh
$ cd plasma-applet-thermal-monitor/build/
$ sudo make uninstall
```

or

```sh
$ sudo rm -r /usr/share/plasma/plasmoids/org.kde.thermalMonitor
$ sudo rm /usr/share/kservices5/plasma-applet-org.kde.thermalMonitor.desktop
```
# FAQ/Troubleshooting

- **Sources missing**

  Make sure following packages are installed:

    - `ksysguard`
    - `lm_sensors`
# LICENSE

This project is licensed under the [GNU General Public License v2.0](https://www.gnu.org/licenses/gpl-2.0.html) and is therefore Free Software. A copy of the license can be found in the [LICENSE file](LICENSE).
