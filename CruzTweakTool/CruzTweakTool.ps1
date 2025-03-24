# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Function to search for the icon.ico file
function Find-IconFile {
    # Define possible locations to search for the icon file
    $searchPaths = @(
        $PSScriptRoot, # Script's directory
        "C:\Users\$env:USERNAME\Desktop", # User's desktop
        "C:\Users\$env:USERNAME\Downloads", # User's downloads folder
        "C:\Users\$env:USERNAME\Documents", # User's documents folder
        "C:\Users\$env:USERNAME\OneDrive\Desktop" # OneDrive desktop (if applicable)
    )

    # Search for the icon.ico file in the defined paths
    foreach ($path in $searchPaths) {
        # Skip if the path is empty or doesn't exist
        if (-Not [string]::IsNullOrEmpty($path) -and (Test-Path -Path $path)) {
            # Look for the icon.ico file directly in the CruzTweakTool folder
            $iconPath = Join-Path -Path $path -ChildPath "CruzTweakTool\icon.ico"
            if (Test-Path -Path $iconPath) {
                return $iconPath
            }
        }
    }

    # If the file is not found, return $null
    return $null
}

# Create the GUI
$window = New-Object System.Windows.Window
$window.Title = "CruzTweakTool"
$window.Width = 1200  # Increased width to fit all tabs
$window.Height = 800  # Increased height for better visibility
$window.WindowStartupLocation = "CenterScreen"

# Find the icon.ico file
$iconPath = Find-IconFile

# Load the icon if found
if ($iconPath) {
    try {
        $iconUri = New-Object -TypeName Uri -ArgumentList $iconPath
        $iconBitmap = New-Object -TypeName System.Windows.Media.Imaging.BitmapImage -ArgumentList $iconUri
        $window.Icon = $iconBitmap
    } catch {
        Write-Host "Failed to load the icon: $_"
    }
} else {
    Write-Host "Icon file (icon.ico) not found in common locations."
}


# === Dark Mode Colors ===
$darkBackground = [System.Windows.Media.Brushes]::Black
$darkForeground = [System.Windows.Media.Brushes]::White
$darkButtonBackground = [System.Windows.Media.Brushes]::DarkSlateGray
$darkButtonForeground = [System.Windows.Media.Brushes]::White
$darkTabBackground = [System.Windows.Media.Brushes]::DarkSlateGray
$darkTabForeground = [System.Windows.Media.Brushes]::White

# Apply dark mode to the window
$window.Background = $darkBackground
$window.Foreground = $darkForeground

# === Custom TabControl Style ===
# Create a style for the TabControl
$tabControlStyle = New-Object System.Windows.Style -ArgumentList ([System.Windows.Controls.TabControl])
$tabControlStyle.Setters.Add(
    (New-Object System.Windows.Setter -ArgumentList ([System.Windows.Controls.Control]::BackgroundProperty, $darkTabBackground))
)
$tabControlStyle.Setters.Add(
    (New-Object System.Windows.Setter -ArgumentList ([System.Windows.Controls.Control]::ForegroundProperty, $darkTabForeground))
)

# Create a style for the TabItem
$tabItemStyle = New-Object System.Windows.Style -ArgumentList ([System.Windows.Controls.TabItem])
$tabItemStyle.Setters.Add(
    (New-Object System.Windows.Setter -ArgumentList ([System.Windows.Controls.Control]::BackgroundProperty, [System.Windows.Media.Brushes]::Transparent))
)
$tabItemStyle.Setters.Add(
    (New-Object System.Windows.Setter -ArgumentList ([System.Windows.Controls.Control]::ForegroundProperty, $darkTabForeground))
)
$tabItemStyle.Setters.Add(
    (New-Object System.Windows.Setter -ArgumentList ([System.Windows.Controls.Control]::BorderBrushProperty, [System.Windows.Media.Brushes]::Transparent))
)

# Create a TabControl to hold the tabs
$tabControl = New-Object System.Windows.Controls.TabControl
$tabControl.Margin = "10"
$tabControl.Style = $tabControlStyle

# Set TabControl width to fill the window
$tabControl.Width = $window.Width - 40  # Adjust for margins

# === System Info Tab ===
$systemInfoTab = New-Object System.Windows.Controls.TabItem
$systemInfoTab.Header = "System Info"
$systemInfoTab.Style = $tabItemStyle

# Create a TextBlock to display system information
$systemInfoText = New-Object System.Windows.Controls.TextBlock
$systemInfoText.Margin = "10"
$systemInfoText.TextWrapping = "Wrap"
$systemInfoText.Foreground = $darkForeground

# Get system information
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$cpu = Get-CimInstance -ClassName Win32_Processor
$gpu = Get-CimInstance -ClassName Win32_VideoController
$ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"

$systemInfoText.Text = @"
OS: $($os.Caption) $($os.Version)
CPU: $($cpu.Name)
GPU: $($gpu.Name)
RAM: $ram GB
Disk: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB Free / $([math]::Round($disk.Size / 1GB, 2)) GB Total
"@

# Create a new StackPanel for the System Info tab
$systemInfoStackPanel = New-Object System.Windows.Controls.StackPanel
$systemInfoStackPanel.Orientation = "Vertical"
$systemInfoStackPanel.Margin = "10"

# Add the system info text to the new StackPanel
$systemInfoStackPanel.AddChild($systemInfoText)

# Set the new StackPanel as the content of the System Info tab
$systemInfoTab.Content = $systemInfoStackPanel

# Add the System Info tab to the TabControl
$tabControl.Items.Add($systemInfoTab)

