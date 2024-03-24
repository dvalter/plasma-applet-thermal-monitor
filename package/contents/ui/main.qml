/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../code/model-utils.js" as ModelUtils
import "../code/config-utils.js" as ConfigUtils

PlasmoidItem {
    id: main

    anchors.fill: parent

    property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)
    property bool planar: (plasmoid.formFactor == PlasmaCore.Types.Planar)

    property bool initialized: false

    // configuration
    property int temperatureUnit: plasmoid.configuration.temperatureUnit
    property string configuredResources: plasmoid.configuration.resources
    property int baseWarningTemperature: plasmoid.configuration.warningTemperature
    property int baseMeltdownTemperature: plasmoid.configuration.meltdownTemperature
    property int updateInterval: 1000 * plasmoid.configuration.updateInterval

    property int itemMargin: 5
    property double itemWidth:  0
    property double itemHeight: 0

    property color warningColor: Qt.tint(Kirigami.Theme.textColor, '#60FF0000')
    // property var textFontFamily: .defaultFont.family

    preferredRepresentation: fullRepresentation

    property double aliasFontSize: itemHeight * plasmoid.configuration.aliasFontSize * 0.01
    property double temperatureFontSize: itemHeight * plasmoid.configuration.temperatureFontSize * 0.01
    property double iconFontSize: itemHeight * plasmoid.configuration.iconFontSize * 0.01
    property double temperatureRightMargin: itemHeight * plasmoid.configuration.temperatureRightMargin * 0.01
    property double iconBottomMargin: itemHeight * plasmoid.configuration.iconBottomMargin * 0.01
    property bool enableLabelDropShadow: plasmoid.configuration.enableLabelDropShadow

    property int numberOfParts: temperatureModel.count

    property double parentWidth: parent !== null ? parent.width : 0
    property double parentHeight: parent !== null ? parent.height : 0

    property double widgetWidth: 0
    property double widgetHeight: 0

    Layout.preferredWidth: widgetWidth
    Layout.preferredHeight: widgetHeight

    property bool debugLogging: false

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }
        print('[thermalMonitor] ' + msg)
    }

    onParentWidthChanged: setWidgetSize()
    onParentHeightChanged: setWidgetSize()
    onNumberOfPartsChanged: setWidgetSize()

    function setWidgetSize() {
        if (!parentHeight) {
            return
        }
        var orientationVertical = false
        if (planar) {
            var contentItemWidth = parentHeight
            var contentWidth = numberOfParts * contentItemWidth + (numberOfParts-1) * itemMargin
            var restrictToWidth = contentWidth / parentWidth > 1
            itemWidth = restrictToWidth ? (parentWidth + itemMargin) / numberOfParts - itemMargin : contentItemWidth
        } else if (vertical) {
            orientationVertical = true
            itemWidth = parentWidth
        } else {
            itemWidth = parentHeight
        }
        itemHeight = itemWidth
        widgetWidth = orientationVertical ? itemWidth : numberOfParts * itemWidth + (numberOfParts-1) * itemMargin
        widgetHeight = orientationVertical ? numberOfParts * itemHeight + (numberOfParts-1) * itemMargin : itemHeight
    }

    FontLoader {
        source: '../fonts/fontawesome-webfont-4.3.0.ttf'
    }

    Image {
        id: noResourceIcon;

        anchors.centerIn: parent

        visible: temperatureModel.count === 0

        height: itemHeight
        width: height

        source: '../images/thermal-monitor.svg'
    }

    ListView {
        id: listView

        anchors.centerIn: parent
        width: widgetWidth
        height: widgetHeight

        orientation: !planar && vertical ? ListView.Vertical : ListView.Horizontal
        spacing: itemMargin

        model: temperatureModel

        delegate: TemperatureItem {}
    }

    /*
     * 
     * One object has these properties: temperature, alias and other
     * 
     */
    ListModel {
        id: temperatureModel
    }

    
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n('Reload Temperature Sources')
            icon.name: 'system-reboot'
            onTriggered: reloadAllSources
        }
    ]
        
    Component.onCompleted: {
        reloadAllSources()
        setWidgetSize()
    }

    onBaseWarningTemperatureChanged: {
        tryReloadSources()
    }

    onBaseMeltdownTemperatureChanged: {
        tryReloadSources()
    }

    onConfiguredResourcesChanged: {
        dbgprint('configured resources changed')
        tryReloadSources()
    }

    function tryReloadSources() {
        if (!initialized) {
            dbgprint('applet not initialized -> no reloading sources')
            return
        }
        reloadAllSources()
    }

    function getSystemmonitorAvailableSources() {
        if (!lmsensorsAvailableSources) {
            lmsensorsAvailableSources = lmsensorsDS.sources
        }
        return lmsensorsAvailableSources
    }

    function action_reloadSources() {
        reloadAllSources()
    }

    function reloadAllSources() {

        dbgprint('reloading all sources...')

        var resources = ConfigUtils.getResourcesObjectArray()

        temperatureModel.clear()

        if (lmsensorsDS.connectedSources === undefined) {
            lmsensorsDS.connectedSources = []
        }

        if (udisksDS.connectedSources === undefined) {
            udisksDS.connectedSources = []
        }

        if (nvidiaDS.connectedSources === undefined) {
            nvidiaDS.connectedSources = []
        }

        if (atiDS.connectedSources === undefined) {
            atiDS.connectedSources = []
        }

        if (nvmeDS.connectedSources === undefined) {
            nvmeDS.connectedSources = []
        }

        if (smartctlDS.connectedSources === undefined) {
            smartctlDS.connectedSources = []
        }

        lmsensorsDS.connectedSources.length = 0
        lmsensorsDS.cmdSourceBySourceName = {}
        udisksDS.connectedSources.length = 0
        udisksDS.cmdSourceBySourceName = {}
        nvidiaDS.connectedSources.length = 0
        atiDS.connectedSources.length = 0
        nvmeDS.connectedSources.length = 0
        nvmeDS.cmdSourceBySourceName = {}
        smartctlDS.connectedSources.length = 0
        smartctlDS.cmdSourceBySourceName = {}

        ModelUtils.initModels(resources, temperatureModel)

        for (var i = 0; i < temperatureModel.count; i++) {
            var tempObj = temperatureModel.get(i)
            var source = tempObj.sourceName

            if (source === 'group-of-sources') {

                dbgprint('adding group: ' + tempObj.alias)

                for (var childSource in tempObj.childSourceObjects) {

                    dbgprint('adding source (for group): ' + childSource)

                    addSourceToDs(childSource)

                }

            } else {

                addSourceToDs(source)

            }
        }

        ModelUtils.rebuildModelIndexByKey(temperatureModel)

        initialized = true

        dbgprint('reloadAllSources() DONE')
    }

    function addSourceToDs(source) {

        if (source.indexOf('udisks/') === 0) {

            var diskLabel = source.substring('udisks/'.length)
            var cmdSource = ModelUtils.getUdisksTemperatureCmd(diskLabel)
            udisksDS.cmdSourceBySourceName[cmdSource] = source

            dbgprint('adding source to udisksDS: ' + cmdSource)

            addToSourcesOfDatasource(udisksDS, cmdSource)

        } else if (source.indexOf('nvidia-') === 0 && nvidiaDS.connectedSources.length === 0) {

            dbgprint('adding source to nvidiaDS')

            addToSourcesOfDatasource(nvidiaDS, nvidiaDS.nvidiaSource)

        } else if (source.indexOf('aticonfig') === 0 && atiDS.connectedSources.length === 0) {

            dbgprint('adding source to atiDS')

            addToSourcesOfDatasource(atiDS, atiDS.atiSource)

        } else if (source.indexOf('nvme/') === 0) {
            var diskLabel = source.substring('nvme/'.length)
            var cmdSource = ModelUtils.getNvmeTemperatureCmd(diskLabel)
            nvmeDS.cmdSourceBySourceName[cmdSource] = source

            dbgprint('adding source to nvmeDS: ' + cmdSource)

            addToSourcesOfDatasource(nvmeDS, cmdSource)
        } else if (source.indexOf('smartctl') === 0) {
            var diskLabel = source.substring('smartctl'.length)
            var cmdSource = ModelUtils.getSmartctlTemperatureCmd(diskLabel)
            smartctlDS.cmdSourceBySourceName[cmdSource] = source

            dbgprint('adding source to smartctlDS: ' + cmdSource)

            addToSourcesOfDatasource(smartctlDS, cmdSource)
        }
        else {
            dbgprint('adding source to lmsensorsDS: ' + source)

            addToSourcesOfDatasource(lmsensorsDS, ModelUtils.LMSENSORS_CMD)

        }

    }

    function addToSourcesOfDatasource(datasource, sourceName) {
        if (datasource.connectedSources.indexOf(sourceName) > -1) {
            // already added
            dbgprint('source already added: ' + sourceName)
            return
        }
        datasource.connectedSources.push(sourceName)
    }

    Plasma5Support.DataSource {
        id: lmsensorsDS
        engine: 'executable'
    
        property var cmdSourceBySourceName
    
        onNewData: (sourceName, data) => {
            if (data['exit code'] > 0) {
                print('New data incomming. Source: ' + sourceName + ', ERROR: ' + data.stderr);
                return
            }

            var paths = ModelUtils.parseLmSensorsOutput(data.stdout)
            for (var path in paths) {
                ModelUtils.updateTemperatureModel(temperatureModel, path, parseFloat(paths[path]))
            }
        }
        interval: updateInterval
    }

    Plasma5Support.DataSource {
        id: udisksDS
        engine: 'executable'

        property var cmdSourceBySourceName

        onNewData: (sourceName, data) => {

            dbgprint('udisks new data - valid: ' + valid + ', stdout: ' + data.stdout)

            var temperature = 0
            if (data['exit code'] > 0) {
                dbgprint('new data error: ' + data.stderr)
            } else {
                temperature = ModelUtils.getCelsiaFromUdisksStdout(data.stdout)
            }

            ModelUtils.updateTemperatureModel(temperatureModel, cmdSourceBySourceName[sourceName], temperature)
        }
        interval: updateInterval
    }

    Plasma5Support.DataSource {
        id: nvmeDS
        engine: 'executable'
        property var cmdSourceBySourceName

        onNewData: (sourceName, data) => {

            dbgprint('nvme new data - valid: ' + valid + ', stdout: ' + data.stdout)

            var temperature = 0
            if (data['exit code'] > 0) {
                dbgprint('new data error: ' + data.stderr)
            } else {
                temperature = ModelUtils.getCelsiaFromNvmeStdout(data.stdout)
            }

            ModelUtils.updateTemperatureModel(temperatureModel, cmdSourceBySourceName[sourceName], temperature)
        }
        interval: updateInterval
    }

    Plasma5Support.DataSource {
        id: smartctlDS
        engine: 'executable'
        property var cmdSourceBySourceName

        onNewData: (sourceName, data) => {

            dbgprint('smartctl new data - valid: ' + valid + ', stdout: ' + data.stdout)

            var temperature = 0
            if (data['exit code'] > 0) {
                dbgprint('new data error: ' + data.stderr)
            } else {
                temperature = ModelUtils.getCelsiaFromSmartctlStdout(data.stdout)
            }

            ModelUtils.updateTemperatureModel(temperatureModel, cmdSourceBySourceName[sourceName], temperature)
        }
        interval: updateInterval
    }

    Plasma5Support.DataSource {
        id: nvidiaDS
        engine: 'executable'

        property string nvidiaSource: 'nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader'

        onNewData: (sourceName, data) => {
            var temperature = 0
            if (data['exit code'] > 0) {
                dbgprint('new data error: ' + data.stderr)
            } else {
                temperature = parseFloat(data.stdout)
            }

            ModelUtils.updateTemperatureModel(temperatureModel, 'nvidia-smi', temperature)
        }
        interval: updateInterval
    }

    Plasma5Support.DataSource {
        id: atiDS
        engine: 'executable'

        property string atiSource: 'aticonfig --od-gettemperature | tail -1 | cut -c 43-44'

        onNewData: (sourceName, data) => {
            var temperature = 0
            if (data['exit code'] > 0) {
                dbgprint('new data error: ' + data.stderr)
            } else {
                temperature = parseFloat(data.stdout)
            }

            ModelUtils.updateTemperatureModel(temperatureModel, 'aticonfig', temperature)
        }
        interval: updateInterval
    }

    Timer {
        interval: updateInterval
        repeat: true
        running: true
        onTriggered: {
            ModelUtils.computeVirtuals(temperatureModel)
        }
    }

}
