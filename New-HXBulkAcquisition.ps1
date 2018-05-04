function New-HXBulkAcquisition {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $TokenSession, 

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("win", "linux", "osx", "*")]
        [string] $Platform,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path $_})]
        [string] $Script,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("hostset_id")] 
        [int] $HostsetId,

        [Parameter(Mandatory=$false)]
        [switch] $Passthru,

        [Parameter(Mandatory=$false)]
        [switch] $Raw
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/acqs/bulk' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/acqs/bulk' }
        else { $Endpoint = $Uri + "/?" }

        # Header:
        $headers = @{ "Accept" = "application/json" }
        if (-not($WebSession) -and ($TokenSession)) { $headers += @{ "X-FeApi-Token" = $TokenSession } }

        # Body:
        $base64_script = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path $Script -Raw -Encoding utf8)))
        $body = "{`"host_set`":{`"_id`":$HostsetId},`"scripts`":[{`"platform`":`"win`",`"b64`":`"$base64_script`"}],`"comment`":`"PSAutomaticBulkAcquisition`"}"

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Post -Headers $headers -Body $body -SkipCertificateCheck -ContentType "application/json"
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json


        # Return the object:
        if (-not($Raw)) {
            $WebRequestContent.data | Foreach-Object {
                $out = New-Object System.Object
                $out | Add-Member -Type NoteProperty -Name bulkacquisition_id -Value $_._id
                $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
                $out | Add-Member -Type NoteProperty -Name comment -Value $_.comment
                $out | Add-Member -Type NoteProperty -Name create_time -Value $_.create_time
                $out | Add-Member -Type NoteProperty -Name state -Value $_.state
                $out | Add-Member -Type NoteProperty -Name url -Value $_.url

                # Check if login data is required to be passed thru:
                if ($Passthru) {
                    $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
                    if ($WebSession) { $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession } 
                    if ($TokenSession) { $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession }
                }

                $out
            }
        }
        else {
            $out = New-Object System.Object
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
            $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            $out | Add-Member -Type NoteProperty -Name RequestStatusCode -Value $WebRequest.StatusCode
            $out | Add-Member -Type NoteProperty -Name RequestContent -Value $WebRequestContent
            $out
        }
    }
    end { }
}