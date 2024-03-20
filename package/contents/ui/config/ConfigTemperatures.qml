import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import "../../code/config-utils.js" as ConfigUtils
import "../../code/model-utils.js" as ModelUtils
import Qt.labs.qmlmodels
import org.kde.kirigami as Kirigami

Item {
    id: resourcesConfigPage

    property double tableWidth: parent.width
    property double tableHeight: parent.height

    property string cfg_resources
    property alias cfg_warningTemperature: warningTemperatureSpinBox.value
    property alias cfg_meltdownTemperature: meltdownTemperatureSpinBox.value
    property var backgroundColor: Kirigami.Theme.backgroundColor
    property var alternateBackgroundColor: Kirigami.Theme.alternateBackgroundColor

    property var preparedSystemMonitorSources: []

    ListModel {
        id: resourcesList
    }
    
    TableModel {
        id: resourcesModel
        TableModelColumn {
            display: "source"
        }
        TableModelColumn {
            display: "alias"
        }
        TableModelColumn {
            display: "action"
        }
    }
    
    ListModel {
        id: comboboxModel
    }

    ListModel {
        id: checkboxesSourcesModel
    }

    Component.onCompleted: {

        lmsensorsDS.sources.forEach(function (source) {
            comboboxModel.append({
                text: source,
                val: source
            })
    
            print('source to combo: ' + source)
        })

        var resources = ConfigUtils.getResourcesObjectArray()
        resources.forEach(function (resourceObj) {
            resourcesList.append(resourceObj)
            resourcesModel.appendRow({
                source: resourceObj.sourceName,
                alias: resourceObj.alias,
                actions: 0
            })
        })
    }

    function reloadComboboxModel(temperatureObj) {

        temperatureObj = temperatureObj || {}
        var childSourceObjects = temperatureObj.childSourceObjects || {}
        var childSourceObjectsEmpty = !temperatureObj.childSourceObjects

        checkboxesSourcesModel.clear()
        sourceCombo.currentIndex = 0

        print('sourceName to select: ' + temperatureObj.sourceName)

        addResourceDialog.sourceTypeSwitch = temperatureObj.sourceName === 'group-of-sources' ? 1 : 0
        addResourceDialog.setVirtualSelected()

        addResourceDialog.groupSources.length = 0

        for (var i = 0; i < comboboxModel.count; i++) {
            var source = comboboxModel.get(i).val

            if (source === temperatureObj.sourceName) {
                sourceCombo.currentIndex = i
            }

            var checkboxChecked = childSourceObjectsEmpty || (source in childSourceObjects)
            checkboxesSourcesModel.append({
                text: source,
                val: source,
                checkboxChecked: checkboxChecked
            })
            if (checkboxChecked) {
                addResourceDialog.groupSources.push(source)
            }
        }

    }

    function resourcesModelChanged() {
        var newResourcesArray = []
        for (var i = 0; i < resourcesList.count; i++) {
            var obj = resourcesList.get(i)
            newResourcesArray.push({
                sourceName: obj.sourceName,
                alias: obj.alias,
                overrideLimitTemperatures: obj.overrideLimitTemperatures,
                warningTemperature: obj.warningTemperature,
                meltdownTemperature: obj.meltdownTemperature,
                virtual: obj.virtual,
                childSourceObjects: obj.childSourceObjects
            })
        }
        cfg_resources = JSON.stringify(newResourcesArray)
        print('resources: ' + cfg_resources)
    }


    function fillAddResourceDialogAndOpen(temperatureObj, editResourceIndex) {

        // set dialog title
        addResourceDialog.addResource = temperatureObj === null
        addResourceDialog.editResourceIndex = editResourceIndex
        
        temperatureObj = temperatureObj || {
            alias: '',
            overrideLimitTemperatures: false,
            meltdownTemperature: 90,
            warningTemperature: 70
        }
        
        // set combobox
        reloadComboboxModel(temperatureObj)
        
        // alias
        aliasTextfield.text = temperatureObj.alias
        showAlias.checked = !!temperatureObj.alias
        
        // temperature overrides
        overrideLimitTemperatures.checked = temperatureObj.overrideLimitTemperatures
        warningTemperatureItem.value = temperatureObj.warningTemperature
        meltdownTemperatureItem.value = temperatureObj.meltdownTemperature
        
        // open dialog
        addResourceDialog.open()
    }

    Dialog {
        id: addResourceDialog

        property bool addResource: true
        property int editResourceIndex: -1

        title: addResource ? i18n('Add Resource') : i18n('Edit Resource')

        width: tableWidth

        property int tableIndex: 0
        property double fieldHeight: addResourceDialog.height / 5 - 3

        property bool virtualSelected: true

        footer: DialogButtonBox {
            id: dialogButtons
            standardButtons: Dialog.Ok | Dialog.Cancel
        }


        property int sourceTypeSwitch: 0

        property var groupSources: []

        ButtonGroup {
            id: sourceTypeGroup
        }

        // onSourceTypeSwitchChanged: {
        //     switch (sourceTypeSwitch) {
        //     case 0:
        //         sourceTypeGroup.current = singleSourceTypeRadio;
        //         break;
        //     case 1:
        //         sourceTypeGroup.current = multipleSourceTypeRadio;
        //         break;
        //     default:
        //     }
        //     setVirtualSelected()
        // }

        function setVirtualSelected() {
            virtualSelected = sourceTypeSwitch === 1
            print('SET VIRTUAL SELECTED: ' + virtualSelected)
        }

        onAccepted: {
            if (!showAlias.checked) {
                aliasTextfield.text = ''
            } else if (!aliasTextfield.text) {
                aliasTextfield.text = '<UNKNOWN>'
            }

            var childSourceObjects = {}
            groupSources.forEach(function (groupSource) {
                print ('adding source to group: ' + groupSource)
                childSourceObjects[groupSource] = {
                    temperature: 0
                }
            })

            var newObject = {
                sourceName: virtualSelected ? 'group-of-sources' : comboboxModel.get(sourceCombo.currentIndex).val,
                alias: aliasTextfield.text,
                overrideLimitTemperatures: overrideLimitTemperatures.checked,
                warningTemperature: warningTemperatureItem.value,
                meltdownTemperature: meltdownTemperatureItem.value,
                virtual: virtualSelected,
                childSourceObjects: childSourceObjects
            }

            if (addResourceDialog.addResource) {
                resourcesModel.appendRow({
                    source: newObject.sourceName,
                    alias: newObject.alias,
                    actions: 0
                })
                resourcesList.append(newObject)
            } else {
                resourcesModel.setRow(addResourceDialog.editResourceIndex, {
                    source: newObject.sourceName,
                    alias: newObject.alias
                })
                resourcesList.set(addResourceDialog.editResourceIndex, newObject)
            }


            resourcesModelChanged()
            addResourceDialog.close()
        }

        GridLayout {
            columns: 2


            RadioButton {
                id: singleSourceTypeRadio
                ButtonGroup.group: sourceTypeGroup
                text: i18n("Source")
                onCheckedChanged: {
                    if (checked) {
                        addResourceDialog.sourceTypeSwitch = 0
                    }
                    addResourceDialog.setVirtualSelected()
                }
                checked: true
            }
            ComboBox {
                id: sourceCombo
                textRole: "text"
                Layout.preferredWidth: tableWidth/2
                model: comboboxModel
                enabled: !addResourceDialog.virtualSelected
            }

            RadioButton {
                id: multipleSourceTypeRadio
                ButtonGroup.group: sourceTypeGroup
                text: i18n("Group of sources")
                onCheckedChanged: {
                    if (checked) {
                        addResourceDialog.sourceTypeSwitch = 1
                    }
                    addResourceDialog.setVirtualSelected()
                }
                Layout.alignment: Qt.AlignTop
            }
            ScrollView {
                ListView {
                    id: checkboxesSourcesListView
                    model: checkboxesSourcesModel
                    delegate: CheckBox {
                        text: val
                        checked: checkboxChecked
                        onCheckedChanged: {
                            if (checked) {
                                if (addResourceDialog.groupSources.indexOf(val) === -1) {
                                    addResourceDialog.groupSources.push(val)
                                }
                            } else {
                                var idx = addResourceDialog.groupSources.indexOf(val)
                                if (idx !== -1) {
                                    addResourceDialog.groupSources.splice(idx, 1)
                                }
                            }
                        }
                    }
                    enabled: addResourceDialog.virtualSelected
                    Layout.preferredWidth: tableWidth/2
                    Layout.preferredHeight: tableHeight/2
                }
                
                implicitHeight: 200
                implicitWidth: 800
            }

            Item {
                Layout.columnSpan: 2
                width: 2
                height: 5
            }

            Label {
                text: i18n("NOTE: Group of sources shows the highest temperature of chosen sources.")
                Layout.columnSpan: 2
                enabled: addResourceDialog.virtualSelected
            }

            Item {
                Layout.columnSpan: 2
                width: 2
                height: 10
            }

            CheckBox {
                id: showAlias
                text: i18n("Show alias:")
                checked: true
                Layout.alignment: Qt.AlignRight
            }
            TextField {
                id: aliasTextfield
                Layout.preferredWidth: tableWidth/2
                enabled: showAlias.checked
            }

            Item {
                Layout.columnSpan: 2
                width: 2
                height: 10
            }

            CheckBox {
                id: overrideLimitTemperatures
                text: i18n("Override limit temperatures")
                Layout.columnSpan: 2
                checked: false
            }

            Label {
                text: i18n('Warning temperature [°C]:')
                Layout.alignment: Qt.AlignRight
            }
            SpinBox {
                id: warningTemperatureItem
                stepSize: 10
                from: 10
                to: 200
                enabled: overrideLimitTemperatures.checked
            }

            Label {
                text: i18n('Meltdown temperature [°C]:')
                Layout.alignment: Qt.AlignRight
            }
            SpinBox {
                id: meltdownTemperatureItem
                stepSize: 10
                from: 10
                to: 200
                enabled: overrideLimitTemperatures.checked
            }

        }
    }

    GridLayout {
        columns: 2

        Label {
            text: i18n('Plasmoid version: ') + '1.3.0'
            Layout.alignment: Qt.AlignRight
            Layout.columnSpan: 2
        }

        Label {
            text: i18n('Resources')
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }

        Item {
            width: 2
            height: 2
        }
        
        HorizontalHeaderView {
            id: myhorizontalHeader
            // anchors.left: mytableView.left
            // anchors.leftMargin: 0
            // anchors.topMargin: 2
            // anchors.top: parent.top
            // anchors.right: parent.right
            // anchors.rightMargin: 2

            syncView: mytableView
            clip: true
            model: ListModel {
                Component.onCompleted: {
                    append({ display: i18n("Source") });
                    append({ display: i18n("Alias") });
                    append({ display: i18n("Action") });
                }
            }
            Layout.preferredWidth: tableWidth
            Layout.columnSpan: 2
        }

        ScrollView {
            id: resourcesTable
            width: parent.width
            clip: true


            TableView {
                anchors.fill: parent
                property var columnWidths: [30, 40, 30]
                columnWidthProvider: function (column) {
                    let aw = resourcesTable.width - resourcesTable.effectiveScrollBarWidth
                    return parseInt(aw * columnWidths[column] / 100 )

                }

                implicitHeight: 200
                implicitWidth: 800
                clip: true
                interactive: true
                rowSpacing: 1
                columnSpacing: 1
                boundsBehavior: Flickable.StopAtBounds
                model: resourcesModel
                id: mytableView
                alternatingRows: true

                selectionBehavior: TableView.SelectRows
                selectionModel: ItemSelectionModel {}

                delegate: myChooser

                DelegateChooser {
                    id: myChooser
                    DelegateChoice {
                        column: 0
                        delegate: Rectangle {
                            color: (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: 0
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    DelegateChoice {
                        column: 1
                        delegate: Rectangle {
                            color: (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                        }
                    }
                    DelegateChoice {
                        column: 2
                        delegate: GridLayout {
                            columnSpacing: 1
                            Text {
                                visible: false
                                text: display
                            }
                            Button {
                                icon.name: 'go-up'
                                enabled: row === 0  ? false : true
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (row > 0) {
                                            resourcesModel.moveRow(row, row - 1, 1)
                                            resourcesList.move(row, row - 1, 1)
                                            resourcesModelChanged()
                                        }
                                    }
                                }
                            }
                            Button {
                                icon.name: 'go-down'
                                enabled: row == (resourcesModel.rowCount - 1)  ? false: true
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (row < resourcesModel.rowCount) {
                                            resourcesModel.moveRow(row, row + 1, 1)
                                            resourcesList.move(row, row + 1, 1)
                                            resourcesModelChanged()
                                        }
                                    }
                                }
                            }
                            Button {
                                icon.name: 'list-remove'
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        resourcesModel.removeRow(row)
                                        resourcesList.remove(row)
                                        resourcesModelChanged()
                                    }
                                }
                            }
                            Button {
                                icon.name: 'entry-edit'
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        fillAddResourceDialogAndOpen(resourcesList.get(row), row)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Layout.preferredHeight: 150
            Layout.preferredWidth: tableWidth
            Layout.columnSpan: 2
        }
      
        Button {
            id: buttonAddResource
            icon.name: 'list-add'
            Layout.preferredWidth: 100
            Layout.columnSpan: 2
            onClicked: {
                fillAddResourceDialogAndOpen(null, -1)
            }
        }

        Item {
            width: 2
            height: 20
            Layout.columnSpan: 2
        }

        Label {
            text: i18n('Notifications')
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }

        Item {
            width: 2
            height: 2
        }

        Label {
            text: i18n('Warning temperature [°C]:')
            Layout.alignment: Qt.AlignRight
        }
        SpinBox {
            id: warningTemperatureSpinBox
            stepSize: 1
            from: 10
            to: 200
        }

        Label {
            text: i18n('Meltdown temperature [°C]:')
            Layout.alignment: Qt.AlignRight
        }
        SpinBox {
            id: meltdownTemperatureSpinBox
            stepSize: 1
            from: 10
            to: 200
        }

    }
    
    Plasma5Support.DataSource {
        id: lmsensorsDS
        engine: 'executable'
    
        connectedSources: [ModelUtils.LMSENSORS_CMD]
    
        property bool prepared: false
    
        onNewData: (sourceName, data) => {
            if (!prepared)
            {
                if (data['exit code'] > 0) {
                    print('New data incomming. Source: ' + sourceName + ', ERROR: ' + data.stderr);
                    return
                }
    
                print('New data incomming. Source: ' + sourceName + ', data: ' + data.stdout);
    
                var pathsToCheck = ModelUtils.parseLmSensorsOutput(data.stdout)
                for (var path in pathsToCheck){
                    comboboxModel.append({
                        text: path,
                        val: path
                    })
                }
    
                prepared = true
    
            }
        }
    }

    Plasma5Support.DataSource {
        id: udisksDS
        engine: 'executable'

        connectedSources: [ ModelUtils.UDISKS_DEVICES_CMD ]

        property bool prepared: false

        onNewData: (sourceName, data) => {
            if (!prepared)
            {
                if (data['exit code'] > 0) {
                    print('New data incomming. Source: ' + sourceName + ', ERROR: ' + data.stderr);
                    return
                }

                print('New data incomming. Source: ' + sourceName + ', data: ' + data.stdout);

                var pathsToCheck = ModelUtils.parseUdisksPaths(data.stdout)
                pathsToCheck.forEach(function (pathObj) {
                    var cmd = ModelUtils.UDISKS_VIRTUAL_PATH_PREFIX + pathObj.name
                    comboboxModel.append({
                        text: cmd,
                        val: cmd
                    })
                })

                prepared = true

            }
        }
    }

    Plasma5Support.DataSource {
        id: nvmeDS
        engine: 'executable'
    
        connectedSources: ['sudo -n nvme list -o json | jq -r ".Devices | map(.DevicePath)"']
    
        property bool prepared: false
    
        onNewData: (sourceName, data) => {
            if (!prepared)
            {
                if (data['exit code'] > 0) {
                    print('New data incomming. Source: ' + sourceName + ', ERROR: ' + data.stderr);
                    return
                }
    
                print('New data incomming. Source: ' + sourceName + ', data: ' + data.stdout);
    
                var pathsToCheck = ModelUtils.parseNvmePaths(data.stdout)
                pathsToCheck.forEach(function (pathObj) {
                    var cmd = ModelUtils.NVME_VIRTUAL_PATH_PREFIX + pathObj.name
                    comboboxModel.append({
                        text: cmd,
                        val: cmd
                    })
                })
    
                prepared = true
    
            }
        }
    }

    Plasma5Support.DataSource {
        id: smartctlDS
        engine: 'executable'
    
        connectedSources: ['sudo -n smartctl --scan-open --json=c | jq -r ".devices | map(.name)"']
    
        property bool prepared: false
    
        onNewData: (sourceName, data) => {
            if (!prepared)
            {
                if (data['exit code'] > 0) {
                    print('New data incomming. Source: ' + sourceName + ', ERROR: ' + data.stderr);
                    return
                }
    
                print('New data incomming. Source: ' + sourceName + ', data: ' + data.stdout);
    
                var pathsToCheck = ModelUtils.parseSmartctlPaths(data.stdout)
                pathsToCheck.forEach(function (pathObj) {
                    var cmd = ModelUtils.SMARTCTL_VIRTUAL_PATH_PREFIX + pathObj.name
                    comboboxModel.append({
                        text: cmd,
                        val: cmd
                    })
                })
    
                prepared = true
    
            }
        }
    }

    Plasma5Support.DataSource {
        id: nvidiaDS
        engine: 'executable'

        connectedSources: [ 'nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader' ]

        property bool prepared: false

        onNewData: (sourceName, data) => { 
            if (!prepared)
            {
                if (data['exit code'] > 0) {
                    prepared = true
                    return
                }

                comboboxModel.append({
                    text: 'nvidia-smi',
                    val: 'nvidia-smi'
                })

                prepared = true
            }
        }
    }

    Plasma5Support.DataSource {
        id: atiDS
        engine: 'executable'

        connectedSources: [ 'aticonfig --od-gettemperature' ]

        property bool prepared: false

        onNewData: (sourceName, data) => {
            if (!prepared)
            {
                if (data['exit code'] > 0) {
                    prepared = true
                    return
                }

                comboboxModel.append({
                    text: 'aticonfig',
                    val: 'aticonfig'
                })

                prepared = true
            }
        }
    }

}
