 $appName = 'teams'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath

 write-host 'AIB Customization: Install watermark"
 $SetupURL = 'https://aibstore.blob.core.windows.net/software/Setup.msi'
 $SetupMSI = 'Setup.msi'
 $outputPath = $LocalPath + '\' + $SetupMSI
 Invoke-WebRequest -Uri $SetupURL -OutFile $outputPath
 Start-Process -FilePath Setup.msi -Args "/qn /norestart"
 write-host 'AIB Customization: Finished Install watermark" 