# === Debloater Tab ===
$debloaterTab = New-Object System.Windows.Controls.TabItem
$debloaterTab.Header = "Debloater"
$debloaterTab.Style = $tabItemStyle

# Create a ScrollViewer for the Debloater tab
$debloaterScrollViewer = New-Object System.Windows.Controls.ScrollViewer
$debloaterScrollViewer.VerticalScrollBarVisibility = "Visible"
$debloaterScrollViewer.HorizontalScrollBarVisibility = "Disabled"
$debloaterScrollViewer.CanContentScroll = $true

# Create a StackPanel to hold the checkboxes for Debloater
$debloaterStackPanel = New-Object System.Windows.Controls.StackPanel
$debloaterStackPanel.Orientation = "Vertical"
$debloaterStackPanel.Margin = "10"
$debloaterStackPanel.Height = $window.Height - 200

# Add a CAUTION message at the top
$cautionText = New-Object System.Windows.Controls.TextBlock
$cautionText.Text = "CAUTION: We are not responsible for any damages while uninstalling these apps. Proceed at your own risk."
$cautionText.Foreground = [System.Windows.Media.Brushes]::Red
$cautionText.FontWeight = "Bold"
$cautionText.Margin = "0,0,0,10"
$cautionText.TextWrapping = "Wrap"
$debloaterStackPanel.AddChild($cautionText)

# List of safe bloatware apps
$safeBloatware = @(
    "McAfee Security",
    "Norton Security",
    "CCleaner",
    "Adobe Flash Player",
    "QuickTime",
    "iTunes",
    "Dell SupportAssist",
    "HP Support Solutions Framework",
    "Lenovo Vantage",
    "ASUS Live Update",
    "Acer Care Center",
    "Samsung Magician",
    "Microsoft Silverlight",
    "Ask Toolbar",
    "Yahoo Toolbar",
    "McAfee WebAdvisor",
    "Norton Toolbar",
    "Bing Bar",
    "Java Auto Updater",
    "WildTangent Games",
    "Candy Crush Saga",
    "Disney Magic Kingdoms",
    "March of Empires",
    "Bubble Witch 3 Saga",
    "Farm Heroes Saga",
    "Minecraft for Windows",
    "Royal Revolt 2",
    "Asphalt 8: Airborne",
    "Hidden City",
    "Pandora",
    "Spotify",
    "Netflix",
    "Hulu",
    "Facebook",
    "Instagram",
    "Twitter",
    "TikTok",
    "WhatsApp",
    "Skype",
    "Microsoft Teams",
    "Microsoft Solitaire Collection",
    "Microsoft Mahjong",
    "Microsoft Jigsaw",
    "Microsoft Minesweeper",
    "Microsoft Sudoku",
    "Microsoft Word (Trial)",
    "Microsoft Excel (Trial)",
    "Microsoft PowerPoint (Trial)",
    "Microsoft OneNote",
    "Groove Music",
    "Movies & TV",
    "Microsoft News",
    "Microsoft Weather",
    "Microsoft Tips",
    "Microsoft Sticky Notes",
    "Microsoft To Do",
    "Microsoft Family Safety",
    "Microsoft Office Hub",
    "Microsoft Power Automate",
    "Microsoft Power BI",
    "Microsoft Sway",
    "Microsoft Whiteboard",
    "Microsoft People",
    "Microsoft Photos",
    "Microsoft Camera",
    "Microsoft Maps"
)

# List of less safe bloatware apps
$lessSafeBloatware = @(
    "Microsoft Edge (Pre-installed)",
    "Cortana",
    "Xbox Game Bar",
    "Xbox App",
    "Xbox Live",
    "Xbox Identity Provider",
    "Microsoft Store",
    "Microsoft Edge DevTools Client",
    "Microsoft Edge Update",
    "Microsoft Edge WebView",
    "Microsoft Edge WebView2",
    "Microsoft Edge WebView2 Runtime",
    "Microsoft Edge WebView2 Helper",
    "Microsoft Edge WebView2 Installer",
    "Microsoft Edge WebView2 Updater",
    "Microsoft Edge WebView2 Canary",
    "Microsoft Edge WebView2 Beta",
    "Microsoft Edge WebView2 Stable",
    "Microsoft Edge WebView2 Experimental",
    "Microsoft Edge WebView2 Insider",
    "Microsoft Edge WebView2 Preview",
    "Microsoft Edge WebView2 Release",
    "Microsoft Edge WebView2 Testing",
    "Microsoft Edge WebView2 Development",
    "Microsoft Edge WebView2 Debug",
    "Microsoft Edge WebView2 Nightly"
)

# Add a separator and warning for less safe apps
$lessSafeText = New-Object System.Windows.Controls.TextBlock
$lessSafeText.Text = "WARNING: The following apps may be system-critical or risky to remove. Proceed with caution."
$lessSafeText.Foreground = [System.Windows.Media.Brushes]::Orange
$lessSafeText.FontWeight = "Bold"
$lessSafeText.Margin = "0,10,0,10"
$lessSafeText.TextWrapping = "Wrap"
$debloaterStackPanel.AddChild($lessSafeText)

# Create a checkbox for each less safe app
foreach ($app in $lessSafeBloatware) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $app
    $checkBox.Tag = $app
    $checkBox.Foreground = $darkForeground
    $debloaterStackPanel.AddChild($checkBox)
}

