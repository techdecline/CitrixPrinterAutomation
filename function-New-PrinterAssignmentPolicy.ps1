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
        [String]$Mode,

        # File Path to Citrix GPO Module psm1
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [String]
        $CtxGpoModulePath
    )

    begin {
        Add-PSSnapin Citrix*
        if (-not (Get-PSSnapin Citrix.Common.GroupPolicy -ErrorAction SilentlyContinue))
        {
            Add-PSSnapin Citrix.Common.GroupPolicy -ErrorAction Stop
        }
        Import-Module $CtxGpoModulePath
        #Import-Module "C:\Program Files\Citrix\PowerShellModules\Citrix.GroupPolicy.Commands\Citrix.GroupPolicy.Commands.psd1" -Force
    }

    process {
        # Loading Environment
        Write-Verbose "Creating Citrix Policy Drive"
        try {
            $ctxDrive = New-PSDrive -Name LocalFarmGpo -PSProvider Citrix.Common.GroupPolicy\CitrixGroupPolicy -Controller $AdminAddress -Root "\" -ErrorAction Stop -Scope Global
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            Write-Error "Could not create drive: $($error[0].Exception.Message)"
            return $null
        }

        # Do stuff
        Write-Verbose "Checking for existing policy: $PolicyName"
        $ctxGpo = Get-CtxGroupPolicy -PolicyName $PolicyName -Type "User" -DriveName $ctxDrive.Name
        try {
            if ($ctxGpo) {
                switch ($Mode) {
                    "Overwrite" {
                        Write-Verbose "Existing policy will be overwritten"
                        Remove-CtxGroupPolicy -PolicyName $PolicyName -Type User -DriveName $ctxDrive.Name
                        Write-Verbose "Creating Policy: $PolicyName"
                        $ctxGpo = New-CtxGroupPolicy -PolicyName $PolicyName -Type User -DriveName $ctxDrive.Name -ErrorAction Stop
                    }
                    "Create" {
                        Write-Warning "Will not re-create existing policy"
                        Get-PSDrive -PSProvider Citrix.Common.GroupPolicy\CitrixGroupPolicy | Remove-PSDrive
                        return $null
                    }
                }
            }
            else {
                Write-Verbose "Creating Policy: $PolicyName"
                $ctxGpo = New-CtxGroupPolicy -PolicyName $PolicyName -Type User -ErrorAction Stop
            }
        }
        catch [System.management.Automation.ActionPreferenceStopException] {
            Write-Error "Could not create policy object or Printer Assignment Objects: $($error[0].Exception.Message)"
            Get-PSDrive -PSProvider Citrix.Common.GroupPolicy\CitrixGroupPolicy | Remove-PSDrive
            return $false
        }
        
        $obj = ($ctxGpo | Get-CtxGroupPolicyConfiguration).PrinterAssignments.Assignments
        Get-PSDrive -PSProvider Citrix.Common.GroupPolicy\CitrixGroupPolicy | Remove-PSDrive
        return $obj

        <#
        $newPolicyPath = Join-Path -Path "$($ctxDrive):\User" -ChildPath $PolicyName
        try {
            New-Item $newPolicyPath -ErrorAction Stop
            $ctxGpo = Get-CtxGroupPolicy -PolicyName $PolicyName -Type "User" -DriveName $ctxDrive.Name -ErrorAction SilentlyContinue
            <#
            $printerData = get-content $InputFile | ConvertFrom-Json
            foreach ($printerRule in $printerData) {
                Write-Verbose "Adding policy for printer $($printerRule.PrinterName)"
                $currentAssignments = ($ctxGpo | Get-CtxGroupPolicyConfiguration).PrinterAssignments
                $currentAssignments
            }
            
        }
        catch [System.Management.Automation.ActionPreferenceStopException]{
            Write-Error "Could not create policy object or Printer Assignment Objects: $($error[0].Exception.Message)"
            return $false
        }
        #>
    }
}

$newPolHash = @{
    #AdminAddress = "vcitrix201"
    InputFile = "C:\Code\CitrixPrinterAutomation\TestData\printer.json"
    PolicyName = "DruckerTest2"
    Verbose = $true
    Mode = "Append"
    CtxGpoModulePath = "C:\Program Files\Citrix\Telemetry Service\TelemetryModule\Citrix.GroupPolicy.Commands.psm1"
}

New-PrinterAssignmentPolicy @newPolHash