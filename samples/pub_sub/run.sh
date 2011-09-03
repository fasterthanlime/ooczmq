for i in {0..1000}
do
    ./sub_zloop &
    echo $i
done
echo "done"

