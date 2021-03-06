function Add-MonitisContact
{
    <#
    .Synopsis
        Adds a contact to monitis
    .Description
        Adds a contact to monitis.  Contacts can be notified when anything happens in monitis.
    .Link
        Get-MonitisContact
    .Example
        Add-MonitisContact -FirstName John -LastName Smith -Account john.smith@anonymous.org -AccountType email
    #>
    param(
    # The first name of the contact
    [Parameter(Mandatory=$true)]
    [string]
    $FirstName,
    

    # The last name of the contact
    [Parameter(Mandatory=$true)]
    [string]
    $LastName,
    
    # The account used to contact the individual 
    [Parameter(Mandatory=$true)]
    [string]
    $Account,    
    
    # The type of account used to contact the individual 
    [Parameter(Mandatory=$true)]
    [ValidateSet("Email","SMS","ICQ","Google", "Twitter", "Phone", "SmsAndPhone", "Url")]
    [string]
    $AccountType,    
    
    # The Monitis API key.  
    # If any command connects to Monitis, the ApiKey and SecretKey will be cached    

    [string]$ApiKey,
    
    # The Monitis Secret key.  
    # If any command connects to Monitis, the ApiKey and SecretKey will be cached    

    [string]$SecretKey,
    
    # The contact group
    [string]$ContactGroup,
    
    # The timezone offset, in minutes
    [ValidateRange(-720, 720)]
    [int]$timeZone,
    
    # The country the contact is located in.
    [string]$Country,
    
    # If set, sends a daily report
    [switch]$SendDailyReport,
    # If set, sends a weekly report
    [switch]$SendWeeklyReport,
    # If set, sends 
    [switch]$SendMonthlyReport,
    # If set, the telephone number is portable (can be changed regardless of carrier).
    # If the locale is en-us, this is always set.
    [switch]$NumberIsPortable,
    # If set, sends HTML alerts
    [switch]$HtmlAlert
    )
    
    begin {
        Set-StrictMode -Off
        $xmlHttp = New-Object -ComObject Microsoft.XMLHTTP
    }
    process {
        #region Reconnect To Monitis
        if ($psBoundParameters.ApiKey -and $psBoundParameters.SecretKey) {
            Connect-Monitis -ApiKey $ApiKey -SecretKey $SecretKey
        } elseif ($script:ApiKey -and $script:SecretKey) {
            Connect-Monitis -ApiKey $script:ApiKey -SecretKey $script:SecretKey
        }
        
        if (-not $apiKey) { $apiKey = $script:ApiKey } 
        
        if (-not $script:AuthToken) 
        {
            Write-Error "Must connect to Monitis first.  Use Connect-Monitis to connect"
            return
        } 
        #endregion 
        
        if (-not $psboundParameters.timeZone) {
            $timeZone = [Timezone]::CurrentTimeZone.GetUtcOffset((Get-Date)).TotalMinutes
        }   
        $xmlHttp.Open("POST", "http://www.monitis.com/api", $false)
        $xmlHttp.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
        $order = 'apiKey', 'authToken', 'validation', 'timestamp', 'output', 
            'version', 'action', 'group', 'firstName', 'lastName', 'account',
            'contactType','timezone', 'sendDailyReport', 'sendWeeklyReport',
            'sendMonthlyReport','portable','country', 'textType'
        $contactType =  switch ($accountType) {
            "Email" { 1 }
            "SMS" {2}
            "ICQ" { 3}
            "Google" { 7}
            "Twitter" { 8 }
            "Phone" { 9 }
            "SmsAndPhone" { 10 }
            "Url" {  11 }         
        }
        
        $postFields = @{
            apiKey = $script:ApiKey
            authToken = $script:AuthToken
            validation = "token"
            timestamp = (Get-Date).ToUniversalTime().ToString("s").Replace("T", " ")
            output = "xml"
            version = "2"            
            action = "addContact"
            group = $contactGroup
            firstName = $firstName
            lastName = $lastName
            timeZone = $timeZone
            account = $account
            contactType = $contactType
        }
        
        if ($SendDailyReport) {
            $postFields.SendDailyReport = "true"
        }
        
        if ($SendWeeklyReport) {
            $postFields.SendWeeklyReport = "true"
        }
        
        if ($SendMonthlyReport) {
            $postFields.SendMonthlyReport = "true"
        }
        
        if ((Get-Culture) -eq 'en-us') {
            # Numbers are portable by law in the US
            $postFields.portable = "true"
        }
        if ($NumberIsPortable) {
            $postFields.portable = "true"
        }
        
        if ($htmlAlert) {
            $postFields.textType = "false"
        } else {
            $postFields.textType = "true"
        }
        
        $postData =  New-Object Text.Stringbuilder
        foreach ($kv in $order) {
            if ($postfields.$kv) {
                $null = $postData.Append("$($kv)=$($postFields[$kv])&")
            }
        }
        $postData = "$postData".TrimEnd("&")
        
        $xmlHttp.Send($postData)        
        $response = $xmlHttp.ResponseText
        
        
    }
} 
