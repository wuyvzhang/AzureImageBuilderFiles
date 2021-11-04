Connect-AzAccount
Get-AzSubscription | Out-GridView -PassThru | Select-AzSubscription

$currentAzContext = Get-AzContext
# destination image resource group
$imageResourceGroup = "AIBTest-RG"
$location = "southeastasia"
$subscriptionID = $currentAzContext.Subscription.Id
$imageName = "Win1020h2-1104"
$runOutputName = "win1020h2ManImg01ro"
$imageTemplateName = "window1020h2Template"
$runOutputName = "winSvrSigR01"
$imageRoleDefName = "Azure Image Builder Image Def"
$idenityName = "aibIdentity"
# create resource group for image and image template resource
if ($null -eq (Get-AzResourceGroup -Name $imageResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $imageResourceGroup -Location $location
}


$resourceproviderfeature = Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
If ($resourceproviderfeature.RegistrationState -ne "Registered") {
    Write-Host "Resource Provider not yet Registered! Registering now..."
    Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
    Write-Host "Waiting loop until Resource Provider is Registered..."
    Do {
        Start-Sleep -Seconds 5
    }
    While ((Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages).RegistrationState -ne "Registered")

    Write-Host "Registering Feature now..."
    Register-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
    Do {
        Start-Sleep -Seconds 5
    }
    While ((Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview).RegistrationState -ne "Registered")
}
Write-Host "Resource Provider OK."

Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage | Where-Object RegistrationState -ne Registered | Register-AzResourceProvider



$resourceprovider = Get-AzResourceProvider -ProviderNamespace Microsoft.ManagedIdentity
If ($resourceprovider.RegistrationState -ne "Registered") {
    Write-Host "Resource Provider not yet Registered! Registering now..."
    Register-AzResourceProvider -ProviderNamespace Microsoft.ManagedIdentity
    Write-Host "Waiting loop until Resource Provider is Registered..."
    Do {
        Start-Sleep -Seconds 5
    }
    While ((Get-AzResourceProvider -ProviderNamespace Microsoft.ManagedIdentity).RegistrationState -ne "Registered")
}
Write-Host "Resource Provider OK."


if ($null -eq (Get-Module -ListAvailable Az.ManagedServiceIdentity)) {
    Install-Module -Name Az.ManagedServiceIdentity -Scope CurrentUser -Force
}
if ($null -eq (Get-Module -ListAvailable Az.ImageBuilder)) {
    Install-Module -Name Az.ImageBuilder -Scope CurrentUser -Force
}
Import-Module -Name Az.ManagedServiceIdentity
Import-Module -Name Az.ImageBuilder




if ($null -eq (Get-AzUserAssignedIdentity -Name $idenityName -ResourceGroupName $imageResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName
}


$idenityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId




if ($null -eq (Get-AzRoleDefinition -Name $imageRoleDefName -ErrorAction SilentlyContinue)) {
    #Custom Role definition does not exist. Creating now...
    $aibRoleImageCreationUrl = "https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
    $aibRoleImageCreationPath = "aibRoleImageCreation.json"

    # download config
    Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

    # create role definition
    New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json
    ### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve: https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
}

#Check Role Assignment
if ($null -eq (Get-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup" -ErrorAction SilentlyContinue)) {
    # grant role definition to image builder service principal
    New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
}





$templateUrl = "https://raw.githubusercontent.com/wuyvzhang/AzureImageBuilderFiles/main/ImageTemplateWin01.json"
$templateFilePath = "helloImageTemplateWin01.json"

# download configs
 Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>', $location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>', $runOutputName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imageName>', $imageName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>', $idenityNameResourceId) | Set-Content -Path $templateFilePath



$resourcetowatch = Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -ImageTemplateName $ImageTemplateName -ErrorAction SilentlyContinue
If ($null -ne $resourcetowatch) {
    Write-Host "Template found, removing ..."
    Remove-AzImageBuilderTemplate -ImageTemplateName $ImageTemplateName -ResourceGroupName $imageResourceGroup
}

New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2019-05-01-preview" -imageTemplateName $imageTemplateName -svclocation $location


Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run -Force

#Get Status of the Image Build and Query
$resourcetowatch = Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName
do {
    $status = (Get-AzResource -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName).Properties.lastRunStatus
    $status | Format-Table *
    Start-Sleep -Seconds 30
} while ($status.runState -eq "Running")