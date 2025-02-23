$mmcPath = "C:\Windows\System32\mmc.exe"

$mscPath = "C:\Users\1365935510N\Documents\AdminTools15.msc"

Start-Process -FilePath $mmcPath -ArgumentList $mscPath