<#
.SYNOPSIS
    CÔNG CỤ TRIỂN KHAI WINDOWS TỰ ĐỘNG - V13 (ANTI-BITLOCKER EDITION)
    Tối ưu hóa: Trệt tiêu BitLocker (Pre/Post/Offline), Custom Hostname, Bypass Win 11 Update
#>

# ==========================================
# 1. YÊU CẦU QUYỀN ADMIN & ÉP LUỒNG STA
# ==========================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ApartmentState STA -File $PSCommandPath ; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ==========================================
# 2. BIẾN ĐỒNG BỘ TOÀN CỤC
# ==========================================
$Global:TrangThaiHethong = [hashtable]::Synchronized(@{
    TienDo = 0; Log = ""; TrangThai = "Sẵn sàng"; DangChay = $false; KetThuc = $false; Loi = ""
})

# ==========================================
# 3. GIAO DIỆN WPF
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Zero-Touch OS Deployment V13 (Anti-BitLocker)" 
        Width="880" Height="780" MinWidth="800" MinHeight="650" 
        WindowStartupLocation="CenterScreen" Background="#F8FAFC">
    <DockPanel Margin="15">
        <TextBlock DockPanel.Dock="Top" Text="HỆ THỐNG TRIỂN KHAI WINDOWS CHUẨN CHỈ" FontSize="22" FontWeight="Bold" Foreground="#0F172A" HorizontalAlignment="Center" Margin="0,0,0,15"/>
        
        <StackPanel DockPanel.Dock="Bottom" Margin="0,15,0,0">
            <StackPanel Margin="0,0,0,10">
                <Grid Margin="0,0,0,5">
                    <TextBlock Name="TxtTrangThai" Text="Sẵn sàng" FontSize="12" Foreground="#1E293B" FontWeight="Bold"/>
                    <TextBlock Name="TxtPhanTram" Text="0%" FontWeight="Bold" FontSize="13" Foreground="#E11D48" HorizontalAlignment="Right"/>
                </Grid>
                <ProgressBar Name="ThanhTienDo" Height="14" Foreground="#10B981" Background="#E2E8F0" BorderThickness="0"/>
            </StackPanel>
            <Button Name="NutKichHoat" Content="🚀 KÍCH HOẠT QUY TRÌNH ZERO-TOUCH" Height="45" Background="#E11D48" Foreground="White" FontSize="16" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
        </StackPanel>

        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="6*"/><RowDefinition Height="Auto"/><RowDefinition Height="4*"/></Grid.RowDefinitions>
            
            <TabControl Grid.Row="0" Background="White" BorderBrush="#CBD5E1" Margin="0,0,0,8" Padding="10">
                <TabControl.Resources>
                    <Style TargetType="TabItem">
                        <Setter Property="Padding" Value="15,10"/>
                        <Setter Property="Margin" Value="0,0,5,0"/>
                        <Setter Property="Background" Value="#F1F5F9"/>
                        <Setter Property="BorderThickness" Value="1,1,1,0"/>
                        <Setter Property="BorderBrush" Value="#CBD5E1"/>
                        <Style.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="White"/>
                                <Setter Property="BorderBrush" Value="#0284C7"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </TabControl.Resources>

                <TabItem Header="📦 NGUỒN DỮ LIỆU" FontSize="14" FontWeight="Bold" Foreground="#0F172A">
                    <StackPanel Margin="10,15,10,10">
                        <TextBlock Text="Đường dẫn file ISO / WIM cài đặt:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,8"/>
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                            <TextBox Name="HopFileBoCai" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,8,0" FontSize="13"/>
                            <Button Name="NutChonFile" Grid.Column="1" Content="📂 Chọn File" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                        </Grid>
                        <TextBlock Text="Phiên bản Windows:" FontWeight="Bold" Foreground="#334155" Margin="0,10,0,8"/>
                        <ComboBox Name="DanhSachBanWin" Height="32" Margin="0,0,0,15" VerticalContentAlignment="Center" FontSize="13"/>
                        <Border BorderThickness="0,1,0,0" BorderBrush="#E2E8F0" Margin="0,10,0,20"/>
                        <TextBlock Text="Thư mục lưu/nạp Driver &amp; Wi-Fi:" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,8"/>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                            <TextBox Name="HopThuMucDriver" Height="32" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,8,0" FontSize="13"/>
                            <Button Name="NutChonDriver" Grid.Column="1" Content="🖨️ Chọn Driver" Background="#475569" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                        </Grid>
                    </StackPanel>
                </TabItem>

                <TabItem Header="⚙️ HỆ THỐNG" FontSize="14" FontWeight="Bold" Foreground="#0F172A">
                    <StackPanel Margin="10,15,10,10">
                        <TextBlock Text="Cấu hình Định danh &amp; Unattend.xml:" FontWeight="Bold" Foreground="#0284C7" Margin="0,0,0,10" FontSize="15"/>
                        <CheckBox Name="ChkGhiDeUnattend" Content="Can thiệp Hệ thống (Tạo User, Tên Máy, Region VN)" IsChecked="True" FontWeight="Bold" Foreground="#334155" Margin="0,0,0,10" FontSize="13"/>
                        <StackPanel Name="KhuVucRegion" Margin="25,0,0,15">
                            <Grid Margin="0,0,0,2">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="90"/>
                                    <ColumnDefinition Width="160"/>
                                    <ColumnDefinition Width="90"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="Tên User:" VerticalAlignment="Center" Foreground="#475569" FontWeight="Bold" FontSize="13"/>
                                <TextBox Name="TxtTenUser" Grid.Column="1" Height="30" VerticalContentAlignment="Center" Text="Admin" FontWeight="Bold" Padding="10,0"/>
                                <TextBlock Text="Tên Máy:" Grid.Column="2" VerticalAlignment="Center" Foreground="#475569" FontWeight="Bold" FontSize="13" Margin="15,0,0,0"/>
                                <TextBox Name="TxtTenMay" Grid.Column="3" Height="30" VerticalContentAlignment="Center" Text="PC-OFFICE" FontWeight="Bold" Padding="10,0"/>
                            </Grid>
                        </StackPanel>
                        <Border BorderThickness="0,1,0,0" BorderBrush="#E2E8F0" Margin="0,10,0,20"/>
                        <TextBlock Text="Các tùy chọn Kích hoạt ngầm:" FontWeight="Bold" Foreground="#0284C7" Margin="0,0,0,15" FontSize="15"/>
                        <UniformGrid Columns="2" VerticalAlignment="Top">
                            <CheckBox Name="ChkOOBE" Content="Tiêu diệt Màn hình xanh OOBE" IsChecked="True" FontWeight="Bold" Margin="0,0,0,12" FontSize="13"/>
                            <CheckBox Name="ChkLogon" Content="Auto Logon vào Desktop" IsChecked="True" FontWeight="Bold" Margin="0,0,0,12" FontSize="13"/>
                            <CheckBox Name="ChkBitlocker" Content="Diệt BitLocker (Trước &amp; Sau cài)" IsChecked="True" Foreground="#E11D48" FontWeight="Bold" Margin="0,0,0,12" FontSize="13"/>
                            <CheckBox Name="ChkTPM" Content="Bypass TPM 2.0 &amp; Auto Update" IsChecked="True" Foreground="#E11D48" FontWeight="Bold" Margin="0,0,0,12" FontSize="13"/>
                            <CheckBox Name="ChkBackupAll" Content="Rút Toàn bộ Driver máy" IsChecked="False" FontWeight="Bold" Margin="0,0,0,12" FontSize="13"/>
                            <CheckBox Name="ChkBackupNet" Content="Chỉ rút Driver LAN/Wi-Fi" IsChecked="True" Foreground="#D97706" FontWeight="Bold" Margin="0,0,0,12" FontSize="13"/>
                            <CheckBox Name="ChkUltraView" Content="Tải &amp; Bật UltraView (Hiện ngay)" IsChecked="True" Foreground="#0284C7" FontWeight="Bold" FontSize="13" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkWifi" Content="Lưu Pass &amp; Tên Wi-Fi" IsChecked="True" Foreground="#D97706" FontWeight="Bold" FontSize="13" Margin="0,0,0,12"/>
                        </UniformGrid>
                    </StackPanel>
                </TabItem>

                <TabItem Header="🚀 TỐI ƯU" FontSize="14" FontWeight="Bold" Foreground="#0F172A">
                    <StackPanel Margin="10,15,10,10">
                        <TextBlock Text="Lựa chọn các tinh chỉnh tự động cho Windows:" FontWeight="Bold" Foreground="#0284C7" Margin="0,0,0,15" FontSize="15"/>
                        <UniformGrid Columns="4" VerticalAlignment="Top">
                            <CheckBox Name="ChkBloatware" Content="Gỡ Bloatware" IsChecked="True" FontSize="12" FontWeight="Bold" Foreground="#D97706" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkNet35" Content="NET Framework 3.5" IsChecked="False" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkLegacy" Content="Legacy Components" IsChecked="False" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkSMB1" Content="SMB 1.0 / CIFS" IsChecked="False" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkNetShare" Content="Network &amp; Sharing" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkThisPC" Content="ThisPC Icon" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkSpotlight" Content="Spotlight - Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkOneDrive" Content="OneDrive - Remove" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkCopilot" Content="Copilot/Bing Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkMeetNow" Content="Meet Now - Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkSuggested" Content="Suggested - Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkDefender" Content="Defender - Remove" IsChecked="False" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkEdge" Content="Edge - FirstRun" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkVisual" Content="Best Visual Effects" IsChecked="False" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkWidgets" Content="Widgets - Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkNotif" Content="Notification Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkSticky" Content="Sticky Keys Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkNews" Content="News &amp; Int Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkTimezone" Content="Set TimeZone Auto" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkUAC" Content="UAC - Disable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkMenuClassic" Content="Classic Menu Win11" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkExt" Content="Show Extensions" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkNumLock" Content="NumLock - Enable" IsChecked="True" FontSize="12" Margin="0,0,0,12"/>
                            <CheckBox Name="ChkWmic" Content="WMIC Win11 Enable" IsChecked="False" FontSize="12" Margin="0,0,0,12"/>
                        </UniformGrid>
                    </StackPanel>
                </TabItem>
            </TabControl>

            <GridSplitter Grid.Row="1" Height="5" HorizontalAlignment="Stretch" VerticalAlignment="Center" Background="#CBD5E1" Cursor="SizeNS" Margin="0,2,0,5"/>
            <Border Grid.Row="2" Background="#0F172A" CornerRadius="8" Padding="8">
                <TextBox Name="HopNhatKy" Background="Transparent" Foreground="#38BDF8" FontFamily="Consolas" FontSize="13" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
            </Border>
        </Grid>
    </DockPanel>
