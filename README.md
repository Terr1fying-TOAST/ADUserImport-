
# ADUserImport

Bulk create Active Directory user accounts from a CSV file using PowerShell.

This script automates the process of creating multiple users in Active Directory by importing user information from a CSV file. It includes validation, logging, and error handling to make the process reliable and auditable.

---

## Features

- Bulk user creation from CSV
- Input validation to prevent invalid entries
- Duplicate user detection
- Logging system with timestamps
- Automatic log directory creation
- Error handling using try/catch
- Version tracking and changelog

---

## Requirements

- Windows Server with **Active Directory Domain Services**
- PowerShell **ActiveDirectory module**
- Permissions to create users in the target OU
- CSV file containing user information

Install the AD module if required:

```powershell
Import-Module ActiveDirectory
```

## CSV Format

The CSV file must contain the following headers:

FirstName, LastName, Email

example file:

```txt
FirstName,LastName,Email
Alex,Chem,alex.chem@gmail.com
Maya,Bing,maya.bing@gmail.com
```

## Script Configuration

Edit the configuration variables in the script before running:

```powershell
$CsvPath = "C:\path\to\.csv"
$TargetOU = "OU=OU_NAME,DC=DOMAIN,DC=DOMAIN"
$DefaultPassword = ConvertTo-SecureString "Default Password" -AsPlainText -Force
```

`CsvPath` = Location of CSV file

`TargetOU` = Organizational Unit where users will be created.

can be found using `The OU path can be retrieved using: 
`Get-ADOrganizationalUnit -Filter * | Select Name, DistinguishedName`

`DefaultPassword` = Default password assigned to new users

**NOTE**: It is HIGHLY Recommended to have different default passwords for each user!

Users will be required to change their password at first login.

## Username Format

The script generates usernames using:
```
firstname.lastname
```

Example:
```
Alex Chem → alex.chem
```

## Example Execution

```powershell
.\ADUserImport.ps1
```

Example output:
```
Created user: Alex Chem (alex.chem)
User already exists: maya.bing
```

## Logging

The script will write logs to:
```
C:\Logs\ADUserImport.log
```

example entries:

```log
12/03/26 14:22:01 [INFO] Starting AD user import script version 1.4
12/03/26 14:22:02 [INFO] Created user: Alex Chem (alex.chem)
12/03/26 14:22:03 [WARNING] User already exists: maya.bing
12/03/26 14:22:04 [ERROR] Failed to create user
12/03/26 14:22:05 [INFO] Completed AD user import script version 1.4
```
If the `C:\Logs` directory does not exist, it will be created automatically.

## How the Script Works

The script follows these steps:

	1.	Import the Active Directory module
	2.	Read the CSV file containing user data
	3.	Loop through each user entry
	4.	Validate the required fields
	5.	Generate username and UPN values
	6.	Check if the account already exists
	7.	Create the new user account
	8.	Log the result

## Change Log

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