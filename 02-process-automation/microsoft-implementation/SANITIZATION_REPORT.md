# Sanitization report — v2

Review date: November 6, 2026.

This is an incremental revision. The existing feedback and event JSON files were copied byte-for-byte. The existing Excel KPI JSON was copied byte-for-byte under `weekly-kpi-report-workflow.json`. Only the missing Owner Report was newly sanitized. Documentation was revised in a separate v2 package; the previous package and original exports were not overwritten.

## Source inventory and output mapping

| Source ZIP | Definition inspected | Output |
| --- | --- | --- |
| `Montien_Thai_Feedback_Workflow.zip` | `Microsoft.Flow/flows/[redacted export folder ID]/definition.json` within its enclosing folder | `feedback-workflow.json` |
| `Montien_event_request_workflow(1).zip` | `Microsoft.Flow/flows/[redacted export folder ID]/definition.json` within its enclosing folder | `event-request-workflow.json` |
| `Montien_Thai_Weekly_Owner_Report_Workflow(1).zip` | `Microsoft.Flow/flows/[redacted export folder ID]/definition.json` within its enclosing folder | `weekly-owner-report-workflow.json` |
| `Montien_Thai_Weekly_KPI_Report.zip` | `Microsoft.Flow/flows/[redacted export folder ID]/definition.json` within its enclosing folder | `weekly-kpi-report-workflow.json` |

Each archive contained one actual definition. Identification used its display name, triggers, connector operations, and actions, not just the ZIP filename. The four complete definitions were inspected, including nested branches, expressions, HTML email bodies, metadata, recurrence settings, and connector references. The prior review parsed the five JSON members in each of the first three archives, including manifests and API/connection maps. This revision inspected the newly attached Owner Report definition; companion files are not included in the output. Non-JSON archive metadata was excluded, not certified or republished.

The original ZIP files were read only. SHA-256 checks confirmed their bytes remained unchanged. The new `Montien_Thai_Sanitized_Workflows_v2.zip` contains only four sanitized JSON files, README, and this report. Checksums also confirmed that the previous package and its individual files remained unchanged. It excludes original archives, manifests, API maps, connection maps, private replacement maps, scripts, and macOS metadata.

## Detected information and treatment

| Workflow | Sensitive categories addressed | Preservation and limitations |
| --- | --- | --- |
| Guest Feedback | Account/tenant/flow/connection IDs, school recipient email, Forms/question IDs, SharePoint site/list, edit timestamps | Previous sanitized file unchanged. Form bindings and SharePoint references require configuration. Dynamic guest fields and rating logic retained. |
| Event Request Approval | Account/tenant/flow/connection IDs, approver email, Forms/question IDs, SharePoint site/list, edit timestamps | Previous sanitized file unchanged. Approval recipient, form mappings, connectors, and list require configuration. All branches and guest notifications retained. |
| Weekly Owner Report | Account/tenant/flow/connection IDs, owner email, SharePoint site and both list IDs, edit timestamps | Newly replaced with consistent placeholders, including the same feedback/event list placeholders used by those workflows. All date filters, status filters, six count expressions, pagination settings, schedule, and dependencies retained. SharePoint connections/resources and recipient require configuration. |
| Weekly KPI Report | Account/tenant/flow/connection IDs, recipient email, workbook drive/file/table IDs, workbook paths, personal dashboard link, edit timestamps | Existing JSON unchanged under its new filename. Excel resource binding, connectors, recipient, and link require configuration. HTML-table generation retained. |

The following category-level details apply across the package:

| Category | Treatment |
| --- | --- |
| School email used as manager, approver, and owner | Replaced with `manager@example.com` for feedback/event workflows and `owner@example.com` for reporting. These represent roles; they do not assert different original account holders. |
| Creator account ID, tenant ID, last-modifying user ID | Replaced with neutral user/tenant placeholders consistently. |
| Flow IDs and flow resource paths | Replaced flow ID segments while preserving generic Microsoft provider paths. |
| Physical connection IDs/names | Replaced under `properties.connectionReferences`; retained logical connector aliases, including the two distinct Forms aliases in the event flow. |
| SharePoint site URL and two list IDs | Replaced with an example-domain site URL and distinct feedback/event list placeholders. |
| Two Forms IDs and form-question IDs | Replaced Forms IDs and all five feedback/nine event question identifiers, including those embedded in expressions and HTML templates. |
| Workbook drive ID, file IDs, table ID | Replaced Excel resource identifiers, including metadata keys and the table metadata reference. |
| Workbook folder/file paths and personal dashboard sharing URL | Replaced with example paths and an example-domain link; removed the original personal path and sharing query string. |
| Edit-history timestamps | Replaced `clientLastModifiedTime` and `connectionKeySavedTimeKey` with `EXAMPLE_METADATA_TIMESTAMP`. Operational recurrence timestamps were retained. |
| Tokens, authorization headers, API keys, passwords, credential values | No literal values of these types were detected in the definitions. The dashboard sharing URL was treated as potentially access-bearing and replaced in full. Empty authentication defaults and generic parameter-reference expressions were preserved. |
| Guest/test-record personal data | No embedded guest records or sample personal payloads were detected in the definitions. Dynamic guest-name, email, date, comment, and approval-response references were preserved as logic, not actual personal values. |

