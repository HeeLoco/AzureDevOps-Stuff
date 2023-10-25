$guid = New-guid
$id = $guid.ToString().ToUpper()
"id: " + $id

#variables
$tenantId = ""
$ClientID = ""
$Secret = "";
$organizationName = "";
$projectName = "";
$PipelineID = ""


#create basic auth information
# $pair = "$($username):$($token)"
# $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

# This is a static value
$AdoAppClientID = "499b84ac-1321-427f-aa17-267ca6975798";

$loginUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientID
    client_secret = $Secret 
    resource      = $AdoAppClientID
}
$token = Invoke-RestMethod -Uri $loginUrl -Method POST -Body $body


#header
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Bearer $($token.access_token)")


$Body = @"
{
  `"templateParameters`": {
    `"matrixIdentifier`": `"$matrixIdentifier`"
  }
}
"@

"Calling Pipeline ..."
$url = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines/$PipelineID/runs?api-version=7.0"
$response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $Body
$response | ConvertTo-Json

$RunID = $response.id

"check progress ..."
do
{
    Start-Sleep 10
    $GetUrl = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines/$PipelineID/runs/$RunID`?api-version=7.0"

    $response = Invoke-RestMethod -Headers $Headers -Uri $GetURL -UseBasicParsing -Method GET

}while ($response.state -eq "inProgress")

if ($response.result -eq "failed")
{
    Write-host "Pipeline failed"
    return 666
}