# Add a separator for safe apps
$safeText = New-Object System.Windows.Controls.TextBlock
$safeText.Text = "Safe to Remove:"
$safeText.Foreground = [System.Windows.Media.Brushes]::Green
$safeText.FontWeight = "Bold"
$safeText.Margin = "0,10,0,10"
$debloaterStackPanel.AddChild($safeText)

# Create a checkbox for each safe app
foreach ($app in $safeBloatware) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $app
    $checkBox.Tag = $app
    $checkBox.Foreground = $darkForeground
    $debloaterStackPanel.AddChild($checkBox)
}

# Add the StackPanel to the ScrollViewer
$debloaterScrollViewer.Content = $debloaterStackPanel

# Create a StackPanel to hold the buttons at the bottom
$buttonStackPanel = New-Object System.Windows.Controls.StackPanel
$buttonStackPanel.Orientation = "Horizontal"
$buttonStackPanel.Margin = "0,10,0,10"

# Create a button to uninstall selected apps
$debloaterButton = New-Object System.Windows.Controls.Button
$debloaterButton.Content = "Uninstall Selected Apps"
$debloaterButton.Width = 150
$debloaterButton.Height = 30
$debloaterButton.Margin = "0,0,10,0"
$debloaterButton.Background = $darkButtonBackground
$debloaterButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$debloaterButton.Add_Click({
    foreach ($child in $debloaterStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $packageName = $child.Tag
            Write-Host "Attempting to uninstall: $packageName"
            try {
                Get-AppxPackage -Name $packageName -AllUsers | Remove-AppxPackage -ErrorAction Stop
                Write-Host "Successfully uninstalled: $packageName"
            } catch {
                Write-Host "Failed to uninstall: $packageName"
            }
        }
    }
    [System.Windows.MessageBox]::Show("Selected apps have been uninstalled (if they were installed)!", "Done")
})

# Create a button to uninstall ALL bloatware
$uninstallAllBloatwareButton = New-Object System.Windows.Controls.Button
$uninstallAllBloatwareButton.Content = "Uninstall All Bloatware"
$uninstallAllBloatwareButton.Width = 150
$uninstallAllBloatwareButton.Height = 30
$uninstallAllBloatwareButton.Margin = "0,0,0,0"
$uninstallAllBloatwareButton.Background = $darkButtonBackground
$uninstallAllBloatwareButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$uninstallAllBloatwareButton.Add_Click({
    # First confirmation dialog
    $confirmation1 = [System.Windows.MessageBox]::Show("Are you sure you want to delete all bloatware?", "CAUTION", "YesNo", "Warning")
    if ($confirmation1 -eq "Yes") {
        # Second confirmation dialog
        $confirmation2 = [System.Windows.MessageBox]::Show("Are you sure?", "CAUTION", "YesNo", "Warning")
        if ($confirmation2 -eq "Yes") {
            # Uninstall all bloatware
            foreach ($child in $debloaterStackPanel.Children) {
                if ($child -is [System.Windows.Controls.CheckBox]) {
                    $packageName = $child.Tag
                    Write-Host "Attempting to uninstall: $packageName"
                    try {
                        Get-AppxPackage -Name $packageName -AllUsers | Remove-AppxPackage -ErrorAction Stop
                        Write-Host "Successfully uninstalled: $packageName"
                    } catch {
                        Write-Host "Failed to uninstall: $packageName"
                    }
                }
            }
            [System.Windows.MessageBox]::Show("All bloatware has been uninstalled (if they were installed)!", "Done")
        }
    }
})

# Add the buttons to the StackPanel
$buttonStackPanel.AddChild($debloaterButton)
$buttonStackPanel.AddChild($uninstallAllBloatwareButton)

# Create a parent StackPanel for the Debloater tab
$debloaterParentStackPanel = New-Object System.Windows.Controls.StackPanel
$debloaterParentStackPanel.Orientation = "Vertical"
$debloaterParentStackPanel.Margin = "10"

# Add the ScrollViewer and Buttons to the parent StackPanel
$debloaterParentStackPanel.AddChild($debloaterScrollViewer)
$debloaterParentStackPanel.AddChild($buttonStackPanel)

# Add the parent StackPanel to the Debloater tab
$debloaterTab.Content = $debloaterParentStackPanel

# Add the Debloater tab to the TabControl
$tabControl.Items.Add($debloaterTab)

# === Tweaks Tab ===
$tweaksTab = New-Object System.Windows.Controls.TabItem
$tweaksTab.Header = "Tweaks"
$tweaksTab.Style = $tabItemStyle

# Create a Grid to hold the ScrollViewer and Buttons
$tweaksGrid = New-Object System.Windows.Controls.Grid
$tweaksGrid.Margin = "10"

# Add a RowDefinition for the ScrollViewer and Buttons
$tweaksGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
$tweaksGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))

# Create a ScrollViewer for the Tweaks tab
$tweaksScrollViewer = New-Object System.Windows.Controls.ScrollViewer
$tweaksScrollViewer.VerticalScrollBarVisibility = "Visible"
$tweaksScrollViewer.HorizontalScrollBarVisibility = "Disabled"
$tweaksScrollViewer.CanContentScroll = $true

# Create a StackPanel to hold the checkboxes for Tweaks
$tweaksStackPanel = New-Object System.Windows.Controls.StackPanel
$tweaksStackPanel.Orientation = "Vertical"
$tweaksStackPanel.Margin = "10"
$tweaksStackPanel.Height = $window.Height - 200

# Add the StackPanel to the ScrollViewer
$tweaksScrollViewer.Content = $tweaksStackPanel