</Window>
"@

$TrinhDoc = (New-Object System.Xml.XmlNodeReader $XAML); $UI = [Windows.Markup.XamlReader]::Load($TrinhDoc)

# Ánh xạ Biến Giao diện
$HopFileBoCai = $UI.FindName("HopFileBoCai"); $NutChonFile = $UI.FindName("NutChonFile"); $DanhSachBanWin = $UI.FindName("DanhSachBanWin")
$HopThuMucDriver = $UI.FindName("HopThuMucDriver"); $NutChonDriver = $UI.FindName("NutChonDriver")
$TxtTenUser = $UI.FindName("TxtTenUser"); $TxtTenMay = $UI.FindName("TxtTenMay")
$ChkGhiDeUnattend = $UI.FindName("ChkGhiDeUnattend"); $KhuVucRegion = $UI.FindName("KhuVucRegion")
$ChkOOBE = $UI.FindName("ChkOOBE"); $ChkLogon = $UI.FindName("ChkLogon"); $ChkTPM = $UI.FindName("ChkTPM")
$ChkBitlocker = $UI.FindName("ChkBitlocker"); $ChkUltraView = $UI.FindName("ChkUltraView"); $ChkWifi = $UI.FindName("ChkWifi")
$ChkBackupAll = $UI.FindName("ChkBackupAll"); $ChkBackupNet = $UI.FindName("ChkBackupNet")
$HopNhatKy = $UI.FindName("HopNhatKy"); $TxtTrangThai = $UI.FindName("TxtTrangThai"); $TxtPhanTram = $UI.FindName("TxtPhanTram")
$ThanhTienDo = $UI.FindName("ThanhTienDo"); $NutKichHoat = $UI.FindName("NutKichHoat")

