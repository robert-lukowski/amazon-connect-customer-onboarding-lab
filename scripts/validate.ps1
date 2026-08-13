[CmdletBinding()]
param(
    [string]$CustomerKey = "demo-a"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$customerSlugPattern = '^[a-z0-9]+(?:-[a-z0-9]+)*$'

function Invoke-TerraformCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string[]]$ArgumentList
    )

    & terraform @ArgumentList
    $terraformExitCode = $LASTEXITCODE
    if ($terraformExitCode -ne 0) {
        [Console]::Error.WriteLine("$Description failed with exit code $terraformExitCode.")
        exit $terraformExitCode
    }
}

if ($CustomerKey -notmatch $customerSlugPattern) {
    [Console]::Error.WriteLine("Invalid customer key '$CustomerKey'. Expected a lowercase slug such as 'demo-a'.")
    exit 2
}

$customersRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot "customers"))
$customerConfigPath = [System.IO.Path]::GetFullPath(
    (Join-Path $customersRoot (Join-Path $CustomerKey "customer.yaml"))
)
$customersRootPrefix = $customersRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $customerConfigPath.StartsWith($customersRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    [Console]::Error.WriteLine("Customer configuration path must remain under the repository customers directory.")
    exit 2
}

if (-not (Test-Path -LiteralPath $customerConfigPath -PathType Leaf)) {
    [Console]::Error.WriteLine("Customer configuration not found: customers/$CustomerKey/customer.yaml")
    exit 2
}

Push-Location $repositoryRoot
try {
    Invoke-TerraformCommand -Description "terraform fmt check" -ArgumentList @(
        "fmt",
        "-check",
        "-recursive"
    )

    $env:TF_VAR_aws_region = "eu-central-1"
    $env:TF_VAR_customer_key = $CustomerKey

    Invoke-TerraformCommand -Description "terraform initialization" -ArgumentList @(
        "-chdir=terraform",
        "init",
        "-backend=false",
        "-input=false"
    )

    Invoke-TerraformCommand -Description "terraform validation" -ArgumentList @(
        "-chdir=terraform",
        "validate"
    )
}
finally {
    Pop-Location
}