No JSON fields, actions, conditions, or branches were deleted. Private values were substituted, including two workbook metadata keys. The original export envelope was retained to show connector configuration without including companion export maps.

Preserved technical content includes the Microsoft schema URL, generic API/provider paths, connector/operation names, SharePoint column names, action names, dependencies, boolean flags, thresholds, status strings, integer conversions, HTML templates, and operational recurrence fields. “Montien”/“Montien Thai” branding and workflow display names remain intentionally because this is the requested named project.

## Expression changes and nonfunctional sections

Form expressions retain their original functions and structure; only opaque question identifiers within `body/...` paths became descriptive `EXAMPLE_FIELD_*` keys. Field meanings were inferred from their destination SharePoint columns and the rating/party-size Compose actions. The `Title` source is also used as the guest name in email templates. The underlying Forms schemas were not supplied.

For example, rating and party-size lookups now use `body/EXAMPLE_FIELD_RATING` and `body/EXAMPLE_FIELD_PARTY_SIZE`. All references to each original field were replaced consistently. The dynamic trigger response ID expression `@triggerOutputs()?['body/resourceData/responseId']` contains no fixed account value and was retained. Dynamic created-item IDs and approval response/comment expressions were also retained.

Placeholders prevent real Forms subscription/response lookup, SharePoint list operations, Excel resource lookup, connector authentication/binding, approval assignment, recipient delivery, and dashboard navigation until reconfigured. Identity and edit-history metadata are illustrative; timestamp placeholders are not date-time values. JSON syntax validation is not deployment/schema validation. No live flow was executed, email sent, approval started, or GitHub content published.

## Validation evidence

Each output was serialized and independently reparsed with Python's JSON parser. A reversible, one-to-one substitution map was applied per workflow. Reversing only the authorized substitutions reproduced the complete original parsed JSON exactly, including object/list structure, all values, branch nesting, expressions, connector configuration, and dependencies. This proves preservation relative to the exported source, not that the source is operationally correct. Formatting changed to indented UTF-8 JSON.

| Output | JSON syntax | Triggers | Actions, including conditions/loops | Conditions | Loops | `runAfter` dependency edges | Changed scalar/key locations |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `feedback-workflow.json` | Passed | 1 | 8 | 1 | 0 | 5 | 27 |
| `event-request-workflow.json` | Passed | 1 | 13 | 2 | 1 | 7 | 34 |
| `weekly-kpi-report-workflow.json` | Passed | 1 | 3 | 0 | 0 | 2 | 17 |
| `weekly-owner-report-workflow.json` | Passed | 1 | 7 | 0 | 0 | 6 | 14 |

Counts match the originals. Distinct substituted source values per workflow: 16 feedback, 21 event, 14 KPI, and 10 Owner Report. Repeated occurrences were all replaced. The Owner Report has four Query/filter actions (not If condition branches), two SharePoint GetItems actions, and one email action.

This revision reparsed all four JSON outputs and compared the three existing files byte-for-byte against the previously validated deliverables. The KPI rename changed no bytes. Applying the retained substitution maps to the original definitions reproduced all three existing outputs. Reversing the new Owner Report substitutions reproduced its complete original parsed definition. No original action, expression, comparison operator, dependency, or recurrence field was removed or redesigned.

A second inspection checked serialized output and embedded strings for email addresses, URLs, hyphenated GUIDs, Forms question IDs, known source values, institutional/personal names and domains, resource IDs, paths, credential-like keys, authentication expressions, and email-template content. No original mapped sensitive value remained. No GUIDs or original opaque form-question identifiers remained. The only email literals were the two example addresses; URL literals were the generic Microsoft workflow schema and example-domain links. Authentication fields contain parameter references, and the secure-object default is empty. All JSON keys and values were included in replacement; workbook metadata keys were checked as well.

## Existing implementation differences and manual review