# Ánh xạ Tweak
$ChkBloatware = $UI.FindName("ChkBloatware"); $ChkNet35 = $UI.FindName("ChkNet35"); $ChkLegacy = $UI.FindName("ChkLegacy"); $ChkSMB1 = $UI.FindName("ChkSMB1")
$ChkNetShare = $UI.FindName("ChkNetShare"); $ChkThisPC = $UI.FindName("ChkThisPC"); $ChkSpotlight = $UI.FindName("ChkSpotlight")
$ChkOneDrive = $UI.FindName("ChkOneDrive"); $ChkCopilot = $UI.FindName("ChkCopilot"); $ChkMeetNow = $UI.FindName("ChkMeetNow")
$ChkSuggested = $UI.FindName("ChkSuggested"); $ChkDefender = $UI.FindName("ChkDefender"); $ChkEdge = $UI.FindName("ChkEdge")
$ChkVisual = $UI.FindName("ChkVisual"); $ChkWidgets = $UI.FindName("ChkWidgets"); $ChkNotif = $UI.FindName("ChkNotif")
$ChkSticky = $UI.FindName("ChkSticky"); $ChkNews = $UI.FindName("ChkNews"); $ChkTimezone = $UI.FindName("ChkTimezone")
$ChkUAC = $UI.FindName("ChkUAC"); $ChkMenuClassic = $UI.FindName("ChkMenuClassic"); $ChkExt = $UI.FindName("ChkExt")
$ChkNumLock = $UI.FindName("ChkNumLock"); $ChkWmic = $UI.FindName("ChkWmic")

# Logic Checkbox
$ChkBackupAll.Add_Click({ if ($ChkBackupAll.IsChecked) { $ChkBackupNet.IsChecked = $false } })
$ChkBackupNet.Add_Click({ if ($ChkBackupNet.IsChecked) { $ChkBackupAll.IsChecked = $false } })
$ChkGhiDeUnattend.Add_Click({
    $TrangThai = $ChkGhiDeUnattend.IsChecked; $KhuVucRegion.IsEnabled = $TrangThai
    $ChkOOBE.IsEnabled = $TrangThai; $ChkLogon.IsEnabled = $TrangThai
})

