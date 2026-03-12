<#
Script: ADUserImport-v1.4.ps1
Version: 1.4
Author: Hilton Furter
Purpose: Bulk create Active Directory users from a CSV file
Description: Reads user information from a CSV file and creates accounts in the specified OU.
Requirements: Active Directory PowerShell module and appropriate permissions to create users in the target OU.
#>


# Import the Active Directory module
Import-Module ActiveDirectory 


# Configuration

$ScriptVersion = "1.4"                                   # Script version for logging purposes

$CsvPath = "C:\Users\root\Downloads\NewUsers.csv"      # Full path to the CSV file containing user data

$TargetOU = "OU=OU_NAME,DC=DOMAIN,DC=DOMAIN"            # Target OU where accounts will be created

# Default password for new accounts
$DefaultPassword = ConvertTo-SecureString "Default Password" -AsPlainText -Force


# Import users from the CSV file
$Users = Import-Csv -Path $CsvPath

$LogFile = "C:\Logs\ADUserImport.log"

# Create the log directory if it does not already exist
$LogDirectory = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}


# Write a timestamped entry to the log file
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "dd/MM/yy HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"

    Add-Content -Path $LogFile -Value $LogEntry
}

Write-Log "Starting AD user import script version $ScriptVersion"

# Main processing loop

foreach ($User in $Users) {
    # Extract values from the current CSV row
    $FirstName = $User.FirstName.Trim()
    $LastName = $User.LastName.Trim()
    $UserEmail = $User.Email.Trim()

    # Skip rows with missing required values
    if ([string]::IsNullOrWhiteSpace($FirstName) -or
        [string]::IsNullOrWhiteSpace($LastName)) {
        Write-Host "Skipping invalid row in CSV" -ForegroundColor Yellow
        Write-Log "Skipped invalid CSV row. FirstName='$FirstName', LastName='$LastName'" "WARNING"
        continue
    }

    # Build account naming values
    $DisplayName = "$FirstName $LastName" # Full name shown in AD
    $SamAccountName = "$FirstName.$LastName".ToLower() # Username format: firstname.lastname
    $UserPrincipalName = "$SamAccountName@HF-MINT.NZ" # User principal name

    # Check whether the account already exists
    $ExistingUser = Get-ADUser -Filter  "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue

    # Skip existing accounts and continue to the next row
    if ($ExistingUser) {
        Write-Host "User already exists: $SamAccountName" -ForegroundColor Yellow
        Write-Log "User already exists: $SamAccountName" "WARNING"
        continue
    }

    # Create the AD user account
    try {
        New-ADUser -Name $DisplayName `
                   -GivenName $FirstName `
                   -Surname $LastName `
                   -DisplayName $DisplayName `
                   -SamAccountName $SamAccountName `
                   -UserPrincipalName $UserPrincipalName `
                   -EmailAddress $UserEmail `
                   -Path $TargetOU `
                   -AccountPassword $DefaultPassword `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true

        # Log successful account creation
        Write-Host "Created user: $DisplayName ($SamAccountName)" -ForegroundColor Green
        Write-Log "Created user: $DisplayName ($SamAccountName)"
    }

    # Log any account creation errors
    catch {
        Write-Host "Error creating user: $DisplayName ($SamAccountName) - $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Failed to create $SamAccountName : $($_.Exception.Message)" "ERROR"
    }
}
Write-Log "Completed AD user import script version $ScriptVersion"



