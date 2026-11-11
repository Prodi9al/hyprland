pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 430

    function openProfile() {
        Qt.openUrlExternally("https://app.hackthebox.com/users/" + HtbService.userId);
    }

    property double ringProgress: HtbService.rankProgress || 0

    Behavior on ringProgress {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutCubic
        }
    }

    onRingProgressChanged: {
        if (progressRing.available)
            progressRing.requestPaint();
    }

    component StatCard: StyledRect {
        property string icon
        property string label
        property var value
        property color accentColor: Colors.primary

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Styling.radius(3)
        variant: "pane"

        StyledRect {
            anchors.fill: parent
            anchors.margins: 3
            radius: Styling.radius(0)
            variant: "internalbg"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                StyledRect {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 8
                    variant: "common"

                    Text {
                        anchors.centerIn: parent
                        text: icon
                        font.family: Icons.font
                        font.pixelSize: Styling.fontSize(4)
                        color: accentColor
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: label
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-2)
                        font.weight: Font.Medium
                        color: Colors.overSurfaceVariant
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: String(value !== undefined && value !== null ? value : 0)
                        font.family: "JetBrains Mono", Config.theme.font
                        font.pixelSize: Styling.fontSize(5)
                        font.weight: Font.Bold
                        color: Colors.overBackground
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 8

        // Top Header Card: Profile & Rank Progress
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            radius: Styling.radius(4)
            variant: "pane"

            StyledRect {
                anchors.fill: parent
                anchors.margins: 3
                radius: Styling.radius(0)
                variant: "internalbg"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Avatar
                    StyledRect {
                        id: avatarContainer
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 32
                        variant: "primary"
                        border.width: 2
                        border.color: Colors.primary

                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            anchors.margins: 2
                            source: HtbService.avatarUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                                maskSource: ShaderEffectSource {
                                    sourceItem: Rectangle {
                                        width: avatarImage.width
                                        height: avatarImage.height
                                        radius: avatarImage.height / 2
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: HtbService.username ? HtbService.username.charAt(0).toUpperCase() : "H"
                            font.family: Config.theme.font
                            font.pixelSize: 26
                            font.weight: Font.Bold
                            color: Colors.overPrimary
                            visible: avatarImage.status !== Image.Ready
                        }
                    }

                    // User info & rank
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: HtbService.username || (HtbService.isLoading ? "Loading..." : "Hack The Box")
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(2)
                            font.weight: Font.Bold
                            color: Colors.overBackground
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 6

                            // Rank Badge
                            StyledRect {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: rankText.implicitWidth + 12
                                radius: 4
                                variant: "primary"

                                Text {
                                    id: rankText
                                    anchors.centerIn: parent
                                    text: HtbService.rankName || "Member"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-3)
                                    font.weight: Font.Bold
                                    color: Colors.overPrimary
                                }
                            }

                            // Country
                            Text {
                                text: HtbService.country || ""
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-2)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                                visible: HtbService.country.length > 0
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Layout.topMargin: 2

                            Text {
                                text: HtbService.ranking > 0 ? "#" + HtbService.ranking : "--"
                                font.family: "JetBrains Mono", Config.theme.font
                                font.pixelSize: Styling.fontSize(3)
                                font.weight: Font.Bold
                                color: Colors.overBackground
                            }

                            Text {
                                text: "Global Rank"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-3)
                                color: Colors.overSurfaceVariant
                            }
                        }
                    }

                    // Progress Ring
                    ColumnLayout {
                        Layout.preferredWidth: 74
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Canvas {
                            id: progressRing
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            Layout.alignment: Qt.AlignHCenter

                            property color strokeColor: Colors.green
                            property color bgColor: Colors.surfaceVariant

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = 26;
                                var strokeWidth = 5;

                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                ctx.strokeStyle = bgColor;
                                ctx.lineWidth = strokeWidth;
                                ctx.stroke();

                                var p = root.ringProgress;
                                if (p > 0) {
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * (p / 100)));
                                    ctx.strokeStyle = strokeColor;
                                    ctx.lineWidth = strokeWidth;
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }

                                ctx.font = "bold 11px 'JetBrains Mono', monospace";
                                ctx.fillStyle = Colors.overBackground;
                                ctx.textAlign = "center";
                                ctx.textBaseline = "middle";
                                ctx.fillText(p.toFixed(0) + "%", centerX, centerY);
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: HtbService.nextRank ? "to " + HtbService.nextRank : "Next Rank"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-4)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openProfile()
                }
            }
        }

        // Stats Grid: 2x2
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            StatCard {
                icon: Icons.cube
                label: "User Flags"
                value: HtbService.userOwns
                accentColor: Colors.green
            }

            StatCard {
                icon: Icons.shield
                label: "System Flags"
                value: HtbService.systemOwns
                accentColor: Colors.red
            }

            StatCard {
                icon: Icons.sparkle
                label: "Total Points"
                value: HtbService.points
                accentColor: Colors.yellow
            }

            StatCard {
                icon: Icons.heart
                label: "Respects"
                value: HtbService.respects
                accentColor: Colors.cyan
            }
        }

        // Bottom Status / Controls Bar
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: Styling.radius(3)
            variant: "pane"

            StyledRect {
                anchors.fill: parent
                anchors.margins: 2
                radius: Styling.radius(0)
                variant: "internalbg"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    // Server indicator dot
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: HtbService.dataAvailable ? Colors.green : (HtbService.hasFailed ? Colors.red : Colors.yellow)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: HtbService.server ? HtbService.server : (HtbService.dataAvailable ? "HTB Connected" : "Connecting...")
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-3)
                        font.weight: Font.Medium
                        color: Colors.overSurfaceVariant
                        elide: Text.ElideRight
                    }

                    // Open profile in browser button
                    StyledRect {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 6
                        variant: profileBtnMouse.containsMouse ? "focus" : "common"

                        Text {
                            anchors.centerIn: parent
                            text: Icons.terminal
                            font.family: Icons.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: Colors.overBackground
                        }

                        MouseArea {
                            id: profileBtnMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.openProfile()
                        }
                    }

                    // Manual refresh button
                    StyledRect {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 6
                        variant: refreshBtnMouse.containsMouse ? "focus" : "common"

                        Text {
                            id: refreshIcon
                            anchors.centerIn: parent
                            text: Icons.sync
                            font.family: Icons.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: HtbService.isLoading ? Colors.primary : Colors.overBackground
                            rotation: HtbService.isLoading ? 360 : 0

                            Behavior on rotation {
                                enabled: HtbService.isLoading
                                NumberAnimation {
                                    duration: 800
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                }
                            }
                        }

                        MouseArea {
                            id: refreshBtnMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                HtbService.updateProfile();
                            }
                        }
                    }
                }
            }
        }
    }
}
