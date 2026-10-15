Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$master = [Drawing.Bitmap]::FromFile((Join-Path $root 'assets/pixel/actors-master.png'))
$atlas = [Drawing.Bitmap]::new(2304,1024,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($atlas)
$graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
$regions = @(@(0,0,355,500),@(365,0,563,500),@(927,0,342,500),@(1350,0,367,500),@(0,500,432,416),@(430,500,449,416),@(879,500,556,416),@(1435,500,282,416))
for ($i=0;$i -lt 8;$i++) {
 $r=$regions[$i]
 $sourceRect=[Drawing.Rectangle]::new($r[0],$r[1],$r[2],$r[3])
 $x=($i%4)*576+[int]((576-$r[2])/2)
 $y=[int][Math]::Floor($i/4)*512+512-$r[3]-12
 $destRect=[Drawing.Rectangle]::new($x,$y,$r[2],$r[3])
 $graphics.DrawImage($master,$destRect,$sourceRect,[Drawing.GraphicsUnit]::Pixel)
}
$atlas.Save((Join-Path $root 'assets/pixel/actors-layout-master.png'),[Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose();$atlas.Dispose();$master.Dispose()
& (Join-Path $root '.tools/um-env/Scripts/python.exe') -m um sprite pixelate (Join-Path $root 'assets/pixel/actors-layout-master.png') (Join-Path $root 'assets/pixel/actors.png') --size 576x256 --colors 96
