# Generates extra 96x96 pages (pure black and white) in the same style as the hand-drawn ones:
# 3x5 pixel font (4px advance), dotted ruled lines, simple silhouettes.
# Usage: powershell -ExecutionPolicy Bypass -File tools/gen_pages.ps1
# Writes assets/pages/<name>_96.png. Optional -Preview <dir> also writes 5x enlarged copies.

param(
	[string]$OutDir = (Join-Path $PSScriptRoot "..\assets\pages"),
	[string]$Preview = ""
)

Add-Type -AssemblyName System.Drawing
$Size = 96

# ---------------------------------------------------------------- font (3x5, matches diary_64)
$Font = @{
	'A'=@('.#.','#.#','###','#.#','#.#'); 'B'=@('##.','#.#','##.','#.#','##.'); 'C'=@('.##','#..','#..','#..','.##')
	'D'=@('##.','#.#','#.#','#.#','##.'); 'E'=@('###','#..','##.','#..','###'); 'F'=@('###','#..','##.','#..','#..')
	'G'=@('.##','#..','#.#','#.#','.##'); 'H'=@('#.#','#.#','###','#.#','#.#'); 'I'=@('###','.#.','.#.','.#.','###')
	'J'=@('..#','..#','..#','#.#','.#.'); 'K'=@('#.#','#.#','##.','#.#','#.#'); 'L'=@('#..','#..','#..','#..','###')
	'M'=@('#.#','###','#.#','#.#','#.#'); 'N'=@('##.','#.#','#.#','#.#','#.#'); 'O'=@('.#.','#.#','#.#','#.#','.#.')
	'P'=@('##.','#.#','##.','#..','#..'); 'Q'=@('.#.','#.#','#.#','##.','.##'); 'R'=@('##.','#.#','##.','#.#','#.#')
	'S'=@('.##','#..','.#.','..#','##.'); 'T'=@('###','.#.','.#.','.#.','.#.'); 'U'=@('#.#','#.#','#.#','#.#','###')
	'V'=@('#.#','#.#','#.#','#.#','.#.'); 'W'=@('#.#','#.#','#.#','###','#.#'); 'X'=@('#.#','#.#','.#.','#.#','#.#')
	'Y'=@('#.#','#.#','.#.','.#.','.#.'); 'Z'=@('###','..#','.#.','#..','###')
	'0'=@('###','#.#','#.#','#.#','###'); '1'=@('.#.','##.','.#.','.#.','###'); '2'=@('##.','..#','.#.','#..','###')
	'3'=@('##.','..#','.#.','..#','##.'); '4'=@('#.#','#.#','###','..#','..#'); '5'=@('###','#..','##.','..#','##.')
	'6'=@('.##','#..','###','#.#','###'); '7'=@('###','..#','.#.','.#.','.#.'); '8'=@('###','#.#','###','#.#','###')
	'9'=@('###','#.#','###','..#','##.')
	'.'=@('...','...','...','...','#..'); ','=@('...','...','...','.#.','#..'); '!'=@('.#.','.#.','.#.','...','.#.')
	'?'=@('##.','..#','.#.','...','.#.'); "'"=@('.#.','.#.','...','...','...'); '-'=@('...','...','###','...','...')
	':'=@('...','.#.','...','.#.','...'); '/'=@('..#','..#','.#.','#..','#..'); '£'=@('.##','.#.','###','.#.','###')
	' '=@('...','...','...','...','...')
}

# ---------------------------------------------------------------- canvas helpers ($ink[x,y] = $true is black)
function New-Page { $script:ink = New-Object 'bool[,]' $Size, $Size }
function Px([int]$x, [int]$y, [bool]$on = $true) { if ($x -ge 0 -and $y -ge 0 -and $x -lt $Size -and $y -lt $Size) { $script:ink[$x, $y] = $on } }

function Text([int]$x, [int]$y, [string]$s, [int]$k = 1, [bool]$on = $true) {
	foreach ($ch in $s.ToUpper().ToCharArray()) {
		$g = $Font[[string]$ch]
		for ($r = 0; $r -lt 5; $r++) { for ($c = 0; $c -lt 3; $c++) {
			if ($g[$r][$c] -eq '#') { for ($i = 0; $i -lt $k; $i++) { for ($j = 0; $j -lt $k; $j++) { Px ($x + $c * $k + $i) ($y + $r * $k + $j) $on } } }
		} }
		$x += 4 * $k
	}
}
function TextW([string]$s, [int]$k = 1) { return $s.Length * 4 * $k - $k }
function TextC([int]$y, [string]$s, [int]$k = 1, [bool]$on = $true) { Text ([int][Math]::Floor(($Size - (TextW $s $k)) / 2)) $y $s $k $on }
function TextR([int]$right, [int]$y, [string]$s) { Text ($right - (TextW $s) + 1) $y $s }

