<#
Script: ADUserImport-v1.4.ps1
Version: 1.4
Author: Hilton Furter: 240000831
Purpose: Bulk create Active Directory users from a CSV file
Description: Reads user information from a CSV file and creates accounts in the specified OU.
Requirements: Active Directory PowerShell module and appropriate permissions to create users in the target OU.
#>


# Import the Active Directory module
Import-Module ActiveDirectory 


# Configuration

$ScriptVersion = "1.4"                                   # Script version for logging purposes

$CsvPath = "C:\Users\root\Downloads\NewUsers.csv"      # Full path to the CSV file containing user data

$TargetOU = "OU=IT_Employees,DC=HF-MINT,DC=NZ"            # Target OU where accounts will be created

# Default password for new accounts
$DefaultPassword = ConvertTo-SecureString "P@ssw0rd01" -AsPlainText -Force


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



<#
Change Log:

v1.0 - 05/03/26
- Initial working version of the script.
- Imports users from a CSV file.
- Creates Active Directory accounts using New-ADUser.
- Added basic configuration for the CSV path and target OU.

v1.1 - 07/03/26
- Added input validation to skip rows with missing required fields.
- Added duplicate user detection using Get-ADUser.
- Added console output messages for created and skipped users.

v1.2 - 09/03/26
- Added structured logging using the Write-Log function.
- Added timestamped log entries and log levels (INFO, WARNING, ERROR).
- Added automatic creation of the log directory if it does not exist.

v1.3 - 11/03/26
- Added a script version variable for version tracking.
- Added log entries for script start and completion.
- Improved comment readability and script structure.
- Updated SamAccountName format to firstname.lastname.

v1.4 - 12/03/26
- Removed the UserID variable because it was not required.
- Updated UserPrincipalName to use SamAccountName instead of UserID.
- Simplified CSV input requirements to FirstName, LastName, and Email.
#>