# ==========================================
# 4. TIMER ĐỒNG BỘ
# ==========================================
$DongHoTimer = New-Object System.Windows.Threading.DispatcherTimer
$DongHoTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$DongHoTimer.Add_Tick({
    if ($Global:TrangThaiHethong.Log) { $HopNhatKy.AppendText($Global:TrangThaiHethong.Log); $HopNhatKy.ScrollToEnd(); $Global:TrangThaiHethong.Log = "" }
    $ThanhTienDo.Value = $Global:TrangThaiHethong.TienDo; $TxtPhanTram.Text = "$($Global:TrangThaiHethong.TienDo)%"; $TxtTrangThai.Text = $Global:TrangThaiHethong.TrangThai
    if ($Global:TrangThaiHethong.KetThuc) {
        $DongHoTimer.Stop()
        if ($Global:TrangThaiHethong.Loi) { 
            [System.Windows.Forms.MessageBox]::Show($Global:TrangThaiHethong.Loi, "LỖI HỆ THỐNG", 0, 16) 
        } else { 
            $HopNhatKy.AppendText("`n`n[$(Get-Date -f 'HH:mm:ss')] ✅ TOÀN BỘ QUY TRÌNH ĐÃ HOÀN TẤT! Máy sẽ khởi động lại sau 5 giây...") 
            Start-Process "cmd.exe" -ArgumentList "/c shutdown /r /t 5 /c `"He thong Zero-Touch da hoan tat. May se khoi dong lai vao WinRE...`"" -WindowStyle Hidden
        }
        $NutKichHoat.IsEnabled = $true; $UI.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

function Quet-ISO_WIM {
    $File = $HopFileBoCai.Text; if (-not (Test-Path $File)) { return }
    $DanhSachBanWin.Items.Clear(); $DanhSachBanWin.Items.Add("⏳ Đang quét danh sách phiên bản..."); $DanhSachBanWin.SelectedIndex = 0
    $UI.Cursor = [System.Windows.Input.Cursors]::Wait
    $FileWim = $File; $Mount = $false
    try {
        if ($File -match '(?i)\.iso$') {
            Mount-DiskImage -ImagePath $File -PassThru | Out-Null; Start-Sleep 1
            $KyTu = (Get-DiskImage -ImagePath $File | Get-Volume).DriveLetter[0]
            $FileWim = "$($KyTu):\sources\install.wim"; if (-not (Test-Path $FileWim)) { $FileWim = "$($KyTu):\sources\install.esd" }
            $Mount = $true
        }
        if (Test-Path $FileWim) {
            $ThongTin = dism.exe /Get-WimInfo /WimFile:$FileWim /English; $Idx = $null; $DanhSachBanWin.Items.Clear()
            foreach ($Dong in $ThongTin) {
                if ($Dong -match 'Index : (\d+)') { $Idx = $matches[1] }
                if ($Dong -match 'Name : (.*)' -and $Idx) { $DanhSachBanWin.Items.Add("Index $($Idx): $($matches[1])") | Out-Null; $Idx = $null }
            }
            $DanhSachBanWin.SelectedIndex = 0
        }
    } catch { } finally { if ($Mount) { Dismount-DiskImage -ImagePath $File | Out-Null }; $UI.Cursor = [System.Windows.Input.Cursors]::Arrow }
}

$NutChonFile.Add_Click({ $Hop = New-Object System.Windows.Forms.OpenFileDialog; if ($Hop.ShowDialog() -eq 'OK') { $HopFileBoCai.Text = $Hop.FileName; Quet-ISO_WIM } })
$NutChonDriver.Add_Click({ $F = New-Object System.Windows.Forms.FolderBrowserDialog; if ($F.ShowDialog() -eq 'OK') { $HopThuMucDriver.Text = $F.SelectedPath } })

# ==========================================
# 6. KỊCH BẢN NỀN (XỬ LÝ LÕI)
# ==========================================
$KichBanNen = {
    param($G, $FileCai, $FileDriver, $IndexLoi, $GhiDeUnattend, $TenUser, $TenMay, $OOBE, $Logon, $TPM, $UltraView, $AnyDesk, $Wifi, $BackupAll, $BackupNet, $Tweaks)
    
    function InLog($txt) { $G.Log += "`n[$(Get-Date -f 'HH:mm:ss')] $txt" }
    
    try {
        InLog "🚀 BẮT ĐẦU CHUỖI QUY TRÌNH ZERO-TOUCH VÀ OPTIMIZER..."

        # --- XỬ LÝ BITLOCKER (TRƯỚC KHI REBOOT VÀO WINRE) ---
        if ($Tweaks.BitLocker) {
            InLog "Đang xử lý vô hiệu hóa BitLocker toàn hệ thống..."
            foreach ($KyTu in 67..90) { 
                $Drive = [char]$KyTu + ":"
                if (Test-Path $Drive) {
                    cmd.exe /c "manage-bde -protectors -disable $Drive >nul 2>&1"
                    cmd.exe /c "manage-bde -off $Drive >nul 2>&1"
                }
            }
            InLog "✅ Đã mở khóa an toàn các phân vùng."
        }
        
        # --- BƯỚC 1: BACKUP DRIVER & NETWORK ---
        $MarkerName = "THUMUC_KHONG_TON_TAI.txt"; $ThuMucDriverTuongDoi = ""

        if ($FileDriver) {
            $MarkerName = "ZT_Driver_$([guid]::NewGuid().ToString('N')).txt"
            Out-File -FilePath "$FileDriver\$MarkerName" -InputObject "Day la thu muc Driver ZT" -Encoding ascii
            $ThuMucDriverTuongDoi = if ($FileDriver.Length -gt 3) { $FileDriver.Substring(3) } else { "" }

            if ($BackupAll) { 
                $G.TrangThai = "BƯỚC 1/6: Đang trích xuất ALL Driver..."; $G.TienDo = 5
                InLog "Đang quét và trích xuất TOÀN BỘ Driver máy hiện tại..."
                Export-WindowsDriver -Online -Destination $FileDriver | Out-Null 
                InLog "✅ Đã lưu Toàn bộ Driver."
            } elseif ($BackupNet) {
                $G.TrangThai = "BƯỚC 1/6: Đang trích xuất Driver LAN/Wi-Fi..."; $G.TienDo = 5
                InLog "Đang quét và CHỈ sao lưu Driver LAN & Wi-Fi..."
                $NetDrivers = Get-WindowsDriver -Online | Where-Object { $_.ClassName -eq 'Net' }
                if ($NetDrivers) {
                    foreach ($drv in $NetDrivers) { pnputil.exe /export-driver $($drv.Driver) "$FileDriver" | Out-Null }
                    InLog "✅ Đã trích xuất Driver Mạng."
                } else { InLog "⚠️ Không tìm thấy Driver Mạng bên ngoài nào." }
            }

            if ($Wifi) { 
                InLog "Đang sao lưu Mật khẩu và Tên Wi-Fi đã truy cập..."
                Invoke-Expression "netsh wlan export profile key=clear folder=`"$FileDriver`"" | Out-Null 
                $LogWifi = "$FileDriver\DanhSach_Ten_WiFi_Da_TruyCap.txt"
                "=================================================" | Out-File $LogWifi -Encoding utf8
                "        DANH SÁCH TÊN WI-FI ĐÃ TỪNG KẾT NỐI      " | Out-File $LogWifi -Append -Encoding utf8
                "=================================================" | Out-File $LogWifi -Append -Encoding utf8
                netsh wlan show profile | Out-File $LogWifi -Append -Encoding utf8
                InLog "✅ Đã xuất Tên & Mật khẩu Wi-Fi."
            }
        }

        # --- BƯỚC 2: XỬ LÝ ISO ---
        if ($FileCai -match '(?i)\.iso$') {
            $G.TrangThai = "BƯỚC 2/6: Đang xả nén bộ cài từ ISO..."
            Mount-DiskImage -ImagePath $FileCai -PassThru | Out-Null; Start-Sleep 1
            $KyTuIso = (Get-DiskImage -ImagePath $FileCai | Get-Volume).DriveLetter[0]
            $Wim = "$($KyTuIso):\sources\install.wim"; $Esd = "$($KyTuIso):\sources\install.esd"
            $FileTrich = if (Test-Path $Wim) { $Wim } else { $Esd }
            $FileCaiDich = Join-Path ([System.IO.Path]::GetDirectoryName($FileCai)) ("install_extracted" + [System.IO.Path]::GetExtension($FileTrich))
            
            if (-not (Test-Path $FileCaiDich)) {
                $In = [System.IO.File]::OpenRead($FileTrich); $Out = [System.IO.File]::Create($FileCaiDich)
                $Buf = New-Object byte[] (8MB); $Len = $In.Length; $Done = 0
                while (($Read = $In.Read($Buf, 0, $Buf.Length)) -gt 0) { 
                    $Out.Write($Buf, 0, $Read); $Done += $Read
                    $G.TienDo = 5 + [math]::Round(($Done / $Len) * 30) 
                }
                $In.Close(); $Out.Close()
            } 
            Dismount-DiskImage -ImagePath $FileCai | Out-Null; $FileCai = $FileCaiDich
        }

        $G.TienDo = 40; $G.TrangThai = "BƯỚC 3/6: Kiến tạo XML & Tweak Nền..."
        $DuongDanTuongDoiWin = if ($FileCai.Length -gt 3) { $FileCai.Substring(3) } else { "" }

        # --- BƯỚC 3: TẠO UNATTEND.XML CHUẨN UTF-8 (CÓ TÊN MÁY TÍNH) ---
        if ($GhiDeUnattend) {
            if ($OOBE) {
                $KhốiUser = ""; $KhốiLogonXML = ""
                if ($Logon) {
                    $KhốiUser = @"
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password><Value></Value><PlainText>true</PlainText></Password>
                        <Description>Local Administrator</Description>
                        <DisplayName>$TenUser</DisplayName>
                        <Group>Administrators</Group>
                        <Name>$TenUser</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
"@
                    $KhốiLogonXML = @"
            <AutoLogon>
                <Password><Value></Value><PlainText>true</PlainText></Password>
                <Enabled>true</Enabled>
                <LogonCount>9999</LogonCount>
                <Username>$TenUser</Username>
            </AutoLogon>
"@
                }

                $TenMayBlock = if (-not [string]::IsNullOrWhiteSpace($TenMay)) { "<ComputerName>$TenMay</ComputerName>" } else { "" }

                $UnattendXML = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            $TenMayBlock
            <TimeZone>SE Asia Standard Time</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>en-US</InputLocale><SystemLocale>en-US</SystemLocale><UILanguage>en-US</UILanguage><UserLocale>vi-VN</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
$KhốiUser$KhốiLogonXML
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add"><Order>1</Order><CommandLine>cmd.exe /c C:\Windows\Setup\Scripts\PostInstall_ZT.cmd</CommandLine></SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
"@
                [System.IO.File]::WriteAllText("$env:TEMP\unattend_ZT.xml", $UnattendXML, [System.Text.Encoding]::UTF8)
            }
        }

        # --- BƯỚC 4: TẠO SCRIPT POST-INSTALL & TWEAKS ---
        $G.TrangThai = "BƯỚC 4/6: Đóng gói Script Hệ thống..."; $G.TienDo = 50
        $Cmd = "@echo off`r`n"
        
        # Xử lý BitLocker Post-Install
        if ($Tweaks.BitLocker) {
            $Cmd += "for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do manage-bde -off %%d: >nul 2>&1`r`n"
        } else {
            $Cmd += "manage-bde -off C: >nul 2>&1`r`n"
        }
        
        InLog "Biên dịch 24 tùy chọn Windows Optimizer..."
        if ($Tweaks.UAC) { $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1`r`n" }
        if ($Tweaks.Defender) { 
            $Cmd += "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender`" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1`r`n"
            $Cmd += "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection`" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1`r`n"
        }
        if ($Tweaks.OneDrive) { $Cmd += "taskkill /f /im OneDrive.exe >nul 2>&1 & %SystemRoot%\SysWOW64\OneDriveSetup.exe /uninstall >nul 2>&1`r`n" }
        if ($Tweaks.Copilot) { $Cmd += "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`" /v `"TurnOffWindowsCopilot`" /t REG_DWORD /d 1 /f >nul 2>&1`r`n" }
        if ($Tweaks.MeetNow) { $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" /v `"HideSCAMeetNow`" /t REG_DWORD /d 1 /f >nul 2>&1`r`n" }
        if ($Tweaks.Suggested) { $Cmd += "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer`" /v `"HideRecommendedSection`" /t REG_DWORD /d 1 /f >nul 2>&1`r`n" }
        if ($Tweaks.Edge) { $Cmd += "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Edge`" /v `"HideFirstRunExperience`" /t REG_DWORD /d 1 /f >nul 2>&1`r`n" }
        if ($Tweaks.Widgets) { $Cmd += "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Dsh`" /v `"AllowNewsAndInterests`" /t REG_DWORD /d 0 /f >nul 2>&1`r`n" }
        if ($Tweaks.News) { $Cmd += "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds`" /v `"EnableFeeds`" /t REG_DWORD /d 0 /f >nul 2>&1`r`n" }
        if ($Tweaks.Timezone) { $Cmd += "sc config tzautoupdate start= auto >nul 2>&1 & net start tzautoupdate >nul 2>&1`r`n" }
        if ($Tweaks.NetShare) {
            $Cmd += "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes >nul 2>&1`r`n"
            $Cmd += "netsh advfirewall firewall set rule group=`"Network Discovery`" new enable=Yes >nul 2>&1`r`n"
        }
        if ($Tweaks.Sticky) { $Cmd += "reg add `"HKU\.DEFAULT\Control Panel\Accessibility\StickyKeys`" /v `"Flags`" /t REG_SZ /d `"506`" /f >nul 2>&1`r`n" }
        if ($Tweaks.NumLock) { $Cmd += "reg add `"HKU\.DEFAULT\Control Panel\Keyboard`" /v `"InitialKeyboardIndicators`" /t REG_SZ /d `"2`" /f >nul 2>&1`r`n" }
        if ($Tweaks.Net35) { $Cmd += "dism /online /enable-feature /featurename:NetFx3 /All /NoRestart >nul 2>&1`r`n" }
        if ($Tweaks.Legacy) { $Cmd += "dism /online /enable-feature /featurename:DirectPlay /All /NoRestart >nul 2>&1`r`n" }
        if ($Tweaks.SMB1) { $Cmd += "dism /online /enable-feature /featurename:SMB1Protocol /All /NoRestart >nul 2>&1`r`n" }
        if ($Tweaks.Wmic) { $Cmd += "dism /online /add-capability /CapabilityName:WMIC~~~~ /NoRestart >nul 2>&1`r`n" }

        $UsrCmd = "@echo off`r`n"
        if ($Tweaks.ThisPC) { $UsrCmd += "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel`" /v `"{20D04FE0-3AEA-1069-A2D8-08002B30309D}`" /t REG_DWORD /d 0 /f >nul 2>&1`r`n" }
        if ($Tweaks.Spotlight) { $UsrCmd += "reg add `"HKCU\Software\Policies\Microsoft\Windows\CloudContent`" /v `"DisableWindowsSpotlightFeatures`" /t REG_DWORD /d 1 /f >nul 2>&1`r`n" }
        if ($Tweaks.Visual) { $UsrCmd += "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects`" /v `"VisualFXSetting`" /t REG_DWORD /d 2 /f >nul 2>&1`r`n" }
        if ($Tweaks.Notif) { $UsrCmd += "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications`" /v `"ToastEnabled`" /t REG_DWORD /d 0 /f >nul 2>&1`r`n" }
        if ($Tweaks.MenuClassic) { $UsrCmd += "reg add `"HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32`" /ve /t REG_SZ /d `"`" /f >nul 2>&1`r`n" }
        if ($Tweaks.Ext) { $UsrCmd += "reg add `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" /v `"HideFileExt`" /t REG_DWORD /d 0 /f >nul 2>&1`r`n" }
        
        $UsrCmd += "taskkill /f /im explorer.exe & start explorer.exe`r`n"
        $UsrCmd += "del %0`r`n"
        $UsrCmd | Out-File "$env:TEMP\UserTweaks_ZT.cmd" -Encoding oem
        $Cmd += "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"ZT_Tweaks`" /t REG_SZ /d `"cmd.exe /c C:\Windows\Setup\Scripts\UserTweaks_ZT.cmd`" /f >nul 2>&1`r`n"

        if ($Tweaks.Bloatware) {
            $BloatPS1 = @"
`$KeepApps = 'calculator|camera|photos|zunevideo|soundrecorder|stickynotes|screensketch|snippingtool|store|appinstaller|sechealth|vclibs|xaml|net.native|edge|heif|webp|vp9'
Get-AppxProvisionedPackage -Online | Where-Object { `$_.DisplayName -notmatch `$KeepApps } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
Get-AppxPackage -AllUsers | Where-Object { `$_.Name -notmatch '^System|^Microsoft\.Windows\.' -and `$_.Name -notmatch `$KeepApps } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
"@
            $BloatPS1 | Out-File "$env:TEMP\RemoveBloat_ZT.ps1" -Encoding utf8
            $Cmd += "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"C:\Windows\Setup\Scripts\RemoveBloat_ZT.ps1`" >nul 2>&1`r`n"
        }

        if ($Wifi) { $Cmd += "for %%f in (`"%~dp0*.xml`") do netsh wlan add profile filename=`"%%f`" user=all >nul 2>&1`r`n" }
        
        $CanDoiMang = $UltraView -or $AnyDesk
        if ($CanDoiMang) {
            $Cmd += "echo Dang doi Internet...`r`nping 127.0.0.1 -n 15 >nul`r`n"
        }

        if ($UltraView) {
            $Cmd += "powershell -Command `"[Net.ServicePointManager]::SecurityProtocol = 3072; Invoke-WebRequest -Uri 'https://dl2.ultraviewer.net/UltraViewer_setup_6.6_vi.exe' -OutFile 'C:\UltraView_Setup.exe'`"`r`n"
            $Cmd += "start /wait C:\UltraView_Setup.exe /verysilent /norestart`r`n"
            $Cmd += "start `"`" `"C:\Program Files (x86)\UltraViewer\UltraViewer_Desktop.exe`"`r`n"
            $Cmd += "del /f /q C:\UltraView_Setup.exe`r`n"
        }

        if ($AnyDesk) { 
            $Cmd += "powershell -Command `"[Net.ServicePointManager]::SecurityProtocol = 3072; Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile 'C:\Users\Public\Desktop\AnyDesk.exe'`" >nul 2>&1`r`n"
            $Cmd += "start `"`" `"C:\Users\Public\Desktop\AnyDesk.exe`"`r`n" 
        }

        $Cmd += "del %0`r`n"
        $Cmd | Out-File "$env:TEMP\PostInstall_ZT.cmd" -Encoding oem

        # --- BƯỚC 5: XỬ LÝ WINRE ---
        $G.TrangThai = "BƯỚC 5/6: Chuẩn bị WinRE..."; $G.TienDo = 60
        $ChuCaiO_Win = [System.IO.Path]::GetPathRoot($env:windir).Substring(0,1)
        $PhanVungOS = Get-Partition -DriveLetter $ChuCaiO_Win
        $OsDiskNum = $PhanVungOS.DiskNumber; $OsPartNum = $PhanVungOS.PartitionNumber
        
        $WinREGoc = "C:\Windows\System32\Recovery\winre.wim"; $ThuMucMnt = "C:\MountRE"
        reagentc.exe /enable | Out-Null; Start-Sleep 2; reagentc.exe /disable | Out-Null; Start-Sleep 2
        
        if (-not (Test-Path $WinREGoc)) { throw "KHÔNG TÌM THẤY LÕI WINRE!" }

        if (Test-Path $ThuMucMnt) { dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Discard | Out-Null; Remove-Item $ThuMucMnt -Recurse -Force }
        New-Item -ItemType Directory -Path $ThuMucMnt | Out-Null
        $WinRECopy = "C:\winre_xu-ly.wim"; Copy-Item $WinREGoc $WinRECopy -Force; Set-ItemProperty $WinRECopy IsReadOnly $false
        
        dism.exe /Mount-Image /ImageFile:$WinRECopy /Index:1 /MountDir:$ThuMucMnt | Out-Null
        Copy-Item "$env:TEMP\PostInstall_ZT.cmd" "$ThuMucMnt\Windows\System32\PostInstall_ZT.cmd" -Force
        Copy-Item "$env:TEMP\UserTweaks_ZT.cmd" "$ThuMucMnt\Windows\System32\UserTweaks_ZT.cmd" -Force
        
        if ($Tweaks.Bloatware) { Copy-Item "$env:TEMP\RemoveBloat_ZT.ps1" "$ThuMucMnt\Windows\System32\RemoveBloat_ZT.ps1" -Force }
        if ($GhiDeUnattend -and (Test-Path "$env:TEMP\unattend_ZT.xml")) { Copy-Item "$env:TEMP\unattend_ZT.xml" "$ThuMucMnt\Windows\System32\unattend_ZT.xml" -Force }
        
        # --- BƯỚC 6: LỆNH CHẠY TRONG WINRE (OFFLINE REGISTRY INJECTION) ---
        $G.TrangThai = "BƯỚC 6/6: Ghi kịch bản tự động hóa..."; $G.TienDo = 80
        $CheckDriverPath = if ($ThuMucDriverTuongDoi) { "%%D:\$ThuMucDriverTuongDoi\$MarkerName" } else { "%%D:\$MarkerName" }
        $DriverInjectPath = if ($ThuMucDriverTuongDoi) { "%DRIVER_DRIVE%:\$ThuMucDriverTuongDoi\." } else { "%DRIVER_DRIVE%:\." }
        $XmlCopyPath = if ($ThuMucDriverTuongDoi) { "%DRIVER_DRIVE%:\$ThuMucDriverTuongDoi\*.xml" } else { "%DRIVER_DRIVE%:\*.xml" }

        $BypassRegistryCmd = ""
        if ($OOBE -and $Logon) {
            $BypassRegistryCmd += @"
:: TIÊM REGISTRY NGOẠI TUYẾN ĐỂ BYPASS TÀI KHOẢN MICROSOFT VÀ ÉP AUTO LOGON
reg load HKLM\ZT_SOFT W:\Windows\System32\config\SOFTWARE
reg add "HKLM\ZT_SOFT\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f
reg add "HKLM\ZT_SOFT\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\ZT_SOFT\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "$TenUser" /f
reg unload HKLM\ZT_SOFT
"@
        }

        $SysRegCmd = ""
        if ($TPM) {
            $SysRegCmd += @"
reg add "HKLM\ZT_SYS\Setup\MoSetup" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f
reg add "HKLM\ZT_SYS\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f
reg add "HKLM\ZT_SYS\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f
reg add "HKLM\ZT_SYS\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f
reg add "HKLM\ZT_SYS\Setup\LabConfig" /v BypassStorageCheck /t REG_DWORD /d 1 /f
"@
        }
        if ($Tweaks.BitLocker) {
            $SysRegCmd += @"
reg add "HKLM\ZT_SYS\ControlSet001\Control\BitLocker" /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
"@
        }

        if ($SysRegCmd) {
            $BypassRegistryCmd += "`nreg load HKLM\ZT_SYS W:\Windows\System32\config\SYSTEM`n" + $SysRegCmd.Trim() + "`nreg unload HKLM\ZT_SYS`n"
        }

        @"
@echo off
set "WIM="; set "DRIVER_DRIVE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( 
    if exist "%%D:\$DuongDanTuongDoiWin" set "WIM=%%D:\$DuongDanTuongDoiWin"
    if not "$MarkerName"=="THUMUC_KHONG_TON_TAI.txt" ( if exist "$CheckDriverPath" set "DRIVER_DRIVE=%%D" )
)

(echo select disk $OsDiskNum & echo select partition $OsPartNum & echo assign letter=W & echo format quick fs=ntfs label="Windows") | diskpart
dism /apply-image /imagefile:"%WIM%" /index:$IndexLoi /applydir:W:\
mkdir W:\Windows\Setup\Scripts
mkdir W:\Windows\Panther

if not "%DRIVER_DRIVE%"=="" (
    dism /image:W:\ /add-driver /driver:"$DriverInjectPath" /recurse
    copy /Y "$XmlCopyPath" W:\Windows\Setup\Scripts\
)
for %%p in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( if exist %%p:\EFI\Microsoft\Boot\BCD ( attrib -h -s -r %%p:\EFI\Microsoft\Boot\BCD & del /f /q %%p:\EFI\Microsoft\Boot\BCD ) )
bcdboot W:\Windows

bcdedit /timeout 0; bcdedit /set {default} recoveryenabled No; bcdedit /set {default} bootstatuspolicy IgnoreAllFailures

:: Chép Scripts
copy /Y X:\Windows\System32\PostInstall_ZT.cmd W:\Windows\Setup\Scripts\PostInstall_ZT.cmd
copy /Y X:\Windows\System32\UserTweaks_ZT.cmd W:\Windows\Setup\Scripts\UserTweaks_ZT.cmd
if exist X:\Windows\System32\RemoveBloat_ZT.ps1 ( copy /Y X:\Windows\System32\RemoveBloat_ZT.ps1 W:\Windows\Setup\Scripts\RemoveBloat_ZT.ps1 )

:: Xử lý Unattend
if exist X:\Windows\System32\unattend_ZT.xml ( 
    copy /Y X:\Windows\System32\unattend_ZT.xml W:\Windows\Panther\unattend.xml
    copy /Y X:\Windows\System32\unattend_ZT.xml W:\unattend.xml
)
echo call C:\Windows\Setup\Scripts\PostInstall_ZT.cmd >> W:\Windows\Setup\Scripts\SetupComplete.cmd

$BypassRegistryCmd

del /F /Q X:\Windows\System32\winpeshl.ini
wpeutil reboot
"@ | Out-File "$ThuMucMnt\Windows\System32\LenhRE.cmd" -Encoding oem
        "[LaunchApps]`r`nX:\Windows\System32\LenhRE.cmd" | Out-File "$ThuMucMnt\Windows\System32\winpeshl.ini" -Encoding ascii
        
        $G.TrangThai = "Đang đóng gói WinRE..."; $G.TienDo = 90
        dism.exe /Unmount-Image /MountDir:$ThuMucMnt /Commit | Out-Null
        Start-Sleep 2
        cmd.exe /c "attrib -h -s -r `"$WinREGoc`"" | Out-Null
        Copy-Item $WinRECopy $WinREGoc -Force; Remove-Item $WinRECopy -Force -ErrorAction SilentlyContinue
        reagentc.exe /setreimage /path C:\Windows\System32\Recovery | Out-Null; reagentc.exe /enable | Out-Null; reagentc.exe /boottore | Out-Null
        $G.TienDo = 100
    } catch { $G.Loi = $_.Exception.Message } finally { 
        Remove-Item "$env:TEMP\unattend_ZT.xml", "$env:TEMP\PostInstall_ZT.cmd", "$env:TEMP\UserTweaks_ZT.cmd", "$env:TEMP\RemoveBloat_ZT.ps1" -Force -ErrorAction SilentlyContinue
        $G.KetThuc = $true 
    }
}

$NutKichHoat.Add_Click({
    $FileCai = $HopFileBoCai.Text; $FileDriver = $HopThuMucDriver.Text; $ChonIndex = $DanhSachBanWin.SelectedItem
    if (-not (Test-Path $FileCai)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn bộ cài!", "LỖI", 0, 16); return }
    if ($ChonIndex -match 'Index (\d+):') { $IndexLoi = $matches[1] } else { $IndexLoi = 1 }
    if ( ($ChkBackupAll.IsChecked -or $ChkBackupNet.IsChecked -or $ChkWifi.IsChecked) -and -not $FileDriver ) { [System.Windows.Forms.MessageBox]::Show("Để Backup Driver/Wi-Fi, vui lòng 'Chọn Driver'.", "LỖI", 0, 16); return }
    if ([System.Windows.Forms.MessageBox]::Show("HỆ THỐNG SẼ FORMAT Ổ C.`nTiếp tục?", "CẢNH BÁO", 4, 48) -ne 'Yes') { return }

    $UI.Cursor = [System.Windows.Input.Cursors]::Wait; $NutKichHoat.IsEnabled = $false
    $Global:TrangThaiHethong.TienDo = 0; $Global:TrangThaiHethong.Log = ""; $Global:TrangThaiHethong.KetThuc = $false; $DongHoTimer.Start()

    $Tweaks = @{
        Bloatware = $ChkBloatware.IsChecked; Net35 = $ChkNet35.IsChecked; Legacy = $ChkLegacy.IsChecked; SMB1 = $ChkSMB1.IsChecked;
        NetShare = $ChkNetShare.IsChecked; ThisPC = $ChkThisPC.IsChecked; Spotlight = $ChkSpotlight.IsChecked;
        OneDrive = $ChkOneDrive.IsChecked; Copilot = $ChkCopilot.IsChecked; MeetNow = $ChkMeetNow.IsChecked;
        Suggested = $ChkSuggested.IsChecked; Defender = $ChkDefender.IsChecked; Edge = $ChkEdge.IsChecked;
        Visual = $ChkVisual.IsChecked; Widgets = $ChkWidgets.IsChecked; Notif = $ChkNotif.IsChecked;
        Sticky = $ChkSticky.IsChecked; News = $ChkNews.IsChecked; Timezone = $ChkTimezone.IsChecked;
        UAC = $ChkUAC.IsChecked; MenuClassic = $ChkMenuClassic.IsChecked; Ext = $ChkExt.IsChecked;
        NumLock = $ChkNumLock.IsChecked; Wmic = $ChkWmic.IsChecked; BitLocker = $ChkBitlocker.IsChecked
    }

    $MoiTruong = [runspacefactory]::CreateRunspace(); $MoiTruong.ApartmentState = "STA"; $MoiTruong.Open()
    $TienTrinh = [powershell]::Create().AddScript($KichBanNen).AddArgument($Global:TrangThaiHethong).AddArgument($FileCai).AddArgument($FileDriver).AddArgument($IndexLoi).AddArgument($ChkGhiDeUnattend.IsChecked).AddArgument($TxtTenUser.Text).AddArgument($TxtTenMay.Text).AddArgument($ChkOOBE.IsChecked).AddArgument($ChkLogon.IsChecked).AddArgument($ChkTPM.IsChecked).AddArgument($ChkUltraView.IsChecked).AddArgument($ChkAnyDesk.IsChecked).AddArgument($ChkWifi.IsChecked).AddArgument($ChkBackupAll.IsChecked).AddArgument($ChkBackupNet.IsChecked).AddArgument($Tweaks)
    $TienTrinh.Runspace = $MoiTruong; $TienTrinh.BeginInvoke() | Out-Null
})

$UI.ShowDialog() | Out-Null