param (
    [parameter (mandatory = $true)]
    [string] $storageAccRg,

    [parameter (mandatory = $true)]
    [string] $storageAccName,

    [parameter (mandatory = $true)]
    [string] $storageAccLocation,

    [parameter (mandatory = $true)]
    [string] $storageContainerName
)

if ((az group exists --name $storageAccRg ) -eq "true") {
    Write-Host "Resource group '$storageAccRg' exists."
} else {
    Write-Host "Resource group '$storageAccRg' does not exist."
    az group create --name $storageAccRg --location $storageAccLocation
}

$storageAccounts = az storage account list --query "[?name == $storageAccName ]"
if ($storageAccounts | ConvertFrom-Json | Where-Object { $_.name -eq '$storageAccName' }) {
    Write-Host "Storage account '$storageAccName' exists."
} else {
    Write-Host "Storage account '$storageAccName' does not exist."
    az storage account create --name "$storageAccName" --resource-group "$storageAccRg" --location "$storageAccLocation" --sku Standard_LRS
}

$containerExists = az storage container exists --name $storageContainerName --account-name $storageAccName --output json
$containerExistsObject = $containerExists | ConvertFrom-Json
if ($containerExistsObject.exists) {
    Write-Host "Container '$storageContainerName' exists in storage account '$storageAccName'."
} else {
    Write-Host "Container '$storageContainerName' does not exist in storage account '$storageAccName'."
    $ctx=$(az storage account show-connection-string --name "$storageAccName" --resource-group "$storageAccRg" --output json --query 'connectionString')
    az storage container create --name "$storageContainerName" --connection-string "$ctx"
}  