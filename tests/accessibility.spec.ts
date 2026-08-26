import { expect, test } from "@playwright/test";

import { Playwright } from "@siteimprove/alfa-playwright";
import { Audit, Rules, SIP } from "@siteimprove/alfa-test-utils";
import { getCommitInformation } from "@siteimprove/alfa-test-utils/git";

import { writeAccessibilityReport } from "./support/report.js";

const conformanceTarget: typeof Rules.wcag21aaFilter = (rule) =>
  Rules.wcag21aaFilter(rule) ||
  Rules.bestPracticesFilter(rule) ||
  Rules.ARIAFilter(rule);

const enforcement =
  process.env.A11Y_ENFORCEMENT === "advisory" ? "advisory" : "enforce";

const auditedPages = [
  {
    route: "/",
    sourceFile: "app/views/home/about.html.erb",
    name: "public home page",
  },
];

for (const auditedPage of auditedPages) {
  test(`${auditedPage.name} meets the accessibility gate`, async ({ page }, testInfo) => {
    const response = await page.goto(auditedPage.route, { waitUntil: "networkidle" });
    expect(response?.ok(), `Expected ${auditedPage.route} to load successfully`).toBe(true);

    const documentHandle = await page.evaluateHandle("document");
    const alfaPage = await Playwright.toPage(documentHandle);
    const audit = await Audit.run(alfaPage, {
      rules: { include: conformanceTarget },
    });

    const uploadEnabled = process.env.SI_UPLOAD_ENABLED === "true";
    const { SI_USER_EMAIL, SI_API_KEY, SI_SITE_ID } = process.env;
    const missingSecrets = [
      ["SI_USER_EMAIL", SI_USER_EMAIL],
      ["SI_API_KEY", SI_API_KEY],
      ["SI_SITE_ID", SI_SITE_ID],
    ]
      .filter(([, value]) => !value)
      .map(([name]) => name);

    if (uploadEnabled && missingSecrets.length > 0) {
      throw new Error(
        `Siteimprove upload is enabled, but these Actions secrets are missing: ${missingSecrets.join(", ")}`,
      );
    }

    const siteID = Number(SI_SITE_ID);
    if (uploadEnabled && (!Number.isInteger(siteID) || siteID <= 0)) {
      throw new Error("SI_SITE_ID must be a positive integer.");
    }

    const reportUrl =
      uploadEnabled && SI_USER_EMAIL && SI_API_KEY
        ? await SIP.upload(audit, {
            userName: SI_USER_EMAIL,
            apiKey: SI_API_KEY,
            siteID,
            commitInformation: await getCommitInformation(),
            pageTitle: await page.title(),
            pageURL: page.url(),
            testName: `Biorepository accessibility audit: ${auditedPage.route}`,
          })
        : undefined;

    if (reportUrl?.isErr()) {
      throw new Error(
        `Siteimprove upload failed: ${reportUrl.getErrUnsafe().join("; ")}`,
      );
    }

    const report = await writeAccessibilityReport(audit, {
      route: auditedPage.route,
      sourceFile: auditedPage.sourceFile,
      url: page.url(),
      title: await page.title(),
      conformance: "WCAG 2.1 AA + Best Practices + ARIA",
    });

    if (report.artifactsGenerated && report.directory && report.workbook) {
      await Promise.all([
        testInfo.attach("Accessibility workbook", {
          path: report.workbook,
          contentType:
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        }),
        testInfo.attach("Accessibility summary", {
          path: `${report.directory}/summary.md`,
          contentType: "text/markdown",
        }),
        testInfo.attach("Accessibility evidence", {
          path: `${report.directory}/report.json`,
          contentType: "application/json",
        }),
      ]);
    }

    if (enforcement === "enforce") {
      expect(
        report.rulesFailed,
        `${report.rulesFailed} Alfa rule(s) failed. Download the accessibility-reports artifact for remediation details.`,
      ).toBe(0);
    } else if (report.rulesFailed > 0) {
      console.warn(
        `Accessibility advisory mode: ${report.rulesFailed} failed rule(s) were reported without blocking this run.`,
      );
    }
  });
}
