$culture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")

$start = [datetime]::ParseExact("11/01/2024", "MM/dd/yyyy", $culture)
$end   = [datetime]::ParseExact("11/10/2024", "MM/dd/yyyy", $culture)

$date = $start

$range = [System.Collections.ArrayList]::new()

while( $date -ne $end.AddDays(1) ){
    $range.add($date) | Out-Null
    $date = $date.AddDays(1)
}
$range = $range | Where-Object { $_.DayofWeek -ne 'Saturday' -and $_.DayofWeek -ne 'Friday' } | ForEach-Object { $_.ToString("MM/dd/yyyy") }
$range 