---
name: rir-apis
description: Query and modify Regional Internet Registry data over HTTP — RIPE NCC and ARIN. Use when the task involves looking up who holds a prefix or ASN, reading or writing whois/registry objects (inetnum, aut-num, route, route6, mntner, NET, ORG, POC), RDAP, IRR objects, checking whether a BGP announcement is RPKI valid/invalid/unknown, or creating, listing and deleting ROAs and ASPAs. Triggers on RIPE, RIPEstat, RIPE Database, rest.db.ripe.net, my.ripe.net, ARIN, Whois-RWS, Reg-RWS, whois.arin.net, reg.arin.net, RDAP, RPKI, ROA, VRP, maxLength, ASPA, TAL, RRDP, route origin validation, prefix hijack checks, "is this prefix valid", "publish a ROA", "who owns this IP".
---

# RIR APIs — RIPE NCC and ARIN

Operating reference for the registry APIs. Two registries, six HTTP surfaces,
five different auth schemes. Picking the wrong surface is the usual failure —
start with the routing table below, not with a search engine.

Long-form version of this material lives in the knowledge base at
`/Users/jhl/Documents/Dev/Docs/docs/rir/` (`ripe-ncc-apis.md`, `arin-apis.md`).

## Pick the surface first

| I want to… | Use | Auth |
|---|---|---|
| Look up who holds a prefix/ASN, any registry | **RDAP** — `rdap.db.ripe.net` / `rdap.arin.net/registry` | none |
| Read/write RIPE whois objects | RIPE Database REST — `rest.db.ripe.net` | none to read, API key to write |
| Read ARIN registry records | Whois-RWS — `whois.arin.net/rest` | none |
| Write ARIN registry records | Reg-RWS — `reg.arin.net/rest` | `Authorization: ApiKey` |
| Ask "is this announcement RPKI-valid?" | RIPEstat — `stat.ripe.net/data` | none |
| Create/delete **RIPE** ROAs | RPKI Management API — `my.ripe.net/api/rpki` | `ncc-api-authorization:` |
| Create/delete **ARIN** ROAs/ASPAs | `reg.arin.net/rest/rpki` | `Authorization: ApiKey` |
| Manage ARIN IRR objects | `reg.arin.net/rest/irr` | `Authorization: ApiKey` |

**Default to RDAP for read-only lookups.** One JSON format across all five RIRs,
no auth, and non-authoritative queries return `301` to the right registry — so a
redirect-following client covers the whole address space. Reach for Whois-RWS or
the RIPE Database REST API only when you need registry-specific attributes
(`mnt-by`, `route:` objects, ARIN POC linkage) that RDAP does not model.

## Auth cheat sheet — these are all different

| Surface | Header | Notes |
|---|---|---|
| RIPE Database | `Authorization: Basic <b64 keyid:secret>` | HTTP **Basic**, not Bearer. Key from <https://apps.db.ripe.net/db-web-ui/api-keys>, **max 1-year validity**, shown once, can be pinned to one `mntner`. |
| RIPE RPKI Management | `ncc-api-authorization: <key>` | Custom header. Key from LIR Portal → API Keys → *Resource Certification (RPKI) API*. The `?key=` query form is **deprecated**. |
| ARIN (all of Reg-RWS, RPKI, IRR) | `Authorization: ApiKey API-XXXX-XXXX-XXXX-XXXX` | One key for everything. `?apikey=` still works but leaks into logs — use the header. |

## Test environments

- **ARIN OT&E — `reg.ote.arin.net`.** Production snapshot, feature parity,
  isolated, and **production API keys work there**. Rehearse every ROA
  transaction here first; only the hostname changes.
- **RIPE** — `rest-test.db.ripe.net` (writes go to the TEST source) and
  `localcert.ripe.net/api/rpki` for the RPKI pilot.

## The three things that actually bite

