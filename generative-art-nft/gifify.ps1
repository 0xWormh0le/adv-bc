$zombie_dir=$args[0]
$bg_dir=$args[1]
$dest_dir=$args[2]

# .\imagemagick\convert -delay 5 -loop 0 bg/01/*.png null: zombies/01/0000000.png -resize 900x900 -layers composite -layers optimizetransparency aaa.gif
#gifsicle -O3 --lossy=80 $dest-tmp.gif -o $dest

$count=0
foreach ($zombie in Get-ChildItem $zombie_dir)
{
	$zombie_number = Split-Path $zombie_dir -Leaf
	Get-Date
	foreach ($bg in Get-ChildItem $bg_dir)
	{
		$bg_number = $bg
		$output_path = $dest_dir + "/bg" + $bg_number + "/" + $zombie_number
		$output = $output_path + "/" + $bg_number + "-" + $zombie_number + "-" + $zombie.BaseName
		Write-Host $output
		$bgpng = $bg_dir + "/" + $bg_number + "/*.png"
		$tmp = $output + "-tmp.gif"
		$final = $output + ".gif"
		mkdir -F $output_path > $null
		$zombie_path = $zombie_dir + "/" + $zombie
		.\tools\imagemagick\convert -delay 5 -loop 0 $bgpng null: $zombie_path -resize 900x900 -layers composite -layers optimizetransparency $tmp
		.\tools\gifsicle\gifsicle -O3 --lossy=80 $tmp -o $final
		rm $tmp
	}
	$count++
	Write-Host $count
	Get-Date

}
