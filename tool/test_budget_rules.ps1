param([string]$ProjectId = 'expenz-4f7ab')
$ErrorActionPreference = 'Stop'

# Every Firestore document lookup is mocked; no user documents are read/written.
$budgetRoot = Split-Path $PSScriptRoot -Parent
Push-Location $budgetRoot
try {
    $budgetCases = node test/firestore_budget_rules_api_cases.cjs | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Could not generate rule test cases.' }
    $budgetCredentialPath = Join-Path $env:USERPROFILE '.config/configstore/firebase-tools.json'
    if (!(Test-Path -LiteralPath $budgetCredentialPath)) {
        throw 'Sign in with firebase login before running the rule tests.'
    }
    $budgetCredentials = Get-Content -LiteralPath $budgetCredentialPath -Raw | ConvertFrom-Json
    $budgetToken = $budgetCredentials.tokens.access_token
    if (!$budgetToken) { throw 'Run firebase login and firebase projects:list to refresh credentials.' }
    $budgetHeaders = @{ Authorization = "Bearer $budgetToken" }
    $budgetBody = $budgetCases.payload | ConvertTo-Json -Depth 80 -Compress
    $budgetResponse = Invoke-RestMethod -Method Post `
        -Uri "https://firebaserules.googleapis.com/v1/projects/${ProjectId}:test" `
        -Headers $budgetHeaders -ContentType 'application/json' -Body $budgetBody
    $budgetIssues = @($budgetResponse.issues | Where-Object { $_.severity -eq 'ERROR' })
    if ($budgetIssues.Count -gt 0) {
        $budgetIssues | ForEach-Object { Write-Output $_.description }
        throw 'Rules did not compile.'
    }
    if ($budgetResponse.testResults.Count -ne $budgetCases.names.Count) {
        throw 'Rules API did not return all test results.'
    }
    $budgetFailures = 0
    for ($budgetIndex = 0; $budgetIndex -lt $budgetCases.names.Count; $budgetIndex++) {
        $budgetResult = $budgetResponse.testResults[$budgetIndex]
        if ($budgetResult.state -ne 'SUCCESS') {
            $budgetFailures++
            Write-Output "FAIL $($budgetCases.names[$budgetIndex])"
            $budgetResult.debugMessages | ConvertTo-Json -Depth 10 | Write-Output
        }
    }
    if ($budgetFailures -gt 0) { throw "$budgetFailures rule checks failed." }
    Write-Output "$($budgetCases.names.Count) fully mocked Firebase rule checks passed."
} finally {
    Pop-Location
}