function HLine([int]$x0, [int]$x1, [int]$y, [bool]$on = $true) { for ($x = $x0; $x -le $x1; $x++) { Px $x $y $on } }
function VLine([int]$x, [int]$y0, [int]$y1) { for ($y = $y0; $y -le $y1; $y++) { Px $x $y } }
function Dotted([int]$x0, [int]$x1, [int]$y) { for ($x = $x0; $x -le $x1; $x++) { if ($x % 2 -eq 0) { Px $x $y } } }
function Box([int]$x0, [int]$y0, [int]$x1, [int]$y1) { HLine $x0 $x1 $y0; HLine $x0 $x1 $y1; VLine $x0 $y0 $y1; VLine $x1 $y0 $y1 }
function Fill([int]$x0, [int]$y0, [int]$x1, [int]$y1, [bool]$on = $true) { for ($y = $y0; $y -le $y1; $y++) { HLine $x0 $x1 $y $on } }
function Ellipse([double]$cx, [double]$cy, [double]$rx, [double]$ry, [bool]$on = $true) {
	for ($y = [int][Math]::Floor($cy - $ry); $y -le [Math]::Ceiling($cy + $ry); $y++) {
		for ($x = [int][Math]::Floor($cx - $rx); $x -le [Math]::Ceiling($cx + $rx); $x++) {
			$dx = ($x - $cx) / $rx; $dy = ($y - $cy) / $ry
			if ($dx * $dx + $dy * $dy -le 1.0) { Px $x $y $on }
		}
	}
}
function Line([int]$x0, [int]$y0, [int]$x1, [int]$y1, [int]$w = 1) {
	$n = [Math]::Max([Math]::Abs($x1 - $x0), [Math]::Abs($y1 - $y0))
	for ($i = 0; $i -le $n; $i++) {
		$x = [int][Math]::Round($x0 + ($x1 - $x0) * $i / [Math]::Max($n, 1))
		$y = [int][Math]::Round($y0 + ($y1 - $y0) * $i / [Math]::Max($n, 1))
		for ($a = 0; $a -lt $w; $a++) { for ($b = 0; $b -lt $w; $b++) { Px ($x + $a) ($y + $b) } }
	}
}
# Ruled page like diary_64: margin rule, dotted lines every 8px, text rows 2px below each rule
function Ruled([int]$margin = 6) {
	VLine $margin 0 ($Size - 1)
	for ($y = 8; $y -lt $Size; $y += 8) { Dotted 0 ($Size - 1) $y }
}

function Save-Page([string]$name) {
	$bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
	for ($y = 0; $y -lt $Size; $y++) { for ($x = 0; $x -lt $Size; $x++) {
		$bmp.SetPixel($x, $y, $(if ($script:ink[$x, $y]) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::White }))
	} }
	New-Item -ItemType Directory -Force $OutDir | Out-Null
	$path = Join-Path $OutDir "$name.png"
	$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
	if ($Preview) {
		New-Item -ItemType Directory -Force $Preview | Out-Null
		$big = New-Object System.Drawing.Bitmap ($Size * 5), ($Size * 5)
		$g = [System.Drawing.Graphics]::FromImage($big)
		$g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
		$g.DrawImage($bmp, 0, 0, $Size * 5, $Size * 5)
		$big.Save((Join-Path $Preview "$name.png")); $g.Dispose(); $big.Dispose()
	}
	$bmp.Dispose()
	Write-Output $path
}

# ---------------------------------------------------------------- diary_2: the next diary entry
New-Page
Ruled 6
HLine 0 ($Size - 1) 8
$lines = @('NOV 2', 'SOLD MUMS RING.', 'THE MAN GAVE ME', 'FORTY POUNDS.', 'IT WAS WORTH MORE', 'THAN THAT.', '',
	'BOUGHT COAL AND', 'BREAD. STILL COLD.', 'ONLY THE PAPERS', 'LEFT TO BURN NOW.')
for ($i = 0; $i -lt $lines.Count; $i++) { Text 9 (2 + 8 * $i) $lines[$i] }
Save-Page "diary2_96"

# ---------------------------------------------------------------- final notice (a bill)
New-Page
Box 1 1 94 94
TextC 5 'FINAL NOTICE'
Fill 4 12 91 13
Text 6 17 'GAS AND ELECTRIC'
Text 6 25 'ACCOUNT 004471'
$rows = @(@('OCT USAGE', '£62.10'), @('LATE FEE', '£15.00'), @('ARREARS', '£84.20'))
for ($i = 0; $i -lt $rows.Count; $i++) {
	Dotted 4 91 (32 + 11 * $i)
	Text 6 (36 + 11 * $i) $rows[$i][0]; TextR 89 (36 + 11 * $i) $rows[$i][1]
}
HLine 4 91 65
Text 6 68 'TOTAL DUE'; TextR 89 68 '£161.30'
Text 6 76 'PAY BY 30 NOV OR'
Fill 4 83 91 92
TextC 85 'SUPPLY WILL BE CUT' 1 $false
Save-Page "bill_96"