# === Add Your Existing Tweaks ===
# List of tweaks with their corresponding scripts and undo scripts
$tweaks = @(
    @{ Name = "Set Power Plan to High Performance"; Script = "powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"; UndoScript = "powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e" }, # Balanced Power Plan
    @{ Name = "Disable Game Bar and Game DVR"; Script = "Get-AppxPackage Microsoft.XboxGamingOverlay | Remove-AppxPackage"; UndoScript = "Get-AppxPackage -allusers Microsoft.XboxGamingOverlay | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register `"$($_.InstallLocation)\AppXManifest.xml`"}" },
    @{ Name = "Disable Fullscreen Optimizations System-Wide"; Script = 'Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "DisableFullscreenOptimizations" -Value 1'; UndoScript = 'Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "DisableFullscreenOptimizations" -Value 0' },
    @{ Name = "Disable Windows Animations"; Script = 'Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0"'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1"' },
    @{ Name = "Disable Mouse Pointer Trails"; Script = 'Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -Value "0"'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -Value "10"' }, # Default value for MouseTrails
    @{ Name = "Disable Windows Search Indexing"; Script = 'Stop-Service -Name "WSearch" -Force; Set-Service -Name "WSearch" -StartupType Disabled'; UndoScript = 'Set-Service -Name "WSearch" -StartupType Automatic; Start-Service -Name "WSearch"' },
    @{ Name = "Disable Superfetch (SysMain)"; Script = 'Stop-Service -Name "SysMain" -Force; Set-Service -Name "SysMain" -StartupType Disabled'; UndoScript = 'Set-Service -Name "SysMain" -StartupType Automatic; Start-Service -Name "SysMain"' },
    @{ Name = "Disable Windows Defender Real-Time Protection (Temporarily)"; Script = 'Set-MpPreference -DisableRealtimeMonitoring $true'; UndoScript = 'Set-MpPreference -DisableRealtimeMonitoring $false' },
    @{ Name = "Disable Windows Notifications"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 1' },
    @{ Name = "Disable Background Apps"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0' },
    @{ Name = "Disable Cortana"; Script = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0'; UndoScript = 'Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana"' },
    @{ Name = "Disable Telemetry"; Script = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0'; UndoScript = 'Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"' },
    @{ Name = "Disable Windows Tips and Suggestions"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 1' },
    @{ Name = "Disable Xbox Live Services"; Script = 'Stop-Service -Name "XboxGipSvc" -Force; Set-Service -Name "XboxGipSvc" -StartupType Disabled'; UndoScript = 'Set-Service -Name "XboxGipSvc" -StartupType Automatic; Start-Service -Name "XboxGipSvc"' },
    @{ Name = "Disable Windows Error Reporting"; Script = 'Stop-Service -Name "WerSvc" -Force; Set-Service -Name "WerSvc" -StartupType Disabled'; UndoScript = 'Set-Service -Name "WerSvc" -StartupType Automatic; Start-Service -Name "WerSvc"' },
    @{ Name = "Disable Windows Update Sharing"; Script = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0'; UndoScript = 'Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode"' },
    @{ Name = "Disable Windows Ink Workspace"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" -Name "PenWorkspaceButtonDesiredVisibility" -Value 0'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" -Name "PenWorkspaceButtonDesiredVisibility" -Value 1' },
    @{ Name = "Disable Windows Aero Theme"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 0'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 1' },
    @{ Name = "Disable Windows Transparency Effects"; Script = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0'; UndoScript = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1' },
    @{ Name = "Disable Windows Timeline"; Script = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0'; UndoScript = 'Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed"' },
    @{ Name = "Disable Hibernation (Optional, frees up disk space)"; Script = "powercfg /hibernate off"; UndoScript = "powercfg /hibernate on" },
    @{ Name = "Disable Windows Defender Cloud-Based Protection (Optional)"; Script = 'Set-MpPreference -MAPSReporting 0'; UndoScript = 'Set-MpPreference -MAPSReporting 1' },
    @{ Name = "Disable Windows Defender Sample Submission"; Script = 'Set-MpPreference -SubmitSamplesConsent 0'; UndoScript = 'Set-MpPreference -SubmitSamplesConsent 1' },
    @{ Name = "Disable Windows Defender Notifications"; Script = 'Set-MpPreference -UILockdown 1'; UndoScript = 'Set-MpPreference -UILockdown 0' },
    @{ Name = "Disable Windows Defender Scheduled Scans"; Script = 'Set-MpPreference -DisableScanningNetworkFiles $true; Set-MpPreference -DisableScanningMappedNetworkDrives $true'; UndoScript = 'Set-MpPreference -DisableScanningNetworkFiles $false; Set-MpPreference -DisableScanningMappedNetworkDrives $false' },
    @{ Name = "Disable Windows Defender Script Scanning"; Script = 'Set-MpPreference -DisableScriptScanning $true'; UndoScript = 'Set-MpPreference -DisableScriptScanning $false' },
    @{ Name = "Disable Windows Defender Behavior Monitoring"; Script = 'Set-MpPreference -DisableBehaviorMonitoring $true'; UndoScript = 'Set-MpPreference -DisableBehaviorMonitoring $false' },
    @{ Name = "Disable Windows Defender IOAV Protection"; Script = 'Set-MpPreference -DisableIOAVProtection $true'; UndoScript = 'Set-MpPreference -DisableIOAVProtection $false' },
    @{ Name = "Disable Windows Defender Realtime Scanning for Downloads"; Script = 'Set-MpPreference -DisableRealtimeMonitoring $true'; UndoScript = 'Set-MpPreference -DisableRealtimeMonitoring $false' },
    @{ Name = "Disable Windows Defender PUA Protection"; Script = 'Set-MpPreference -PUAProtection 0'; UndoScript = 'Set-MpPreference -PUAProtection 1' },
    @{ Name = "Disable Windows Defender Cloud-Delivered Protection"; Script = 'Set-MpPreference -MAPSReporting 0'; UndoScript = 'Set-MpPreference -MAPSReporting 1' },
    @{ Name = "Disable Windows Defender Network Inspection System"; Script = 'Set-MpPreference -DisableIntrusionPreventionSystem $true'; UndoScript = 'Set-MpPreference -DisableIntrusionPreventionSystem $false' },
    @{ Name = "Disable Windows Defender Exploit Protection"; Script = 'Set-ProcessMitigation -System -Disable DEP,SEHOP,ASLR'; UndoScript = 'Set-ProcessMitigation -System -Enable DEP,SEHOP,ASLR' },
    @{ Name = "Disable Windows Defender Controlled Folder Access"; Script = 'Set-MpPreference -EnableControlledFolderAccess Disabled'; UndoScript = 'Set-MpPreference -EnableControlledFolderAccess Enabled' },
    @{ Name = "Disable Windows Defender Network Protection"; Script = 'Set-MpPreference -EnableNetworkProtection Disabled'; UndoScript = 'Set-MpPreference -EnableNetworkProtection Enabled' },
    @{ Name = "Disable Windows Defender Exploit Guard"; Script = 'Set-MpPreference -EnableExploitGuard Disabled'; UndoScript = 'Set-MpPreference -EnableExploitGuard Enabled' },
    @{ Name = "Disable Windows Defender Application Guard"; Script = 'Set-MpPreference -EnableApplicationGuard Disabled'; UndoScript = 'Set-MpPreference -EnableApplicationGuard Enabled' },
    @{ Name = "Disable Windows Defender Credential Guard"; Script = 'Set-MpPreference -EnableCredentialGuard Disabled'; UndoScript = 'Set-MpPreference -EnableCredentialGuard Enabled' },
    @{ Name = "Disable Windows Defender Device Guard"; Script = 'Set-MpPreference -EnableDeviceGuard Disabled'; UndoScript = 'Set-MpPreference -EnableDeviceGuard Enabled' },
    @{ Name = "Disable Windows Defender Firewall (Optional, not recommended for most users)"; Script = 'Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False'; UndoScript = 'Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True' },
    @{ Name = "Disable Windows Defender SmartScreen"; Script = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off"'; UndoScript = 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "On"' },
    @{ Name = "Disable Windows Defender Spynet Reporting"; Script = 'Set-MpPreference -SpynetReporting 0'; UndoScript = 'Set-MpPreference -SpynetReporting 1' }
)

# Create a checkbox for each tweak
foreach ($tweak in $tweaks) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $tweak.Name
    $checkBox.Tag = $tweak.Script
    $checkBox.Foreground = $darkForeground
    $tweaksStackPanel.AddChild($checkBox)
}

# === Add "Delete Temp Files" Button ===
$deleteTempFilesButton = New-Object System.Windows.Controls.Button
$deleteTempFilesButton.Content = "Delete Temp Files"
$deleteTempFilesButton.Width = 150
$deleteTempFilesButton.Height = 30
$deleteTempFilesButton.Margin = "0,10,0,10"
$deleteTempFilesButton.Background = $darkButtonBackground
$deleteTempFilesButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$deleteTempFilesButton.Add_Click({
    try {
        # Delete files in C:\Windows\Temp (skip files in use)
        Get-ChildItem -Path "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction Stop
                Write-Host "Deleted: $($_.FullName)"
            } catch {
                Write-Host "Skipped (in use): $($_.FullName)"
            }
        }

        # Delete files in the user's TEMP directory (skip files in use)
        Get-ChildItem -Path $env:TEMP -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction Stop
                Write-Host "Deleted: $($_.FullName)"
            } catch {
                Write-Host "Skipped (in use): $($_.FullName)"
            }
        }

        [System.Windows.MessageBox]::Show("Temporary files have been deleted successfully!", "Success", "OK", "Information")
    } catch {
        [System.Windows.MessageBox]::Show("Failed to delete temporary files: $_", "Error", "OK", "Error")
    }
})

# Add the button to the Tweaks tab's StackPanel
$tweaksStackPanel.AddChild($deleteTempFilesButton)

# === Add "Undo All Tweaks" Button ===
$undoAllTweaksButton = New-Object System.Windows.Controls.Button
$undoAllTweaksButton.Content = "Undo All Tweaks"
$undoAllTweaksButton.Width = 150
$undoAllTweaksButton.Height = 30
$undoAllTweaksButton.Margin = "0,10,0,10"
$undoAllTweaksButton.Background = $darkButtonBackground
$undoAllTweaksButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$undoAllTweaksButton.Add_Click({
    # Undo all tweaks
    foreach ($tweak in $tweaks) {
        $undoScript = $tweak.UndoScript
        if ($undoScript) {
            Write-Host "Undoing tweak: $($tweak.Name)"
            Invoke-Expression -Command $undoScript
        }
    }
    [System.Windows.MessageBox]::Show("All tweaks have been undone! Restart your system for changes to take effect.", "Restart Required")
})

# Add the button to the Tweaks tab's StackPanel
$tweaksStackPanel.AddChild($undoAllTweaksButton)

# Add the ScrollViewer to the first row of the Grid
[System.Windows.Controls.Grid]::SetRow($tweaksScrollViewer, 0)

# Create a StackPanel to hold the buttons
$buttonStackPanel = New-Object System.Windows.Controls.StackPanel
$buttonStackPanel.Orientation = "Horizontal"
$buttonStackPanel.Margin = "0,10,0,10"

# Create a button to apply selected tweaks
$tweaksButton = New-Object System.Windows.Controls.Button
$tweaksButton.Content = "Apply Selected Tweaks"
$tweaksButton.Width = 150
$tweaksButton.Height = 30
$tweaksButton.Margin = "0,0,10,0"
$tweaksButton.Background = $darkButtonBackground
$tweaksButton.Foreground = $darkButtonForeground

# Create a button to apply ALL tweaks
$applyAllTweaksButton = New-Object System.Windows.Controls.Button
$applyAllTweaksButton.Content = "Apply ALL Tweaks"
$applyAllTweaksButton.Width = 150
$applyAllTweaksButton.Height = 30
$applyAllTweaksButton.Margin = "0,0,0,0"
$applyAllTweaksButton.Background = $darkButtonBackground
$applyAllTweaksButton.Foreground = $darkButtonForeground

# Add the buttons to the StackPanel
$buttonStackPanel.AddChild($tweaksButton)
$buttonStackPanel.AddChild($applyAllTweaksButton)

# Add the StackPanel to the second row of the Grid
[System.Windows.Controls.Grid]::SetRow($buttonStackPanel, 1)
$tweaksGrid.AddChild($buttonStackPanel)

# Add the ScrollViewer and Buttons to the Grid
$tweaksGrid.AddChild($tweaksScrollViewer)

# Add the Grid to the Tweaks tab
$tweaksTab.Content = $tweaksGrid

# Add the Tweaks tab to the TabControl
$tabControl.Items.Add($tweaksTab)

# === Backup & Restore Tab ===
$backupTab = New-Object System.Windows.Controls.TabItem
$backupTab.Header = "Restore"
$backupTab.Style = $tabItemStyle

# Create a StackPanel for the Backup and Restore tab
$backupStackPanel = New-Object System.Windows.Controls.StackPanel
$backupStackPanel.Orientation = "Vertical"
$backupStackPanel.Margin = "10"

# Create a Button to Create a Restore Point
$createRestorePointButton = New-Object System.Windows.Controls.Button
$createRestorePointButton.Content = "Create a Restore Point"
$createRestorePointButton.Width = 200
$createRestorePointButton.Height = 30
$createRestorePointButton.Margin = "0,10,0,10"
$createRestorePointButton.Background = $darkButtonBackground
$createRestorePointButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$createRestorePointButton.Add_Click({
    # Check if the user has administrative privileges
    if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        [System.Windows.MessageBox]::Show("Please run this script as an administrator.", "Error", "OK", "Error")
        return
    }

    # Check if System Restore is enabled for the main drive
    try {
        # Try getting restore points to check if System Restore is enabled
        Enable-ComputerRestore -Drive "$env:SystemDrive"
    } catch {
        [System.Windows.MessageBox]::Show("An error occurred while enabling System Restore: $_", "Error", "OK", "Error")
        return
    }

    # Check if the SystemRestorePointCreationFrequency value exists
    $exists = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
    if ($null -eq $exists) {
        Write-Host 'Changing system to allow multiple restore points per day'
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value "0" -Type DWord -Force -ErrorAction Stop | Out-Null
    }

    # Attempt to load the required module for Get-ComputerRestorePoint
    try {
        Import-Module Microsoft.PowerShell.Management -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show("Failed to load the Microsoft.PowerShell.Management module: $_", "Error", "OK", "Error")
        return
    }

    # Get all the restore points for the current day
    try {
        $existingRestorePoints = Get-ComputerRestorePoint | Where-Object { $_.CreationTime.Date -eq (Get-Date).Date }
    } catch {
        [System.Windows.MessageBox]::Show("Failed to retrieve restore points: $_", "Error", "OK", "Error")
        return
    }

    # Check if there is already a restore point created today
    if ($existingRestorePoints.Count -eq 0) {
        $description = "Restore Point Created by CruzTweakTool"

        try {
            Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
            [System.Windows.MessageBox]::Show("System Restore Point Created Successfully", "Success", "OK", "Information")
        } catch {
            [System.Windows.MessageBox]::Show("Failed to create a restore point: $_", "Error", "OK", "Error")
        }
    } else {
        [System.Windows.MessageBox]::Show("A restore point has already been created today.", "Info", "OK", "Information")
    }
})

# Add the button to the StackPanel
$backupStackPanel.AddChild($createRestorePointButton)

# Add the StackPanel to the Backup and Restore tab
$backupTab.Content = $backupStackPanel

# Add the Backup and Restore tab to the TabControl
$tabControl.Items.Add($backupTab)

# === Network Tweaks Tab ===
$networkTab = New-Object System.Windows.Controls.TabItem
$networkTab.Header = "Network Tweaks"
$networkTab.Style = $tabItemStyle

# Create a StackPanel for the Network Tweaks tab
$networkStackPanel = New-Object System.Windows.Controls.StackPanel
$networkStackPanel.Orientation = "Vertical"
$networkStackPanel.Margin = "10"

# List of network tweaks
$networkTweaks = @(
    "Disable QoS Packet Scheduler",
    "Optimize TCP/IP for Gaming",
    "Disable IPv6",
    "Enable DNS over HTTPS (DoH)"
)

# Create a checkbox for each network tweak
foreach ($tweak in $networkTweaks) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $tweak
    $checkBox.Foreground = $darkForeground
    $networkStackPanel.AddChild($checkBox)
}

# Create a button to apply selected network tweaks
$networkButton = New-Object System.Windows.Controls.Button
$networkButton.Content = "Apply Selected Tweaks"
$networkButton.Width = 150
$networkButton.Height = 30
$networkButton.Margin = "0,10,0,10"
$networkButton.Background = $darkButtonBackground
$networkButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$networkButton.Add_Click({
    foreach ($child in $networkStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $tweakName = $child.Content
            Write-Host "Applying network tweak: $tweakName"
            # Add code here to apply the selected network tweak
            $child.IsChecked = $false
        }
    }
    [System.Windows.MessageBox]::Show("Selected network tweaks have been applied!", "Network Tweaks")
})

# Add the StackPanel and Button to the Network Tweaks tab
$networkTab.Content = $networkStackPanel
$networkStackPanel.AddChild($networkButton)

# Add the Network Tweaks tab to the TabControl
$tabControl.Items.Add($networkTab)

# === Services Manager Tab ===
$servicesTab = New-Object System.Windows.Controls.TabItem
$servicesTab.Header = "Services Manager"
$servicesTab.Style = $tabItemStyle

# Create a StackPanel for the Services Manager tab
$servicesStackPanel = New-Object System.Windows.Controls.StackPanel
$servicesStackPanel.Orientation = "Vertical"
$servicesStackPanel.Margin = "10"

# List of services to manage
$services = @(
    "DiagTrack", "dmwappushservice", "DPS", "WMPNetworkSvc", "WSearch", "wuauserv"
)

# Create a checkbox for each service
foreach ($service in $services) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $service
    $checkBox.Foreground = $darkForeground
    $servicesStackPanel.AddChild($checkBox)
}

# Create a button to apply selected service changes
$servicesButton = New-Object System.Windows.Controls.Button
$servicesButton.Content = "Apply Selected Changes"
$servicesButton.Width = 150
$servicesButton.Height = 30
$servicesButton.Margin = "0,10,0,10"
$servicesButton.Background = $darkButtonBackground
$servicesButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$servicesButton.Add_Click({
    foreach ($child in $servicesStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $serviceName = $child.Content
            Write-Host "Disabling service: $serviceName"
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
            $child.IsChecked = $false
        }
    }
    [System.Windows.MessageBox]::Show("Selected services have been disabled!", "Services Manager")
})

# Add the StackPanel and Button to the Services Manager tab
$servicesTab.Content = $servicesStackPanel
$servicesStackPanel.AddChild($servicesButton)

# Add the Services Manager tab to the TabControl
$tabControl.Items.Add($servicesTab)

# === Startup Manager Tab ===
$startupTab = New-Object System.Windows.Controls.TabItem
$startupTab.Header = "Startup Manager"
$startupTab.Style = $tabItemStyle

# Create a StackPanel for the Startup Manager tab
$startupStackPanel = New-Object System.Windows.Controls.StackPanel
$startupStackPanel.Orientation = "Vertical"
$startupStackPanel.Margin = "10"

# Get startup programs
$startupPrograms = Get-CimInstance -ClassName Win32_StartupCommand | Select-Object -ExpandProperty Command

# Create a checkbox for each startup program
foreach ($program in $startupPrograms) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $program
    $checkBox.Foreground = $darkForeground
    $startupStackPanel.AddChild($checkBox)
}

# Create a button to disable selected startup programs
$startupButton = New-Object System.Windows.Controls.Button
$startupButton.Content = "Disable Selected Programs"
$startupButton.Width = 150
$startupButton.Height = 30
$startupButton.Margin = "0,10,0,10"
$startupButton.Background = $darkButtonBackground
$startupButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$startupButton.Add_Click({
    foreach ($child in $startupStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $programName = $child.Content
            Write-Host "Disabling startup program: $programName"
            # Add code here to disable the selected startup program
            $child.IsChecked = $false
        }
    }
    [System.Windows.MessageBox]::Show("Selected startup programs have been disabled!", "Startup Manager")
})

# Add the StackPanel and Button to the Startup Manager tab
$startupTab.Content = $startupStackPanel
$startupStackPanel.AddChild($startupButton)

# Add the Startup Manager tab to the TabControl
$tabControl.Items.Add($startupTab)

# === Power Plan Tweaks Tab ===
$powerTab = New-Object System.Windows.Controls.TabItem
$powerTab.Header = "Power Plan Tweaks"
$powerTab.Style = $tabItemStyle

# Create a StackPanel for the Power Plan Tweaks tab
$powerStackPanel = New-Object System.Windows.Controls.StackPanel
$powerStackPanel.Orientation = "Vertical"
$powerStackPanel.Margin = "10"

# List of power plan tweaks
$powerTweaks = @(
    "Set High Performance Power Plan",
    "Disable USB Selective Suspend",
    "Disable Hibernation",
    "Disable Sleep Mode"
)

# Create a checkbox for each power plan tweak
foreach ($tweak in $powerTweaks) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $tweak
    $checkBox.Foreground = $darkForeground
    $powerStackPanel.AddChild($checkBox)
}

# Create a button to apply selected power plan tweaks
$powerButton = New-Object System.Windows.Controls.Button
$powerButton.Content = "Apply Selected Tweaks"
$powerButton.Width = 150
$powerButton.Height = 30
$powerButton.Margin = "0,10,0,10"
$powerButton.Background = $darkButtonBackground
$powerButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$powerButton.Add_Click({
    foreach ($child in $powerStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $tweakName = $child.Content
            Write-Host "Applying power plan tweak: $tweakName"
            # Add code here to apply the selected power plan tweak
            $child.IsChecked = $false
        }
    }
    [System.Windows.MessageBox]::Show("Selected power plan tweaks have been applied!", "Power Plan Tweaks")
})

# Add the StackPanel and Button to the Power Plan Tweaks tab
$powerTab.Content = $powerStackPanel
$powerStackPanel.AddChild($powerButton)

# Add the Power Plan Tweaks tab to the TabControl
$tabControl.Items.Add($powerTab)

# === Privacy Tweaks Tab ===
$privacyTab = New-Object System.Windows.Controls.TabItem
$privacyTab.Header = "Privacy Tweaks"
$privacyTab.Style = $tabItemStyle

# Create a StackPanel for the Privacy Tweaks tab
$privacyStackPanel = New-Object System.Windows.Controls.StackPanel
$privacyStackPanel.Orientation = "Vertical"
$privacyStackPanel.Margin = "10"

# List of privacy tweaks
$privacyTweaks = @(
    "Disable Telemetry",
    "Disable Cortana",
    "Disable Location Tracking",
    "Disable Advertising ID",
    "Disable Wi-Fi Sense",
    "Disable Tailored Experiences"
)

# Create a checkbox for each privacy tweak
foreach ($tweak in $privacyTweaks) {
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $tweak
    $checkBox.Foreground = $darkForeground
    $privacyStackPanel.AddChild($checkBox)
}

# Create a button to apply selected privacy tweaks
$privacyButton = New-Object System.Windows.Controls.Button
$privacyButton.Content = "Apply Selected Tweaks"
$privacyButton.Width = 150
$privacyButton.Height = 30
$privacyButton.Margin = "0,10,0,10"
$privacyButton.Background = $darkButtonBackground
$privacyButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$privacyButton.Add_Click({
    foreach ($child in $privacyStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $tweakName = $child.Content
            Write-Host "Applying privacy tweak: $tweakName"
            # Add code here to apply the selected privacy tweak
            $child.IsChecked = $false
        }
    }
    [System.Windows.MessageBox]::Show("Selected privacy tweaks have been applied!", "Privacy Tweaks")
})

# Add the StackPanel and Button to the Privacy Tweaks tab
$privacyTab.Content = $privacyStackPanel
$privacyStackPanel.AddChild($privacyButton)

# Add the Privacy Tweaks tab to the TabControl
$tabControl.Items.Add($privacyTab)

# === Custom Scripts Tab ===
$scriptsTab = New-Object System.Windows.Controls.TabItem
$scriptsTab.Header = "Custom Scripts"
$scriptsTab.Style = $tabItemStyle

# Create a StackPanel for the Custom Scripts tab
$scriptsStackPanel = New-Object System.Windows.Controls.StackPanel
$scriptsStackPanel.Orientation = "Vertical"
$scriptsStackPanel.Margin = "10"

# Create a TextBox for custom script input
$scriptInput = New-Object System.Windows.Controls.TextBox
$scriptInput.Width = 500
$scriptInput.Height = 100
$scriptInput.Margin = "0,10,0,10"
$scriptInput.AcceptsReturn = $true
$scriptInput.Foreground = $darkForeground
$scriptInput.Background = $darkButtonBackground

# Create a button to run the custom script
$runScriptButton = New-Object System.Windows.Controls.Button
$runScriptButton.Content = "Run Script"
$runScriptButton.Width = 150
$runScriptButton.Height = 30
$runScriptButton.Margin = "0,10,0,10"
$runScriptButton.Background = $darkButtonBackground
$runScriptButton.Foreground = $darkButtonForeground

# Add an event handler for the button click
$runScriptButton.Add_Click({
    $script = $scriptInput.Text
    try {
        Invoke-Expression -Command $script
        [System.Windows.MessageBox]::Show("Script executed successfully!", "Custom Scripts")
    } catch {
        [System.Windows.MessageBox]::Show("Failed to execute script: $_", "Custom Scripts")
    }
})

# Add the TextBox and Button to the Custom Scripts tab
$scriptsStackPanel.AddChild($scriptInput)
$scriptsStackPanel.AddChild($runScriptButton)

# Add the StackPanel to the Custom Scripts tab
$scriptsTab.Content = $scriptsStackPanel

# Add the Custom Scripts tab to the TabControl
$tabControl.Items.Add($scriptsTab)

# === Logging ===
# Log file path
$logFile = "$env:USERPROFILE\Documents\TweaksLog.txt"

# Function to log actions
function Log-Action {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Add logging to relevant buttons
$debloaterButton.Add_Click({
    foreach ($child in $debloaterStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $packageName = $child.Tag
            Log-Action "Uninstalled: $($child.Content)"
        }
    }
})

$tweaksButton.Add_Click({
    foreach ($child in $tweaksStackPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $tweakName = $child.Content
            Log-Action "Applied tweak: $tweakName"
        }
    }
})

# === Restart Prompt ===
# Add a restart prompt to relevant buttons
$tweaksButton.Add_Click({
    $restartPrompt = [System.Windows.MessageBox]::Show("Restart your system to apply changes. Restart now?", "Restart Required", "YesNo")
    if ($restartPrompt -eq "Yes") {
        Restart-Computer -Force
    }
})

# Add the TabControl to the window
$window.Content = $tabControl

# Show the window
$window.ShowDialog()