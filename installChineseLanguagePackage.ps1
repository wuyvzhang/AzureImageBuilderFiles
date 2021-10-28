 $appName = 'teams'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath


 write-host 'AIB Customization: Install Chinese Language Package'
 $LanguageURL = 'https://aibstore.blob.core.windows.net/software/LanguageExperiencePack.zh-CN.Neutral.appx'
 $LanguageMsi = 'LanguageExperiencePack.appx'
 $outputPath1 = $LocalPath + '\' + $LanguageMsi
 $LicenseURL = 'https://aibstore.blob.core.windows.net/software/License.xml'
 $License = 'License.xml'
 $outputPath2 = $LocalPath + '\' + $License
 Invoke-WebRequest -Uri $LanguageURL  -OutFile $outputPath1
 Invoke-WebRequest -Uri $LicenseURL -OutFile $outputPath2
 Add-AppProvisionedPackage -Online -PackagePath $outputPath1 -LicensePath $outputPath2
 write-host 'AIB Customization: Finished Install Chinese Language Package' 
 