1. **KPI report scope:** The flow reads an Excel table and emails its returned rows as HTML. It has no previous-seven-days filtering, feedback/event retrieval, or reporting calculations. The workbook was not included, so its data, formulas, and upstream preparation were not audited.
2. **KPI timing:** `recurrence` and `evaluatedRecurrence` both specify `Week`, interval `"1"`, Monday, and start time `2026-10-11T12:00:00.000Z`. Neither contains a time zone or explicit schedule hours/minutes. The export does not establish Monday at 9 AM Eastern. These operational values were left unchanged.
3. **Reporting version fields:** `contentVersion` is the literal string `"undefined"` in both reporting sources and remains so. Successful JSON parsing does not establish that Power Automate will accept it.
4. **Feedback condition:** The original test is integer rating `<= @2`, rather than explicitly equal to 1 or 2. It matches the stated rule if input is constrained to a 1–5 scale. Form validation was not available for inspection; out-of-range values would follow the existing comparison.
5. **Event approval payload:** The approval details field is a static sentence listing desired request details, not expressions inserting those details. This was preserved. The decision checks exactly `Approve`; its other branch is `Declined`. The declined update prefixes the occasion with `/`, and the decline notification loops through approval responses. These are original behaviors, not sanitization changes.
6. **Retained context:** Project branding, display names, generic business column names, message wording, and the operational schedule can still identify the academic project. Review whether that context is appropriate for your public portfolio. No affiliation or endorsement is asserted.
7. **Scope of privacy review:** No detected private identifiers remain under the documented checks; this is not an unconditional guarantee of anonymity or security. Review the five final files before publication. Screenshots, workbook data, Forms, SharePoint records, flow run history, and any other repository files are outside this review and require their own inspection. Original ZIP exports and private replacement maps must not be added to the public package.


## Newly included Owner Report: exact implementation and schedule

The attachment's actual filename includes `(1)`; it is the missing export described in the request. Its display name is `Montien Weekly Owner Report` and it uses SharePoint, not Excel.

Execution order follows `runAfter`: `Event_Items` → `Feedback_Items` → `Follow_Up_Items` → `Approved_Items` → `Declined_Items` → `Pending_Items` → `Send_an_email_(V2)`. All six dependency edges are unchanged, even though JSON key order places the email action earlier in the object.

- Both SharePoint `GetItems` queries build the OData filter using `concat`, `formatDateTime`, `addDays(utcNow(), -7)`, and `utcNow()`: inclusive lower bound on `Created`, exclusive upper bound. The queries run sequentially and calculate their own current time, so their windows may differ slightly. These are rolling creation-date windows, not calendar weeks or visit/event-date filters.
- Both queries retain `runtimeConfiguration.paginationPolicy.minimumItemCount: 5000`. No guarantee of complete counts beyond connector/pagination limits is established by this review.
- `Follow_Up_Items` retains `@equals(item()?['Follow_Up'],true)`.
- The three event filters retain exact `Status.Value` comparisons for `Approved`, `Declined`, and `Pending`.
- The HTML email retains six `length(...)` expressions: the two retrieved arrays and four filtered arrays. It summarizes counts, not individual guest details. Unknown status values can be part of the total without appearing in those three status counts.
- `recurrence` and `evaluatedRecurrence` remain identical to the source: weekly interval `"1"`, Monday, start time `2026-10-07T13:00:00.000Z`, no `timeZone`, and no explicit hours/minutes. The start date itself is a Wednesday; it is preserved as the supplied anchor, while Monday is the configured weekday. This review does not assert the first actual firing time.
- 13:00 UTC converts to 09:00 EDT (UTC−4) and 08:00 EST (UTC−5). Python's `America/New_York` time-zone database verified representative summer and winter conversions. This configuration does not explicitly preserve 9 AM Eastern through daylight-saving transitions. No schedule correction was made.

Only identifiers, the owner email, site URL, and edit-history timestamps changed in this new definition. No reporting expression required alteration. The Owner Report's generic authentication parameter references and empty SecureObject default contain no embedded credential. No literal guest records, passwords, API keys, authorization headers, or tokens were detected in the definition.

## Final v2 review boundaries

All four outputs passed JSON parsing, source correspondence, structural preservation, and second-pass identifier checks. The final scan covered keys, ordinary values, embedded expressions, and HTML strings for known replaced values, emails, GUIDs, opaque resource/question IDs, private URLs, and credential patterns. Only example email addresses, example-domain URLs, and the generic Microsoft schema URL remain as literal addresses/URLs.

Project branding, display names, business column names, message wording, and original operational start times intentionally remain in all relevant files. Review that public project context before publication. Generic guest-field references are not stored guest records, but future screenshots, runs, data exports, or populated payloads must be reviewed separately. These checks do not establish absolute anonymity, Power Automate schema acceptance, connector validity, live scheduling, or successful execution. No live records, workbook contents, external Forms/SharePoint schemas, or run histories were inspected. The four workflows were not deployed or executed, and nothing was published to GitHub.
