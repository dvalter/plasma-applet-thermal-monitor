import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {

    property alias cfg_updateInterval: updateIntervalSpinBox.value

    property int cfg_temperatureUnit

    onCfg_temperatureUnitChanged: {
        switch (cfg_temperatureUnit) {
        case 0:
            temperatureTypeGroup.checkedButton = temperatureTypeRadioCelsius;
            break;
        case 1:
            temperatureTypeGroup.checkedButton = temperatureTypeRadioFahrenheit;
            break;
        case 2:
            temperatureTypeGroup.checkedButton = temperatureTypeRadioKelvin;
            break;
        default:
        }
    }


    Component.onCompleted: {
        cfg_temperatureUnitChanged()
    }

    ButtonGroup {
        id: temperatureTypeGroup
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2

        Label {
            text: i18n('Update interval:')
            Layout.alignment: Qt.AlignRight
        }
        SpinBox {
            id: updateIntervalSpinBox
            from: decimalToInt(0.1)

            stepSize: 1
            editable: true

            property int decimals: 1
            property real realValue: value / decimalFactor
            readonly property int decimalFactor: Math.pow(10, decimals)

            function decimalToInt(decimal) {
                return decimal * decimalFactor
            }

            validator: DoubleValidator {
                bottom: Math.min(updateIntervalSpinBox.from, updateIntervalSpinBox.to)
                top:  Math.max(updateIntervalSpinBox.from, updateIntervalSpinBox.to)
                decimals: updateIntervalSpinBox.decimals
                notation: DoubleValidator.StandardNotation
            }
            
            textFromValue: function(value, locale) {
                let num = Number(value / decimalFactor).toLocaleString(locale, 'f', updateIntervalSpinBox.decimals)
                let suffix = i18nc('Abbreviation for seconds', 's')
                return "%1 %2".arg(num).arg(suffix)
            }

            valueFromText: function(text, locale) {
                return Math.round(Number.fromLocaleString(locale, text) * decimalFactor)
            }
        }

        Item {
            width: 2
            height: 10
            Layout.columnSpan: 2
        }

        Label {
            text: i18n("Temperature:")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
        RadioButton {
            id: temperatureTypeRadioCelsius
            ButtonGroup.group: temperatureTypeGroup
            text: i18n("°C")
            onCheckedChanged: if (checked) cfg_temperatureUnit = 0
        }
        Item {
            width: 2
            height: 2
            Layout.rowSpan: 1
        }
        RadioButton {
            id: temperatureTypeRadioFahrenheit
            ButtonGroup.group: temperatureTypeGroup
            text: i18n("°F")
            onCheckedChanged: if (checked) cfg_temperatureUnit = 1
        }
        Item {
            width: 2
            height: 2
            Layout.rowSpan: 1
        }
        RadioButton {
            id: temperatureTypeRadioKelvin
            ButtonGroup.group: temperatureTypeGroup
            text: i18n("K")
            onCheckedChanged: if (checked) cfg_temperatureUnit = 2
        }

    }

}
