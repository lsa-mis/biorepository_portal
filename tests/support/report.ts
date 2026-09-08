import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import ExcelJS from "exceljs";
import { Logging, type Audit } from "@siteimprove/alfa-test-utils";

interface ReportMeta {
  route: string;
  sourceFile: string;
  url: string;
  title: string;
  conformance: string;
}

interface RuleRow {
  rule: string;
  uri: string;
  failed: number;
  cantTell: number;
  passed: number;
}

export interface ReportResult {
  artifactsGenerated: boolean;
  directory?: string;
  workbook?: string;
  rulesFailed: number;
}

const reportsRoot = "reports";

function csvCell(value: string | number): string {
  const text = String(value);
  return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function csv(rows: Array<Array<string | number>>): string {
  return `${rows.map((row) => row.map(csvCell).join(",")).join("\n")}\n`;
}

function routeSlug(route: string): string {
  const value = route.replace(/^\/+|\/+$/g, "").replace(/[^a-zA-Z0-9._-]+/g, "-");
  return value || "home";
}

function renderLog(log: Logging, depth = 0): string {
  let output = `${"  ".repeat(depth)}${log.title}\n`;
  for (const child of log.logs) output += renderLog(child, depth + 1);
  return output;
}

function githubCommandValue(value: string): string {
  return value.replace(/%/g, "%25").replace(/\r/g, "%0D").replace(/\n/g, "%0A");
}

function extractIssues(rendered: string): Array<{ title: string; occurrences: number }> {
  return rendered.split("\n").flatMap((line) => {
    const match = line.match(/^\s*\d+\.\s+(.+?)\s+\((\d+)\s+occurrence/);
    return match ? [{ title: match[1], occurrences: Number(match[2]) }] : [];
  });
}

function styleHeader(row: ExcelJS.Row): void {
  row.eachCell((cell) => {
    cell.font = { bold: true, color: { argb: "FFFFFF" } };
    cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "356854" } };
    cell.alignment = { vertical: "middle", wrapText: true };
  });
}

async function writeWorkbook(
  path: string,
  meta: ReportMeta,
  generatedAt: string,
  rules: RuleRow[],
  rulesFailed: number,
  occurrencesFailed: number,
): Promise<void> {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "Biorepository accessibility CI";
  workbook.created = new Date(generatedAt);

  const summary = workbook.addWorksheet("Summary");
  summary.columns = [{ width: 34 }, { width: 74 }];
  summary.addRow(["Accessibility audit", meta.route]);
  summary.getRow(1).font = { bold: true, size: 15, color: { argb: "356854" } };
  summary.addRows([
    ["Verdict", rulesFailed === 0 ? "PASS" : "FAIL"],
    ["Page", meta.url],
    ["Source", meta.sourceFile],
    ["Standard", meta.conformance],
    ["Generated", generatedAt],
    ["Failed rule types", rulesFailed],
    ["Failed occurrences", occurrencesFailed],
    ["Branch", process.env.GITHUB_REF_NAME ?? "local"],
    ["Commit", process.env.GITHUB_SHA ?? "local working tree"],
  ]);
  summary.getColumn(1).font = { bold: true };
  summary.views = [{ showGridLines: false }];

  const issues = workbook.addWorksheet("Issues");
  issues.columns = [
    { header: "Rule", key: "rule", width: 18 },
    { header: "Result", key: "result", width: 18 },
    { header: "Failed", key: "failed", width: 12 },
    { header: "Needs review", key: "cantTell", width: 16 },
    { header: "Passed", key: "passed", width: 12 },
    { header: "Rule reference", key: "uri", width: 72 },
    { header: "Source", key: "source", width: 48 },
    { header: "Owner", key: "owner", width: 22 },
    { header: "Status", key: "status", width: 18 },
  ];
  styleHeader(issues.getRow(1));
  for (const rule of rules.filter((row) => row.failed > 0 || row.cantTell > 0)) {
    const row = issues.addRow({
      ...rule,
      result: rule.failed > 0 ? "Failed" : "Needs review",
      source: meta.sourceFile,
      owner: "Unassigned",
      status: "Not Started",
    });
    row.getCell("status").dataValidation = {
      type: "list",
      formulae: ['"Not Started,In Progress,Blocked,Done"'],
    };
    row.getCell("uri").value = { text: rule.uri, hyperlink: rule.uri };
  }
  issues.autoFilter = "A1:I1";
  issues.views = [{ state: "frozen", ySplit: 1, showGridLines: false }];

  const coverage = workbook.addWorksheet("Rule Coverage");
  coverage.columns = [
    { header: "Rule", key: "rule", width: 18 },
    { header: "Failed", key: "failed", width: 12 },
    { header: "Needs review", key: "cantTell", width: 16 },
    { header: "Passed", key: "passed", width: 12 },
    { header: "Reference", key: "uri", width: 76 },
  ];
  styleHeader(coverage.getRow(1));
  for (const rule of rules) {
    const row = coverage.addRow(rule);
    row.getCell("uri").value = { text: rule.uri, hyperlink: rule.uri };
  }
  coverage.autoFilter = "A1:E1";
  coverage.views = [{ state: "frozen", ySplit: 1, showGridLines: false }];

  await workbook.xlsx.writeFile(path);
}

