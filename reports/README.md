# Accessibility reports

The accessibility workflow creates one directory per audited route containing:

- `accessibility-report.xlsx` — remediation workbook
- `summary.md` — human-readable audit summary
- `report.json` — machine-readable evidence
- `issues.csv` — issue summary for spreadsheet tools
- `rules.csv` — Alfa rule-level results

Generated report directories are ignored by Git and uploaded by GitHub Actions.
