pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string username: ""
    property string rankName: ""
    property int ranking: 0
    property int points: 0
    property string nextRank: ""
    property double rankProgress: 0
    property var seasonalMachine: null
    property int userOwns: 0
    property int systemOwns: 0
    property int respects: 0
    property string country: ""
    property string countryCode: ""
    property string server: ""
    property string avatarUrl: ""
    property int userId: 2426022

    property bool isLoading: false
    property bool hasFailed: false
    property bool dataAvailable: false
    property bool wasCancelled: false
    property int retryCount: 0
    readonly property int maxRetries: 2

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/htb_profile.sh"
    readonly property string cacheFilePath: Quickshell.env("HOME") + "/.cache/prodigal/htb_profile.json"

    property bool cacheLoaded: false

    property FileView cacheFile: FileView {
        id: cacheView
        path: root.cacheFilePath
        watchChanges: false
        onLoaded: root.loadFromCache()
        onFileChanged: root.loadFromCache()
    }

    function loadFromCache() {
        if (!cacheView.text() || cacheView.text().trim().length === 0)
            return;

        try {
            const cached = JSON.parse(cacheView.text());
            if (!cached)
                return;

            const info = cached.profile || cached.info || cached;
            const uname = info.name || info.username || info.full_name || "";
            if (!uname)
                return;

            root.username = uname;
            root.rankName = info.rank || info.rank_name || info.rankName || "";
            root.ranking = parseInt(info.ranking || info.rank_id || 0) || 0;
            root.points = parseInt(info.points || 0) || 0;
            root.nextRank = info.next_rank || info.nextRank || "";
            root.rankProgress = parseFloat(info.current_rank_progress || info.rankProgress || 0) || 0;
            root.userOwns = parseInt(info.user_owns || info.userOwns || 0) || 0;
            root.systemOwns = parseInt(info.system_owns || info.systemOwns || info.root_owns || 0) || 0;
            root.respects = parseInt(info.respects || info.user_respects || 0) || 0;
            root.country = info.country_name || info.country || "";
            root.countryCode = (info.country_code || "").toLowerCase();
            root.server = info.server || "";
            var avatar = info.avatar || info.avatarUrl || "";
            if (avatar && avatar.indexOf("http") !== 0)
                avatar = "https://www.hackthebox.com" + avatar;
            root.avatarUrl = avatar;
            if (info.id || info.userId)
                root.userId = parseInt(info.id || info.userId) || root.userId;

            root.dataAvailable = true;
            root.cacheLoaded = true;
        } catch (e) {
            console.warn("HtbService: cache parse error:", e);
        }
    }

    function saveToCache() {
        cacheView.setText(JSON.stringify({
            username: root.username,
            rankName: root.rankName,
            ranking: root.ranking,
            points: root.points,
            nextRank: root.nextRank,
            rankProgress: root.rankProgress,
            userOwns: root.userOwns,
            systemOwns: root.systemOwns,
            respects: root.respects,
            country: root.country,
            countryCode: root.countryCode,
            server: root.server,
            avatarUrl: root.avatarUrl,
            userId: root.userId,
            savedAt: new Date().toISOString()
        }, null, 2));
    }

    property var suspendConnections: Connections {
        target: SuspendManager
        function onPreparingForSleep() {
            if (apiProcess.running) {
                root.wasCancelled = true;
                apiProcess.running = false;
            }
            if (retryTimer)
                retryTimer.stop();
        }
        function onWakingUp() {
            if (wakeRefreshTimer)
                wakeRefreshTimer.restart();
        }
    }

    property Timer wakeRefreshTimer: Timer {
        interval: 8000
        repeat: false
        onTriggered: root.updateProfile()
    }

    property Timer refreshTimer: Timer {
        interval: 600000
        running: !SuspendManager.isSuspending
        repeat: true
        onTriggered: root.updateProfile()
    }

    property Timer retryTimer: Timer {
        interval: 15000
        repeat: false
        onTriggered: root.updateProfile()
    }

    property Process apiProcess: Process {
        running: false
        command: [root.scriptPath, String(root.userId)]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (root.wasCancelled)
                    return;

                var raw = text.trim();
                if (raw.length === 0) {
                    root.handleError();
                    return;
                }

                try {
                    var data = JSON.parse(raw);
                    if (data.error) {
                        console.warn("HtbService:", data.error);
                        root.handleError();
                        return;
                    }

                    var info = (data.profile && data.profile.name) ? data.profile : (data.info || data);
                    var uname = info.name || info.username || info.full_name || "";
                    if (!uname) {
                        console.warn("HtbService: unexpected response");
                        root.handleError();
                        return;
                    }

                    root.username = uname;
                    root.rankName = info.rank || info.rank_name || "";
                    root.nextRank = info.next_rank || info.nextRank || "";
                    root.rankProgress = parseFloat(info.current_rank_progress || info.rankProgress || 0) || 0;
                    root.ranking = parseInt(info.ranking || info.rank_id || 0) || 0;
                    root.points = parseInt(info.points || 0) || 0;
                    root.userOwns = parseInt(info.user_owns || info.userOwns || 0) || 0;
                    root.systemOwns = parseInt(info.system_owns || info.systemOwns || info.root_owns || 0) || 0;
                    root.respects = parseInt(info.respects || info.user_respects || 0) || 0;
                    root.country = info.country_name || info.country || "";
                    root.countryCode = (info.country_code || "").toLowerCase();
                    root.server = info.server || "";
                    var avatar = info.avatar || "";
                    if (avatar && avatar.indexOf("http") !== 0)
                        avatar = "https://www.hackthebox.com" + avatar;
                    root.avatarUrl = avatar;
                    if (info.id)
                        root.userId = parseInt(info.id) || root.userId;

                    root.dataAvailable = true;
                    root.hasFailed = false;
                    root.isLoading = false;
                    root.retryCount = 0;
                    root.saveToCache();
                } catch (e) {
                    console.warn("HtbService: JSON parse error:", e);
                    root.handleError();
                }
            }
        }

        onExited: function (code) {
            if (code !== 0 && code !== 15) {
                console.warn("HtbService: script exited with code", code);
                root.handleError();
            }
            root.wasCancelled = false;
        }
    }

    function handleError() {
        if (retryCount < maxRetries) {
            retryCount++;
            retryTimer.start();
        } else {
            root.isLoading = false;
            root.hasFailed = true;
            retryCount = 0;
        }
    }

    function updateProfile() {
        if (apiProcess.running) {
            root.wasCancelled = true;
            apiProcess.running = false;
        }

        root.isLoading = true;
        root.hasFailed = false;
        apiProcess.command = [scriptPath, String(root.userId)];
        apiProcess.running = true;
    }

    Timer {
        id: startupDelay
        interval: 1500
        running: true
        onTriggered: {
            root.updateProfile();
            root.updateSeasonal();
        }
    }

    Component.onCompleted: {
        if (cacheView.text() && cacheView.text().trim().length > 0)
            root.loadFromCache();
    }

    property Process seasonalProcess: Process {
        running: false
        command: []

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (root.wasCancelled)
                    return;

                var raw = text.trim();
                if (raw.length === 0) {
                    root.seasonalMachine = null;
                    return;
                }

                try {
                    var data = JSON.parse(raw);
                    if (data.error) {
                        root.seasonalMachine = null;
                        return;
                    }

                    var info = data.data || data.info || data;
                    if (info && (info.name || info.id)) {
                        root.seasonalMachine = info;
                    } else {
                        root.seasonalMachine = null;
                    }
                } catch (e) {
                    root.seasonalMachine = null;
                }
            }
        }
    }

    function updateSeasonal() {
        if (seasonalProcess.running) {
            seasonalProcess.running = false;
        }

        seasonalProcess.command = ["bash", "-c", "source " + Quickshell.shellDir + "/scripts/htb_env.sh 2>/dev/null; curl -s -L --max-time 10 -H \"Authorization: Bearer $HTB_TOKEN\" \"https://labs.hackthebox.com/api/v4/season/machine/active\""];
        seasonalProcess.running = true;
    }
}
