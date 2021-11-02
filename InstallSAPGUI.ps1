 write-host 'AIB Customization: Install the SAPGUI'
 $appName = 'teams'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath
 $sapGUIURL = 'https://aibstore.blob.core.windows.net/privatesoftware/SAPGUI750_V1.1.exe'
 $sapGUILexe = 'SAPGUI750_V1.1.exe'
 $outputPath = $LocalPath + '\' +  $sapGUILexe
 Invoke-WebRequest -Uri $sapGUIURL -OutFile $outputPath
 $serviceURL = "https://aibstore.blob.core.windows.net/privatesoftware/services"
 $SAPMSGURL = "https://aibstore.blob.core.windows.net/privatesoftware/sapmsg.ini"
 $service = "services"
 $SAPMSG = "sapmsg.ini"
 $serviceoutputPath = $LocalPath + '\' +  $service
 Invoke-WebRequest -Uri $serviceURL -OutFile $serviceoutputPath
 $SAPMSGoutputPath = $LocalPath + '\' + $SAPMSG
 Invoke-WebRequest -Uri $SAPMSGURL -OutFile $SAPMSGoutputPath
 write-host 'AIB Customization: Starting Install the SAPGUI'
 Start-Process -FilePath $outputPath -Args "/Silent" -Wait
 write-host 'AIB Customization: Starting Install the SAPGUI'
 write-host 'AIB Customization: Copy Config file to Destination'
 Copy-Item -Path $serviceoutputPath -Destination "C:\Windows\System32\drivers\etc\" -Force
 Copy-Item -Path $SAPMSGoutputPath -Destination "C:\Windows\" -Force
