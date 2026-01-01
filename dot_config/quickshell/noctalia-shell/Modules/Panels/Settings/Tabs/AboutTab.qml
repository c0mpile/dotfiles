import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Noctalia
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root

  property string latestVersion: GitHubService.latestVersion
  property string currentVersion: UpdateService.currentVersion
  property var contributors: GitHubService.contributors
  property string commitInfo: ""

  readonly property int topContributorsCount: 20
  readonly property bool isGitVersion: root.currentVersion.endsWith("-git")

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("AboutTab", "Component.onCompleted - Current version:", root.currentVersion);
    Logger.d("AboutTab", "Component.onCompleted - Is git version:", root.isGitVersion);
    // Only fetch commit info for -git versions
    if (root.isGitVersion) {
      // On NixOS, extract commit hash from the store path first
      if (HostService.isNixOS) {
        var shellDir = Quickshell.shellDir || "";
        Logger.d("AboutTab", "Component.onCompleted - NixOS detected, shellDir:", shellDir);
        if (shellDir) {
          // Extract commit hash from path like: /nix/store/...-noctalia-shell-2025-11-30_225e6d3/share/noctalia-shell
          // Pattern matches: noctalia-shell-YYYY-MM-DD_<commit_hash>
          var match = shellDir.match(/noctalia-shell-\d{4}-\d{2}-\d{2}_([0-9a-f]{7,})/i);
          if (match && match[1]) {
            // Use first 7 characters of the commit hash
            root.commitInfo = match[1].substring(0, 7);
            Logger.d("AboutTab", "Component.onCompleted - Extracted commit from NixOS path:", root.commitInfo);
            return;
          } else {
            Logger.d("AboutTab", "Component.onCompleted - Could not extract commit from NixOS path, trying fallback");
          }
        }
        fetchGitCommit();
        return;
      } else {
        // On non-NixOS systems, check for pacman first.
        whichPacmanProcess.running = true;
        return;
      }
    }
  }

  Timer {
    id: gitFallbackTimer
    interval: 500
    running: false
    onTriggered: {
      if (!root.commitInfo) {
        fetchGitCommit();
      }
    }
  }

  Process {
    id: whichPacmanProcess
    command: ["which", "pacman"]
    running: false
    onExited: function (exitCode) {
      if (exitCode === 0) {
        Logger.d("AboutTab", "whichPacmanProcess - pacman found, starting query");
        pacmanProcess.running = true;
        gitFallbackTimer.start();
      } else {
        Logger.d("AboutTab", "whichPacmanProcess - pacman not found, falling back to git");
        fetchGitCommit();
      }
    }
  }

  Process {
    id: pacmanProcess
    command: ["pacman", "-Q", "noctalia-shell-git"]
    running: false

    onStarted: {
      gitFallbackTimer.stop();
    }

    onExited: function (exitCode) {
      gitFallbackTimer.stop();
      Logger.d("AboutTab", "pacmanProcess - Process exited with code:", exitCode);
      if (exitCode === 0) {
        var output = stdout.text.trim();
        Logger.d("AboutTab", "pacmanProcess - Output:", output);
        var match = output.match(/noctalia-shell-git\s+(.+)/);
        if (match && match[1]) {
          // For Arch packages, the version format might be like: 3.4.0.r112.g3f00bec8-1
          // Extract just the commit hash part if it exists
          var version = match[1];
          var commitMatch = version.match(/\.g([0-9a-f]{7,})/i);
          if (commitMatch && commitMatch[1]) {
            // Show short hash (first 7 characters)
            root.commitInfo = commitMatch[1].substring(0, 7);
            Logger.d("AboutTab", "pacmanProcess - Set commitInfo from Arch package:", root.commitInfo);
            return; // Successfully got commit hash from Arch package
          } else {
            // If no commit hash in version format, still try git repo
            Logger.d("AboutTab", "pacmanProcess - No commit hash in version, trying git");
            fetchGitCommit();
          }
        } else {
          // Unexpected output format, try git
          Logger.d("AboutTab", "pacmanProcess - Unexpected output format, trying git");
          fetchGitCommit();
        }
      } else {
        // If not on Arch, try to get git commit from repository
        Logger.d("AboutTab", "pacmanProcess - Package not found, trying git");
        fetchGitCommit();
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  function fetchGitCommit() {
    var shellDir = Quickshell.shellDir || "";
    Logger.d("AboutTab", "fetchGitCommit - shellDir:", shellDir);
    if (!shellDir) {
      Logger.d("AboutTab", "fetchGitCommit - Cannot determine shell directory, skipping git commit fetch");
      return;
    }

    gitProcess.workingDirectory = shellDir;
    gitProcess.running = true;
  }

  Process {
    id: gitProcess
    command: ["git", "rev-parse", "--short", "HEAD"]
    running: false

    onExited: function (exitCode) {
      Logger.d("AboutTab", "gitProcess - Process exited with code:", exitCode);
      if (exitCode === 0) {
        var gitOutput = stdout.text.trim();
        Logger.d("AboutTab", "gitProcess - gitOutput:", gitOutput);
        if (gitOutput) {
          root.commitInfo = gitOutput;
          Logger.d("AboutTab", "gitProcess - Set commitInfo to:", root.commitInfo);
        }
      } else {
        Logger.d("AboutTab", "gitProcess - Git command failed. Exit code:", exitCode);
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  NHeader {
    label: I18n.tr("settings.about.noctalia.section.label")
    description: I18n.tr("settings.about.noctalia.section.description")
  }

  RowLayout {
    spacing: Style.marginXL

    // Versions
    GridLayout {
      columns: 2
      rowSpacing: Style.marginXS
      columnSpacing: Style.marginS

      NText {
        text: I18n.tr("settings.about.noctalia.latest-version")
        color: Color.mOnSurface
      }

      NText {
        text: root.latestVersion
        color: Color.mOnSurface
        font.weight: Style.fontWeightBold
      }

      NText {
        text: I18n.tr("settings.about.noctalia.installed-version")
        color: Color.mOnSurface
      }

      NText {
        text: root.currentVersion
        color: Color.mOnSurface
        font.weight: Style.fontWeightBold
      }

      NText {
        visible: root.isGitVersion
        text: I18n.tr("settings.about.noctalia.git-commit")
        color: Color.mOnSurface
      }

      NText {
        visible: root.isGitVersion
        text: root.commitInfo || I18n.tr("settings.about.noctalia.git-commit-loading")
        color: Color.mOnSurface
        font.weight: Style.fontWeightBold
        font.family: root.commitInfo ? "monospace" : ""
        pointSize: Style.fontSizeXS
      }
    }
  }

  // Ko-fi support button
  Rectangle {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
    width: supportRow.implicitWidth + Style.marginXL
    height: supportRow.implicitHeight + Style.marginM
    radius: Style.radiusS
    color: supportArea.containsMouse ? Qt.alpha(Color.mOnSurface, 0.05) : Color.transparent
    border.width: 0

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    RowLayout {
      id: supportRow
      anchors.centerIn: parent
      spacing: Style.marginS

      NText {
        text: I18n.tr("settings.about.support")
        pointSize: Style.fontSizeXS
        color: Color.mOnSurface
        opacity: supportArea.containsMouse ? Style.opacityFull : Style.opacityMedium
      }

      NIcon {
        icon: supportArea.containsMouse ? "heart-filled" : "heart"
        pointSize: 14
        color: Color.mOnSurface
        opacity: supportArea.containsMouse ? Style.opacityFull : Style.opacityMedium
      }
    }

    MouseArea {
      id: supportArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        Quickshell.execDetached(["xdg-open", "https://ko-fi.com/lysec"]);
        ToastService.showNotice(I18n.tr("settings.about.support"), I18n.tr("toast.kofi.opened"));
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXXXL
    Layout.bottomMargin: Style.marginL
  }

  // Contributors






  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }
}
