# Bite Force — Wazuh configuration recovery bundle

These files reconstruct the configuration behaviour documented by Team Bite Force.
They are **not backups of the deleted Wazuh server** and have not been tested against
your replacement instances yet. Treat them as a starting point and validate them
against the exact Wazuh and Suricata versions you deploy.

## Contents

- `manager/local_rules.xml` — custom Wazuh rules 100101 and 100401.
- `agent/ossec.conf.fragment.xml` — agent configuration entries for FIM and log collection.
- `suricata/suricata.yaml.fragment` — settings to merge into the installed Suricata YAML.

## Important: merge, do not blindly overwrite

The Wazuh agent fragment is intentionally a fragment. Merge its `<syscheck>` and
`<localfile>` entries into the existing `/var/ossec/etc/ossec.conf`. Keep the existing
`<client>` section and any AMI-specific configuration. If the existing file already
has `<syscheck>` or `<localfile>` sections, add the entries inside those sections
rather than creating duplicate top-level sections.

Copy `manager/local_rules.xml` into the manager's local rules file, or merge its
rules into the existing `/var/ossec/etc/rules/local_rules.xml`. Preserve any existing
local rules.

The Suricata file is a merge guide, not a complete replacement for
`/etc/suricata/suricata.yaml`. Check the actual interface name using `ip -br link`;
the original lab used `ens5`.

## Reconstructed detection behaviour

| Rule | Purpose | Documented behaviour |
|---|---|---|
| 100101 | SSH repeated failures | Parent rule 5760; 5 events in 120 seconds; same source IP; level 10 |
| 550 | Account-file FIM | Stock Wazuh rule; changes to `/etc/passwd` and `/etc/shadow` |
| 554 | File added | Stock Wazuh rule; new PHP file in monitored upload directory |
| 100401 | Suricata TLS telemetry | Parent rule 86604; TLS event to destination port 443; level 8 |

Rule 100401 is intentionally described as telemetry requiring direction verification.
The team's report notes that the rule is port-based and can match other TLS traffic to
port 443. Confirm the victim is the source before describing an event as outbound.

Rules 550 and 554 are stock Wazuh rules; they are not custom rules to add to
`local_rules.xml`.

## Validation checklist

1. Confirm the installed Wazuh version and inspect whether parent rules 5760 and 86604
   exist in that version's ruleset.
2. Validate the manager rules with the Wazuh rule test utility (`wazuh-logtest`) and
   confirm both custom rules load after restarting the manager.
3. Confirm the agent is connected to the manager.
4. Confirm the agent's FIM configuration watches `/etc/passwd` and `/etc/shadow`,
   with `nodiff` protecting `/etc/shadow`.
5. Confirm Suricata is monitoring the intended interface and writing EVE JSON.
6. Confirm the agent can read `/var/log/suricata/eve.json`.
7. Re-run the four authorised lab tests and verify the expected rule IDs in the dashboard.

## Operational notes

- Do not commit credentials, private keys, API tokens, raw sensitive logs, or password hashes.
- Do not expose `/etc/shadow` contents in evidence.
- Realtime FIM and log collection depend on the installed OS, Wazuh version, permissions,
  and service configuration.
- The team's original report documents Apache access-log/decoder evidence for the HTTP
  request, not a verified custom alert for that request.
- Full L4 attribution was documented as follow-up work, not a completed detection.

## Source of reconstruction

The configuration intent and observed rule IDs are reconstructed from the Bite Force
project report supplied in this conversation. The original server's exact XML/YAML files
were not recovered.
