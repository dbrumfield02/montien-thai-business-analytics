# Montien Thai — Integrated Business Analytics and Operations System

## Microsoft Power Automate implementation — v2

This academic business analytics project demonstrates guest feedback handling, event request decisions, and scheduled KPI reporting. These files document the exported implementations; they are not an official Montien Thai service and do not imply affiliation, endorsement, or a production deployment.

**Technologies:** Microsoft Forms, SharePoint Lists, Power Automate, Outlook (Office 365 Outlook connector), Approvals, and Excel Online (Business). Excel is included because the weekly report export reads a workbook table.

## Workflows and business rules

| Workflow | Implementation in the supplied export |
| --- | --- |
| Guest Feedback | A Forms submission triggers response retrieval, integer rating conversion, a SharePoint record, and a guest acknowledgment. The condition tests rating `<= 2`: on a 1–5 scale, ratings 1 or 2 set `Follow_Up` to true and email the manager; the other branch sets it to false. |
| Event Request Approval | A Forms submission creates a SharePoint request with status `Pending`. Parties of 8 or more require manager approval. Outcome `Approve` updates the status to `Approved` and emails the guest; the other outcome branch sets `Declined` and sends guest emails with approval-response comments. Parties under 8 are automatically marked `Approved` and notified. |
| Weekly Owner Report | A weekly Monday recurrence queries SharePoint feedback and event requests created in the previous seven days, filters feedback requiring follow-up and events by Approved/Declined/Pending status, and emails six record counts to the owner. |
| Weekly KPI Report | A separate weekly Monday recurrence reads an Excel KPI table, converts the returned rows to HTML, and emails the owner with a dashboard link. |

**Owner Report schedule:** The intended rule is Mondays at 9 AM Eastern. Both exported recurrence objects specify `Week`, interval `"1"`, Monday, and `startTime: "2026-10-07T13:00:00.000Z"`, with no `timeZone` or explicit schedule hours/minutes. The UTC start-time anchor is 13:00: 9 AM Eastern during daylight saving time and 8 AM during standard time. This does not configure a year-round 9 AM Eastern schedule. The export is preserved; live scheduling was not tested.

**Owner Report calculations:** Both SharePoint queries filter `Created >= utcNow() - 7 days` and `Created < utcNow()`. These are rolling creation-date windows, not visit dates, requested event dates, or a calendar-week grouping. The email counts feedback received, feedback marked `Follow_Up = true`, event requests received, and events whose `Status.Value` is `Approved`, `Declined`, or `Pending`. The flow does not calculate Excel KPIs.

**KPI Report scope and schedule:** This separate flow emails the returned Excel table rows without seven-day filtering or aggregation calculations in the flow. Workbook preparation is outside the export. Its Monday recurrence uses start time `2026-10-11T12:00:00.000Z`, without a time zone or explicit schedule hours/minutes. It is not the SharePoint Owner Report described in the Guest Operations case study.

Other preserved implementation details: approval details contain static descriptive text rather than populated request fields; the declined-request update prefixes the occasion with `/`. See the sanitization report for these review points.

## Files

| File | Purpose |
| --- | --- |
| `feedback-workflow.json` | Sanitized guest feedback workflow. |
| `event-request-workflow.json` | Sanitized event approval workflow. |
| `weekly-owner-report-workflow.json` | Newly included SharePoint operational summary workflow. |
| `weekly-kpi-report-workflow.json` | Existing Excel-based KPI workflow, renamed from `weekly-report-workflow.json` without changing its contents. |
| `SANITIZATION_REPORT.md` | Redaction scope, validation results, limitations, and review requirements. |
| `README.md` | Project and implementation overview. |

The v2 ZIP contains only the six files listed above. The feedback and event files are unchanged; the KPI JSON is identical to the previous version under its clearer filename. The original package remains a separate backup.

Each JSON retains the source `definition.json` export envelope, with executable workflow structure under `properties.definition` and sanitized connector bindings under `properties.connectionReferences`. Generic Microsoft connector identifiers are retained. No export manifests or connection-map files are included.

## Placeholders and deployment limitations

Account-specific identifiers, recipients, form-question references, resource locations, and metadata timestamps were replaced with descriptive placeholders such as `EXAMPLE_TENANT_ID`, `EXAMPLE_FIELD_RATING`, and `manager@example.com`. `example.com` links are illustrative. “Montien Thai” remains as the requested academic project context.

**These are readable portfolio examples, not files ready for direct deployment.** Forms triggers and response mappings, SharePoint access, workbook access, email recipients, approval assignment, dashboard links, and connector bindings require valid configuration. Form-field placeholders in expressions must be mapped to actual question IDs. Authentication expressions refer to an empty secure parameter; no credentials are supplied. Review the existing implementation issues, configure the intended schedule, and test in a controlled environment before reuse.
