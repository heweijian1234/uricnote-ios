Add-Type -AssemblyName System.Drawing
# UricNote 截图生成 · 2026-11-15 · 青绿视觉系统（4.3 防火墙③：兄弟 App 截图不复用——本脚本从 grindsnore 母版重写配色+文案+布局）
$W = 1290; $H = 2796
$OUT = 'E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\store'

function New-Teal($w, $h, $c1, $c2, $c3, $c4) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb($c1,$c2,$c3), [System.Drawing.Color]::FromArgb($c2,$c3,$c4), 60)
    $g.FillRectangle($bg, $rect)
    return @($bmp, $g)
}
function Card($g, $x, $y, $w, $h, $alpha = 40) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = 36
    $path.AddArc($x, $y, $r, $r, 180, 90); $path.AddArc($x+$w-$r, $y, $r, $r, 270, 90)
    $path.AddArc($x+$w-$r, $y+$h-$r, $r, $r, 0, 90); $path.AddArc($x, $y+$h-$r, $r, $r, 90, 90)
    $path.CloseFigure()
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 255, 255))
    $g.FillPath($brush, $path)
}
function Txt($g, $t, $x, $y, $size, $bold, $r, $gr, $b) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = New-Object System.Drawing.Font('Segoe UI', $size, $style)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($r, $gr, $b))
    $g.DrawString($t, $font, $brush, $x, $y)
}
function CenterTxt($g, $t, $y, $size, $bold, $r, $gr, $b) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = New-Object System.Drawing.Font('Segoe UI', $size, $style)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($r, $gr, $b))
    $m = $g.MeasureString($t, $font)
    $x = ([single]($script:W) - $m.Width) / 2
    $g.DrawString($t, $font, $brush, $x, $y)
}

# ===== shot1：仪表盘（三数字+已控制徽章） =====
$c = New-Teal $W $H 10 92 78 6 60; $bmp = $c[0]; $g = $c[1]
CenterTxt $g 'UricNote' 150 72 $true 255 255 255
CenterTxt $g 'Gout & uric acid — under control' 260 40 $false 170 230 210
# 三数字卡
Card $g 100 420 ($W-200) 300
Txt $g 'FLARE-FREE' 180 470 36 $true 170 230 210
Txt $g '47 days' 180 540 64 $true 255 255 255
Txt $g 'Crystals are quietly dissolving' 180 630 30 $false 200 220 215
Card $g 100 780 ($W-200) 260
Txt $g 'TO TARGET' 180 820 36 $true 170 230 210
Txt $g '5.2 mg/dL  ✓' 180 890 60 $true 120 240 180
Txt $g 'Goal: below 6.0' 180 970 30 $false 200 220 215
# 已控制徽章
Card $g 100 1120 ($W-200) 220 60
CenterTxt $g '✓ WELL CONTROLLED' 1180 48 $true 120 240 180
CenterTxt $g 'Gout no longer runs your life' 1280 32 $false 220 240 232
# 复查节律
Card $g 100 1420 ($W-200) 220
Txt $g 'NEXT REVIEW' 180 1470 36 $true 170 230 210
Txt $g 'in 12 days' 180 1540 56 $true 255 255 255
Txt $g 'The rhythm validated in clinical trials' 180 1630 30 $false 200 220 215
CenterTxt $g 'Free to track · One-time unlock for doctor reports' 1750 38 $true 170 230 210
CenterTxt $g 'No subscription · No ads · Data stays on your phone' 1840 32 $false 190 215 205
$bmp.Save("$OUT\shot1.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ===== shot2：发作 3 秒记录（深色夜间场景——夜间发作 2.4 倍场景） =====
$c = New-Teal $W $H 8 40 36 4 26; $bmp = $c[0]; $g = $c[1]
CenterTxt $g 'Flare at 3am?' 170 68 $true 255 255 255
CenterTxt $g 'Record it in 3 seconds — half asleep' 270 38 $false 170 220 205
Card $g 100 420 ($W-200) 320
Txt $g 'WHICH JOINT?' 180 470 34 $true 170 230 210
$jointChips = @('Big toe', 'Ankle', 'Heel', 'Knee', 'Finger', 'Wrist')
$cx = 180; $cy = 540
foreach ($j in $jointChips) {
    $f = $g.MeasureString($j, (New-Object System.Drawing.Font('Segoe UI', 32, [System.Drawing.FontStyle]::Bold)))
    $bw = [int]($f.Width + 50)
    Card $g $cx $cy $bw 90 70
    Txt $g $j ($cx+25) ($cy+18) 32 $true 235 245 240
    $cx += $bw + 24
    if ($cx -gt 900) { $cx = 180; $cy += 110 }
}
Card $g 100 800 ($W-200) 200
Txt $g 'PAIN' 180 845 34 $true 170 230 210
Txt $g '8 / 10' 180 910 56 $true 255 255 255
Card $g 100 1060 ($W-200) 160
Txt $g 'CAN YOU WALK?' 180 1100 34 $true 170 230 210
Txt $g 'Barely' 180 1160 48 $true 255 165 140
# 安抚文案（发作后的语气）
CenterTxt $g 'Noted. Rest tonight — this app remembers' 1350 40 $true 170 230 210
CenterTxt $g 'so you do not have to.' 1420 36 $false 190 215 205
CenterTxt $g 'Your trigger ranking grows with every flare' 1560 36 $true 170 230 210
CenterTxt $g 'Explainable rules — never a black-box score' 1640 32 $false 190 215 205
$bmp.Save("$OUT\shot2.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ===== shot3：绿灯食物库（健哥令：先看能吃的） =====
$c = New-Teal $W $H 10 92 78 8 70; $bmp = $c[0]; $g = $c[1]
CenterTxt $g 'What you CAN eat' 160 68 $true 255 255 255
CenterTxt $g '103 green-light foods — hope first, limits second' 260 36 $false 170 230 210
# 三段Tab（垂直错开排列，避免重叠）
Card $g 100 400 1060 110 80
Card $g 110 410 340 90 90
Txt $g '✓ Can eat' 150 432 34 $true 120 240 180
Txt $g 'Moderate' 520 432 34 $false 220 230 228
Txt $g 'Careful' 890 432 34 $false 220 230 228
# 绿灯食物网格
$foods = @('Cherries', 'Eggs', 'Skim milk', 'Oats', 'Corn', 'Tofu (firm)', 'Apples', 'Bananas', 'Water', 'Broccoli', 'Potatoes', 'Green tea')
$fx = 100; $fy = 560
$i = 0
foreach ($food in $foods) {
    Card $g $fx $fy 350 120 55
    Txt $g $food ($fx+30) ($fy+35) 30 $true 240 250 246
    Txt $g 'green' ($fx+30) ($fy+80) 22 $false 120 240 180
    $fx += 370
    if ($fx -gt 900) { $fx = 100; $fy += 140 }
}
CenterTxt $g 'Source: ACR 2020 Guideline — with version logs' 1420 36 $true 170 230 210
CenterTxt $g 'Your trigger ranking after 30 days of easy logging' 1510 34 $false 200 225 218
CenterTxt $g 'Doctor report: one page, 15-minute visit ready' 1650 36 $true 170 230 210
$bmp.Save("$OUT\shot3.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

Write-Output 'DONE 3 shots (UricNote teal)'