# ---------------------------------------------------------------- lost dog poster (silhouette)
New-Page
Box 1 1 94 94
TextC 5 'LOST DOG' 2
# dog facing right, standing; origin (ox, oy) is the top-left of a ~50x30 box
$ox = 22; $oy = 20
Ellipse ($ox + 22) ($oy + 15) 14 6                           # body
Ellipse ($ox + 34) ($oy + 11) 5 6                            # chest and neck
Ellipse ($ox + 39) ($oy + 6) 5 4.5                           # head
Fill ($ox + 42) ($oy + 6) ($ox + 47) ($oy + 9)               # snout
Px ($ox + 47) ($oy + 6) $false                               # rounded nose top
Ellipse ($ox + 36) ($oy + 6) 1.6 4                           # floppy ear (dark)
Fill ($ox + 11) ($oy + 18) ($ox + 13) ($oy + 29); Fill ($ox + 15) ($oy + 18) ($ox + 17) ($oy + 28)   # back legs
Fill ($ox + 30) ($oy + 16) ($ox + 32) ($oy + 29); Fill ($ox + 34) ($oy + 16) ($ox + 36) ($oy + 28)   # front legs
HLine ($ox + 11) ($ox + 14) ($oy + 29); HLine ($ox + 30) ($ox + 33) ($oy + 29)                       # paws
Line ($ox + 9) ($oy + 12) ($ox + 3) ($oy + 4) 2                                                      # tail
Ellipse ($ox + 37) ($oy + 5) 1.2 1.2 $false                                                          # eye...
Ellipse ($ox + 37) ($oy + 5) 0.6 0.6                                                                 # ...with pupil
HLine 6 89 52
TextC 56 'ANSWERS TO BISCUIT'
TextC 64 'BROWN WITH ONE'
TextC 72 'WHITE EAR. SHY.'
Fill 4 80 91 91
TextC 83 'REWARD £50' 1 $false
Save-Page "lost_dog_96"

# ---------------------------------------------------------------- postcard (silhouette picture + message)
New-Page
Box 1 1 94 94
Box 4 4 91 46
# cliff on the left with a lighthouse on top
for ($x = 5; $x -le 40; $x++) { $top = 30 + [int]([Math]::Pow(($x - 5) / 35.0, 2) * 15); Fill $x $top $x 45 }
Fill 18 14 26 30; for ($y = 14; $y -le 30; $y++) { $w = [int](($y - 14) / 6); Fill (18 - $w) $y (26 + $w) $y }   # tower, widening down
Fill 17 9 27 13; Fill 19 7 25 8; Px 22 6                     # lamp room, roof, spire
Fill 19 10 25 12 $false; Fill 21 10 23 12                    # lit window with the lamp in it
HLine 17 27 18 $false; HLine 16 28 24 $false                 # white bands on the tower
for ($i = 0; $i -lt 8; $i++) { Px (30 + 3 * $i) (11 - [int]($i / 2)) }   # beam, dotted
for ($i = 0; $i -lt 8; $i++) { Px (30 + 3 * $i) (12 + [int]($i / 3)) }
for ($y = 36; $y -le 45; $y += 3) { for ($x = 42; $x -le 90; $x++) { if ((($x + $y) % 6) -lt 2) { Px $x $y } } }    # waves
foreach ($b in @(@(60, 18), @(70, 14), @(78, 20))) { Px $b[0] $b[1]; Px ($b[0] + 1) ($b[1] + 1); Px ($b[0] + 2) $b[1]; Px ($b[0] - 1) ($b[1] - 1); Px ($b[0] + 3) ($b[1] - 1) }   # gulls
$msg = @('DEAR SAM,', 'THE SEA IS LOVELY.', 'DAD SAYS WE CAN COME', 'BACK NEXT SUMMER.', 'LOVE, MUM X')
for ($i = 0; $i -lt $msg.Count; $i++) { Text 6 (50 + 8 * $i) $msg[$i]; Dotted 4 91 (56 + 8 * $i) }
Save-Page "postcard_96"

# ---------------------------------------------------------------- gran's recipe (ruled, with a pot)
New-Page
Ruled 6
Text 9 2 "GRAN'S STEW"
HLine 0 ($Size - 1) 8
$steps = @('2 ONIONS', '4 CARROTS', '1 LB BEEF', 'SPLASH OF STOUT', 'STIR SLOWLY.', 'SIMMER 3 HOURS.', 'NEVER RUSH IT.', '', '', '- GRAN')
for ($i = 0; $i -lt $steps.Count; $i++) { Text 9 (10 + 8 * $i) $steps[$i] }
# pot in the empty bottom-right corner, under the method
Fill 62 72 88 86; Ellipse 75 86 13 4                         # pot body and rounded base
Fill 60 70 90 71                                             # rim
Fill 57 74 59 76; Fill 91 74 93 76                           # handles
Fill 72 67 78 69; Fill 74 66 76 66                           # lid knob
foreach ($sx in @(66, 75, 84)) { for ($k = 0; $k -lt 4; $k++) { Px ($sx + (($k % 2) * 2) - 1) (64 - 2 * $k) } }   # steam
Save-Page "recipe_96"
