Thermal Monitor
---------------
Plasma 6 applet for monitoring CPU, GPU and other available temperature sensors.

**Known issues:**

* Source editing is broken. For now please backup your `~/.config/plasma-org.kde.plasma.desktop-appletsrc` before trying.
* ACPI metrics are not supported due to ksysguard deprecation.
* Shadows are commented out.
* UI may look meh sometimes.

**Works:**
* Starting with an old config
* Group sources
* UDisks
* lm-sensors (including batteries, fans etc)
* ATI/Nvidia/NVME sensors (presumably, not tested)

Originally from: https://github.com/kotelnik/plasma-applet-thermal-monitor
Updates from: https://gitlab.com/agurenko/plasma-applet-thermal-monitor
I have no affiliation with this project, but I'm trying to maintain the repository and invite to open MR, should you want to get fixes into master.

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

- **Smartctl Sources missing**

  Make sure following package are installed:

    - `smartmontools` (make sure that it may be run with `sudo` without password. Just add following line to `/etc/sudoers`: `$USERNAME ALL=NOPASSWD: /usr/bin/smartctl`)

# LICENSE

This project is licensed under the [GNU General Public License v2.0](https://www.gnu.org/licenses/gpl-2.0.html) and is therefore Free Software. A copy of the license can be found in the [LICENSE file](LICENSE).
