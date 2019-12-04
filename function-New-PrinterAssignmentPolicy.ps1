function New-PrinterAssignmentPolicy {
    [CmdletBinding()]
    param (
        # Delivery Controller IP or Hostname
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Connection $_})]
        [string]$AdminAddress,

        # Input File with existing Printer Assignment Settings
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({Test-Path $_})]
        [ValidatePattern("^*.\.json$")]
        [string]$InputFile,

        # Policy Name
        [Parameter(Mandatory)]
        [string]$PolicyName,

        # Overwrite parameter to re-create existing policies
        [Parameter(Mandatory=$false)]
        [switch]$Overwrite
    )

    begin {

    }

    process {

    }

    end {

    }
}