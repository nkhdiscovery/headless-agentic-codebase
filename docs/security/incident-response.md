# Incident response

What to do when something goes wrong in production.

## Severity levels

- **SEV-1** — user data lost, exposed, or corrupted; service down for all users
- **SEV-2** — service degraded for a subset; security vulnerability in unreleased code
- **SEV-3** — known issue with workaround; minor data inaccuracy

## First responder checklist

1. **Stop the bleeding.** Roll back, disable the feature, take the service offline if needed.
2. **Communicate.** Post in the incident channel, notify affected users if SEV-1.
3. **Preserve evidence.** Capture logs, DB snapshots, network state.
4. **Assign roles.** Incident commander, comms, scribe.
5. **Time-box.** If unresolved in 1h, escalate.

## Post-incident

Within 48h of resolution:

1. Write a post-mortem in `docs/security/postmortems/YYYY-MM-DD-<slug>.md`
2. File issues for action items
3. If a security incident, draft an advisory

## Contacts

- Security: <security-contact>
- Hosting / infra: <hosting-contact>
- Founder / on-call: <on-call-contact>