export async function writeAccessibilityReport(
  audit: Audit,
  meta: ReportMeta,
): Promise<ReportResult> {
  const json = audit.toJSON();
  const rules: RuleRow[] = [];
  let rulesFailed = 0;
  let rulesCantTell = 0;
  let rulesPassed = 0;
  let occurrencesFailed = 0;
  let occurrencesCantTell = 0;

  for (const [uri, counts] of json.resultAggregates) {
    const rule = uri.split("/").pop() ?? uri;
    rules.push({ rule, uri, ...counts });
    occurrencesFailed += counts.failed;
    occurrencesCantTell += counts.cantTell;
    if (counts.failed > 0) rulesFailed += 1;
    else if (counts.cantTell > 0) rulesCantTell += 1;
    else if (counts.passed > 0) rulesPassed += 1;
  }
  rules.sort((a, b) => a.rule.localeCompare(b.rule, undefined, { numeric: true }));

  const rendered = renderLog(Logging.fromAudit(audit)).trimEnd();
  const issues = extractIssues(rendered);
  const generatedAt = new Date().toISOString();
  const verdict = rulesFailed === 0 ? "PASS" : "FAIL";
  const openRules = rules.filter((rule) => rule.failed > 0 || rule.cantTell > 0);
  const ruleDetails = openRules.flatMap((rule, index) => [
    `  ${index + 1}. ${rule.failed > 0 ? "[FAIL]" : "[REVIEW]"} ${rule.rule}`,
    `     Failed occurrences: ${rule.failed}`,
    `     Needs-review occurrences: ${rule.cantTell}`,
    `     Passed checks: ${rule.passed}`,
    `     Rule: ${rule.uri}`,
    `     Source: ${meta.sourceFile}`,
  ]);

  console.log(
    [
      "",
      `${verdict === "PASS" ? "✓" : "✗"} Accessibility audit ${verdict.toLowerCase()}`,
      `  Page: ${meta.url}`,
      `  Scope: ${meta.conformance}`,
      `  Failed: ${rulesFailed} rule type(s), ${occurrencesFailed} occurrence(s)`,
      `  Needs review: ${rulesCantTell} rule type(s), ${occurrencesCantTell} occurrence(s)`,
      "",
      "Granular rule results:",
      ...(ruleDetails.length > 0 ? ruleDetails : ["  No failed or indeterminate rules."]),
      "",
      rendered,
    ].join("\n"),
  );

  if (process.env.GITHUB_ACTIONS === "true") {
    for (const rule of openRules) {
      const status = rule.failed > 0 ? "failed" : "needs review";
      const detail =
        `${rule.rule} ${status}: ${rule.failed} failed, ${rule.cantTell} needs review. ` +
        `${rule.uri} — source ${meta.sourceFile}`;
      console.log(
        `::warning title=Accessibility ${rule.rule}::${githubCommandValue(detail)}`,
      );
    }
  }

  if (process.env.GITHUB_ACTIONS !== "true") {
    return { artifactsGenerated: false, rulesFailed };
  }

  const directory = join(reportsRoot, routeSlug(meta.route));
  mkdirSync(directory, { recursive: true });

  const reportJson = {
    verdict: verdict.toLowerCase(),
    generatedAt,
    engine: { name: "Siteimprove Alfa", version: json.alfaVersion },
    page: meta,
    ci: {
      branch: process.env.GITHUB_REF_NAME,
      commit: process.env.GITHUB_SHA,
      runId: process.env.GITHUB_RUN_ID,
    },
    summary: {
      rulesFailed,
      rulesCantTell,
      rulesPassed,
      occurrencesFailed,
      occurrencesCantTell,
    },
    issues,
    rules,
    outcomes: json.outcomes,
    durations: json.durations,
  };
  writeFileSync(join(directory, "report.json"), `${JSON.stringify(reportJson, null, 2)}\n`);

  writeFileSync(
    join(directory, "issues.csv"),
    csv([
      ["Page", "Issue", "Occurrences", "Verdict"],
      ...issues.map((issue) => [meta.url, issue.title, issue.occurrences, verdict]),
    ]),
  );
  writeFileSync(
    join(directory, "rules.csv"),
    csv([
      ["Rule", "Rule URI", "Failed", "Needs Review", "Passed"],
      ...rules.map((rule) => [
        rule.rule,
        rule.uri,
        rule.failed,
        rule.cantTell,
        rule.passed,
      ]),
    ]),
  );

  const markdown = [
    `# Accessibility audit — \`${meta.route}\``,
    "",
    `**Verdict: ${verdict}**`,
    "",
    `- Page: ${meta.url}`,
    `- Source: \`${meta.sourceFile}\``,
    `- Standard: ${meta.conformance}`,
    `- Failed: ${rulesFailed} rule type(s), ${occurrencesFailed} occurrence(s)`,
    `- Needs review: ${rulesCantTell} rule type(s), ${occurrencesCantTell} occurrence(s)`,
    "",
    "## Open rules",
    "",
    "| Rule | Failed | Needs review | Reference |",
    "| --- | ---: | ---: | --- |",
    ...rules
      .filter((rule) => rule.failed > 0 || rule.cantTell > 0)
      .map(
        (rule) =>
          `| ${rule.rule} | ${rule.failed} | ${rule.cantTell} | ${rule.uri} |`,
      ),
    "",
    "Automated checks do not replace keyboard, screen-reader, zoom, and usability testing.",
    "",
  ].join("\n");
  writeFileSync(join(directory, "summary.md"), markdown);

  const workbook = join(directory, "accessibility-report.xlsx");
  await writeWorkbook(
    workbook,
    meta,
    generatedAt,
    rules,
    rulesFailed,
    occurrencesFailed,
  );

  return { artifactsGenerated: true, directory, workbook, rulesFailed };
}
