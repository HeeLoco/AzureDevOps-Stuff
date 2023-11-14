#thank you black marble
#https://blogs.blackmarble.co.uk/rfennell/a-more-secure-alternative-to-pat-tokens-for-azure-devops/#:~:text=A%20newly%20available%20and%20better,defined%20securely%20in%20Azure%20AD.

$guid = New-guid;
$identifier = $guid.ToString().ToUpper();
write-host ("Deployment Identifier: " + $identifier);

#variables
$tenantId = "";
$ClientID = "";
$Secret = "";
$organizationName = "";
$projectName = ";
$PipelineID = "";

# This is a static value
$AdoAppClientID = "499b84ac-1321-427f-aa17-267ca6975798";

$loginUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token";
$body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientID
    client_secret = $Secret 
    resource      = $AdoAppClientID
}
$token = Invoke-RestMethod -Uri $loginUrl -Method POST -Body $body;


#header
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]";
$headers.Add("Content-Type", "application/json");
$headers.Add("Authorization", "Bearer $($token.access_token)");

$Body = @"
{
  `"templateParameters`": {
    `"identifier`": `"$identifier`"
  }
}
"@

write-host ("Calling Pipeline ...");
$url = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines/$PipelineID/runs?api-version=7.0";
$response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $Body;
$response | ConvertTo-Json;

$RunID = $response.id;

write-host ("Checking Pipeline progress ...");
do
{
    Start-Sleep 10;
    $GetUrl = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines/$PipelineID/runs/$RunID`?api-version=7.0";

    $response = Invoke-RestMethod -Headers $Headers -Uri $GetURL -UseBasicParsing -Method GET;

}while ($response.state -eq "inProgress")

if ($response.result -eq "failed")
{
    Write-host ("Pipeline failed");
    return;
}
