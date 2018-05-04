function New-HXSession {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/token' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/token' }
        else { $Endpoint = $Uri }

        # Get the plaintext password from the credential object:
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        $auth = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($password)"))

        $headers = @{
            Authorization = $auth
        }

        # Make the request to the controller:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -Method Get -SessionVariable LoginSession -ErrorAction Stop -Headers $headers -SkipCertificateCheck 

        $TokenSession = $WebRequest.Headers.'X-FeApi-Token' | out-string -NoNewline
        # -NoNewLine was introduced in PS6.0, so use below to enable Windows PowerShell backwards compatibility:
        #$TokenSession = $TokenSession -replace "`t|`n|`r","" # bugfix: 'out-string' introduce a new-line at the end of the string. This hack will remove it. 
        
        if ($TokenSession -eq $null) { throw "Login token not observed in the authentication response." }
        
        # Return the object:
        $out = New-Object System.Object
        $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
        $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
        $out | Add-Member -Type NoteProperty -Name WebSession -Value $LoginSession
        $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
        $out
    }
    end { }
}