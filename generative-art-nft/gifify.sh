zombie_dir=$1
bg_dir=$2
dest_dir=$3

#convert -delay 5 -loop 0 $source/*.png null: \( $zombie -resize 900x900 \) -layers composite -layers optimize +map $dest-tmp.gif
#gifsicle -O3 --lossy=80 $dest-tmp.gif -o $dest

count=0
for zombie in $zombie_dir/*.png
do
	zombie_number="$(basename $zombie_dir)"
	for bg in $bg_dir/*
	do
		bg_number="$(basename $bg)"
		output="$dest_dir/bg$bg_number/$zombie_number/$bg_number-$zombie_number-$(basename $zombie .png)"
		echo "processing $output $(date)"
		mkdir -p "$(dirname $output)"
		convert -delay 5 -loop 0 $bg/*.png null: \( $zombie -resize 900x900 \) -layers composite -layers optimize +map $output-tmp.gif
		gifsicle -O3 --lossy=80 $output-tmp.gif -o $output.gif
		rm $output-tmp.gif
		echo "done $(date)"
	done
	((count++))
	echo $count
done
