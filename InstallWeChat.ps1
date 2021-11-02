 $appName = 'teams'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath



 write-host 'AIB Customization: Install Wechat'
 $WeComURL = 'https://aibstore.blob.core.windows.net/software/WeCom_3.1.18.6007.exe'
 $WeComEXE = 'WeCom.exe'
 $outputPath = $LocalPath + '\' + $WeComEXE
 Invoke-WebRequest -Uri $WeComURL -OutFile $outputPath
 Start-Process -FilePath WeCom.exe -Args "/S"
 write-host 'AIB Customization: Finished Install WeComEXE' 