1. **Never publish a RIPE ROA blind.** `POST /api/rpki/announcements/affected`
   with the candidate ROA returns the live announcements it would flip to valid
   or invalid. Run it, read it, *then* publish. A too-tight `maximalLength` is
   the classic way to blackhole your own more-specifics.
2. **A validator without the ARIN TAL reports ARIN space as `unknown`, not
   `invalid`.** ARIN's TAL requires accepting the Relying Party Agreement, so it
   is not bundled like the other four — Routinator needs
   `routinator init --accept-arin-rpa`. Symptom: RPKI filters mysteriously catch
   nothing in North America.
3. **ARIN Whois-RWS JSON is BadgerFish-mapped from XML** — expect `{"$": "..."}`
   value wrappers and `@`-prefixed attribute keys. It is machine-readable, not
   human-readable. RDAP is plain JSON; prefer it.

Also worth knowing: RIPE Database updates take up to ~10 s to become visible;
RIPEstat allows **8 concurrent requests per IP** and asks you to register above
1000 req/day; ARIN hosted ROAs have a **90-day lifespan and auto-renew**, with
the repository regenerating ~every 5 min and 30–60 min to propagate.

## Recipes

**Is this announcement RPKI-valid?** (the same verdict a validating router reaches)

```bash
curl -s 'https://stat.ripe.net/data/rpki-validation/data.json?resource=3333&prefix=193.0.0.0/21' \
  | jq -r '.data.status'   # valid | invalid_asn | invalid_length | unknown
```

**Who holds this address?**

```bash
curl -s 'https://rdap.arin.net/registry/ip/192.149.252.75' | jq '.name, .handle'
curl -sL 'https://rdap.db.ripe.net/ip/193.0.0.1' | jq '.name'   # -L follows cross-RIR 301
```

**Publish a RIPE ROA, safely:**

```bash
API=https://my.ripe.net/api/rpki; H="ncc-api-authorization: $RIPE_RPKI_KEY"
NEW='{"asn":"AS64512","prefix":"203.0.113.0/24","maximalLength":24}'

curl -s -H "$H" "$API/resources"                      # 1. do we hold it?
curl -s -X POST -H "$H" -H 'Content-Type: application/json' \
  "$API/announcements/affected" -d "$NEW"             # 2. what breaks?
curl -s -X POST -H "$H" -H 'Content-Type: application/json' \
  "$API/roas/publish" -d "{\"added\":[$NEW],\"deleted\":[]}"   # 3. go
```

**Which of my RIPE ROAs are actively breaking something?**

```bash
curl -s -H "ncc-api-authorization: $RIPE_RPKI_KEY" https://my.ripe.net/api/rpki/roas \
  | jq '[.[] | select(._numberOfInvalidsCaused > 0)]'
```

**List / change ARIN ROAs:**

```bash
curl -s -H "Authorization: ApiKey $ARIN_API_KEY" https://reg.arin.net/rest/roa/EXAMPLEORG

# rehearse in OT&E, then production — identical payload
for host in reg.ote.arin.net reg.arin.net; do
  curl -X POST -H "Authorization: ApiKey $ARIN_API_KEY" \
    -H 'Content-Type: application/xml' --data @roa-txn.xml \
    "https://$host/rest/rpki/EXAMPLEORG"
done
```

**Cross-check a change:** the registry API tells you what you asked for; RIPEstat
tells you what the world sees. Verify with both.

## Going deeper

Read on demand — each is self-contained:

- `references/ripe.md` — every RIPE endpoint: Database REST CRUD and search
  parameters (incl. `roa-check`), RDAP paths, the RIPEstat endpoint catalog, the
  full RPKI Management API with JSON payloads, error codes, repository URLs.
- `references/arin.md` — Whois-RWS paths and matrix-parameter search, the
  Reg-RWS method tables, the RPKI REST XML payloads for ROAs and ASPAs, the IRR
  REST API, TAL and repository details.

Endpoint paths, header names and payload fields drift. Both references cite the
official docs — **re-check those pages before relying on an exact field name,
and never reconstruct an endpoint from memory.**
