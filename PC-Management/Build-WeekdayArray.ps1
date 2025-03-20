$start = get-date "11/1/2024"
$end = get-date "11/10/2024"
$date = $start

$range = [System.Collections.ArrayList]::new()

while( $date -ne $end.AddDays(1) ){
    $range.add($date) | Out-Null
    $date = $date.AddDays(1)
}
$range