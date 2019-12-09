function New-PrinterAssignmentPolicy {
    [CmdletBinding()]
    param (
        # Delivery Controller IP or Hostname
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Connection $_})]
        [string]$AdminAddress = "localhost",

        # Input File with existing Printer Assignment Settings
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({Test-Path $_})]
        [ValidatePattern("^*.\.json$")]
        [string]$InputFile,

        # Policy Name
        [Parameter(Mandatory)]
        [string]$PolicyName,

        # Mode for handling policy conflicts
        [Parameter(Mandatory=$false)]
        [ValidateSet("Overwrite","Append","Create")]
        [String]$Mode
    )

    begin {
        function Test-CtxPolicy {
            param (
                [String]$PolicyName,
                [String]$Scope = "Computer",
                [System.Management.Automation.PSDriveInfo]$PSDriveObject
            )
            $targetPath = ("Citrix.GroupPolicy.Commands\$($PSDriveObject.Provider.Name)" + "::$($PSDriveObject.Name)" + ":\$Scope" + "\$PolicyName")
            Write-Verbose "Checking for existing Policy: $targetPath"
            if (Get-Item $targetPath -ErrorAction SilentlyContinue) {
                return $true
            }
            else {
                return $false
            }
        }

        function Get-CtxPolicy {
            param (
                [String]$PolicyName,
                [String]$Scope = "Computer",
                [System.Management.Automation.PSDriveInfo]$PSDriveObject
            )
            $targetPath = ("Citrix.GroupPolicy.Commands\$($PSDriveObject.Provider.Name)" + "::$($PSDriveObject.Name)" + ":\$Scope" + "\$PolicyName")
            Write-Verbose "Checking for existing Policy: $targetPath"
            $obj = get-item $targetPath -ErrorAction SilentlyContinue
            return $obj
        }

        function Remove-CtxPolicy {
            param (
                [String]$PolicyName,
                [String]$Scope = "Computer",
                [System.Management.Automation.PSDriveInfo]$PSDriveObject
            )
            $targetPath = ("Citrix.GroupPolicy.Commands\$($PSDriveObject.Provider.Name)" + "::$($PSDriveObject.Name)" + ":\$Scope" + "\$PolicyName")
            Write-Verbose "Removing existing Policy: $targetPath"
            try {
                (get-item $targetPath).Remove()
            }
            catch {
                return $false
            }

        }

        Add-PSSnapin Citrix*
        if (-not (Get-PSSnapin Citrix.Common.GroupPolicy -ErrorAction SilentlyContinue))
        {
            Add-PSSnapin Citrix.Common.GroupPolicy -ErrorAction Stop
        }
        #Import-Module Citrix.GroupPolicy.Commands
    }

    process {
        # Loading Environment
        Write-Verbose "Creating Citrix Policy Drive"
        try {
            $ctxDrive = New-PSDrive -Name LocalFarmGpo -PSProvider Citrix.GroupPolicy.Commands\CitrixGroupPolicy -Controller $AdminAddress -Root "\" -ErrorAction Stop
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            Write-Error "Could not create drive: $($error[0].Exception.Message)"
            return $null
        }

        # Do stuff
        Write-Verbose "Checking for existing policy: $PolicyName"
        $policyExists = Test-CtxPolicy -PolicyName $PolicyName -Scope "User" -PSDriveObject $ctxDrive
        if ($policyExists) {
            switch ($Mode) {
                "Overwrite" {
                    Write-Verbose "Existing policy will be overwritten"
                    Remove-CtxPolicy -PolicyName $PolicyName -Scope User -PSDriveObject $ctxDrive
                }
                "Merge" {
                    Write-Error "Not yet implemented"
                    return $null
                }
                "Create" {
                    Write-Warning "Will not re-create existing policy"
                    return $null
                }
            }
        }
        $newPolicyPath = Join-Path -Path "$($ctxDrive):\User" -ChildPath $PolicyName
        try {
            New-Item $newPolicyPath -ErrorAction Stop
        }
        catch [System.Management.Automation.ActionPreferenceStopException]{
            Write-Error "Could not create policy object: $($error[0].Exception.Message)"
            return $false
        }
        # Cleanup Environment
        Write-Verbose "Removing PS Drive"
        Remove-PSDrive LocalFarmGpo
    }
}

New-PrinterAssignmentPolicy -AdminAddress vcitrix201.softed.de -InputFile .\TestData\printer.json -PolicyName "DruckerTest" -Verbose -Mode Overwrite