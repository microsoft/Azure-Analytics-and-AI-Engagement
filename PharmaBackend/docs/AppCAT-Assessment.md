# AppCAT Assessment

## Scope
- Project: `PharmacyBackend.csproj`
- Assessment domain: `dotnet-cloud-readiness`
- Producer: `.NET AppCAT CLI`
- Action ID: `20260625113656`
- Report file: `PharmaBackend/.github/modernize/assessment/copilot/reports/report-20260625113656/report.json`

## Summary
- Total projects assessed: `1`
- Total issues: `4`
- Total incidents: `15`
- Estimated effort: `35`

### Severity breakdown
- Mandatory: `0`
- Optional: `4`
- Potential: `11`
- Information: `0`

### Category breakdown
- Configuration: `5`
- Connection: `2`
- Cache: `4`
- Security: `4`

## Key findings
- Local configuration and connection-string migration risks were detected in `appsettings.json` and `appsettings.Development.json`.
- Cache migration considerations were detected for Redis integration in `Program.cs`.
- Security guidance incidents were detected around secret handling patterns in `Program.cs` and `Data/DbSeeder.cs`.

## Evidence artifacts
- Primary report:
  - `PharmaBackend/.github/modernize/assessment/copilot/reports/report-20260625113656/report.json`
- Engine output (latest run artifact):
  - `PharmaBackend/.github/modernize/assessment/copilot/engines/appcat/result/report.json`
- Engine execution log:
  - `PharmaBackend/.github/modernize/assessment/copilot/engines/appcat/appcat.log`

## Notes
- The report metadata status is `cancelled`, but the report includes complete findings and issue summaries that were persisted to disk.
