# RIPE NCC — full endpoint reference

Four independent surfaces. Different hostnames, different owners inside the NCC,
different auth.

| Surface | Base URL |
|---|---|
| Database REST API | `https://rest.db.ripe.net` (test: `rest-test.db.ripe.net`, client-cert: `rest-cert.db.ripe.net`) |
| RDAP | `https://rdap.db.ripe.net` |
| RIPEstat Data API | `https://stat.ripe.net/data` |
| RPKI Management API | `https://my.ripe.net/api/rpki` (pilot: `localcert.ripe.net/api/rpki`) |

---

## 1. Database REST API

XML by default. Get JSON with `Accept: application/json` or by appending `.json`
to the path. `text/plain` also available. Responses are UTF-8; objects are stored
latin-1, so UTF-8 input is converted on the way in. HTTPS mandatory for writes.

### Lookup

```
GET /{source}/{objectType}/{key}
```

```bash
curl 'https://rest.db.ripe.net/ripe/mntner/RIPE-DBM-MNT'
curl -H 'Accept: application/json' \
  'https://rest.db.ripe.net/ripe/inetnum/193.0.0.0%20-%20193.0.7.255'
```

`source` is `ripe`, `test`, or a GRS mirror name. Params: `unfiltered` (return
normally-filtered attributes such as `e-mail:`; needs auth), `unformatted`
(preserve whitespace). Spaces in primary keys must be URL-encoded.

### Search

```
GET /search?source={source}&query-string={query}
```

| Param | Meaning |
|---|---|
| `query-string` | search term (mandatory) |
| `source` | one or more sources, default RIPE |
| `type-filter` | restrict to object types (repeatable) |
| `inverse-attribute` | inverse lookup — `org`, `mnt-by`, `admin-c`, … |
| `flags` | whois flags — `no-filtering`, `no-referenced`, `r`, `B`, … |
| `include-tag` / `exclude-tag` | filter by object tag |
| `limit` / `offset` | pagination |
| `resource-holder` | include holder org |
| `abuse-contact` | include resolved abuse contact |
| `roa-check` | **annotate results with RPKI ROA validity** |
| `managed-attributes` | mark RIPE-managed attributes |

```bash
curl 'https://rest.db.ripe.net/search?source=ripe&type-filter=inetnum&inverse-attribute=org&query-string=ORG-RIEN1-RIPE'

# route objects that disagree with the ROAs
curl -H 'Accept: application/json' \
  'https://rest.db.ripe.net/search?source=ripe&type-filter=route&roa-check=true&query-string=193.0.0.0/21'
```

### Other reads

```bash
curl 'https://rest.db.ripe.net/metadata/sources.json'          # RIPE, TEST, *-GRS
curl 'https://rest.db.ripe.net/metadata/templates/person.xml'  # required attributes
curl 'https://rest.db.ripe.net/abuse-contact/AS3333'
curl 'https://rest.db.ripe.net/geolocation?ipkey=10.0.0.0'
curl 'https://rest.db.ripe.net/ripe/aut-num/AS3333/versions'
curl 'https://rest.db.ripe.net/ripe/aut-num/AS3333/versions/2'
```

### Authentication

1. **API key** — created at <https://apps.db.ripe.net/db-web-ui/api-keys> while
   logged into RIPE NCC Access. Name + mandatory expiry (**max 1 year**),
   optionally pinned to one `mntner`. Shown **once**. Sent as HTTP **Basic**:
   the key has an id part and a secret part, usable as ordinary
   username/password.
   ```bash
   curl -H 'Authorization: Basic <b64 keyid:secret>' \
     'https://rest.db.ripe.net/ripe/person/PP1-RIPE?unfiltered'
   ```
2. **Maintainer password** via Basic — legacy, prefer API keys.
3. **Client certificate** matched against the `mntner`'s `key-cert` attributes,
   via `rest-cert.db.ripe.net`.
4. **RIPE NCC Access SSO cookie** — browser flows.

### Create / update / delete

```bash
curl -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' \
  -H 'Authorization: Basic <key>' --data @object.json \
  'https://rest.db.ripe.net/ripe/person'

curl -X PUT -H 'Content-Type: application/xml' -H 'Authorization: Basic <key>' \
  --data @object.xml 'https://rest.db.ripe.net/ripe/person/PP1-RIPE'

curl -X DELETE -H 'Authorization: Basic <key>' \
  'https://rest.db.ripe.net/ripe/person/PP1-RIPE?reason=cleanup'
```

- `PUT` **replaces the whole object** — read, edit, write back.
- **`?dry-run`** validates without committing. Use it in CI.
- `?reason=` is DELETE-only.
- Updates take **up to ~10 s** to become queryable.

**Status codes:** `200` ok · `400` malformed · `401` bad credentials · `403`
query limit exceeded · `404` not found · `409` integrity violation (duplicate) ·
`415` unsupported content type · `429` rate limited · `500` server error.

---

## 2. RDAP

```
https://rdap.db.ripe.net/{objectType}/{key}
```

| Path | Example |
|---|---|
| `/ip/{addr or prefix}` | `/ip/2001:67c:2e8::/48` |
| `/autnum/{asn}` | `/autnum/3333` |
| `/domain/{rdns}` | `/domain/193.0.6.139.in-addr.arpa` |
| `/entity/{handle}` | `/entity/RIPE-NCC-MNT` |
| `/entities?fn=` / `?handle=` | entity search by name / handle |
| `/domains?name=` | reverse-DNS domain search |
| `/help` | service notices, supported extensions |

JSON, no auth. Non-authoritative resources return **301** to the correct RIR.

---

## 3. RIPEstat Data API

```
https://stat.ripe.net/data/{endpoint}/data.json?resource=...
https://stat.ripe.net/data/{endpoint}/meta      # methodology + version
```

Envelope on every response: `status` (`ok`/`error`/`maintenance`),
`data_call_name`, `version`, `data_call_status` (`supported`/`deprecated`/
`development`), `cached`, `process_time`, and the payload under `data`.

Params: `resource`, `sourceapp` (identify your script — expected for anything
recurring), `data_overload_limit=ignore`, `preferred_version`, `callback`.

**Limits:** no hard cap, but **8 concurrent requests per IP**; register if
regularly above **1000 requests/day**.

### rpki-validation

```
GET /data/rpki-validation/data.json?resource={asn}&prefix={prefix}
```

Backed by RIPE NCC's Routinator. `data.status` is `valid`, `invalid_asn`,
`invalid_length`, or `unknown`, plus `description`, the echoed `prefix` /
`resource`, and matching VRPs.

### Other endpoints

| Endpoint | Answers |
|---|---|
| `rpki-history` | how a prefix/ASN's RPKI state changed over time |
| `announced-prefixes` | every prefix an ASN originates |
| `routing-status` | announced space, origins, neighbour counts |
| `bgp-state` | raw RIS BGP table snapshot |
| `prefix-overview` | holder, ASN, announcement status |
| `related-prefixes` | more/less specifics announced by others |
| `as-overview` | holder + basic ASN facts |
| `looking-glass` | per-RIS-collector view |
| `whois` | whois records assembled across RIRs |

---

## 4. RPKI Management API

Drives the LIR Portal RPKI Dashboard — **hosted RPKI** only (the NCC holds the
CA key; you declare ROA intent).

**Auth:** LIR Portal → API Keys → *Resource Certification (RPKI) API*. Value
shown once. Header `ncc-api-authorization: <api-key>`. The `?key=` query form is
deprecated.

```bash
API=https://my.ripe.net/api/rpki; H='ncc-api-authorization: <api-key>'
```

**`GET /resources`** — what you may write ROAs for:
```json
{ "resources": ["84.205.64.0/19", "2001:67c:e0::/48"] }
```

**`GET /announcements`** — live announcements from your space:
```json
[{ "asn": "AS12654", "prefix": "2001:7fb:fe0f::/48",
   "visibility": 90, "currentState": "VALID", "suppressed": false }]
```
`currentState` ∈ `VALID`/`INVALID`/`UNKNOWN`; `visibility` = share of RIS
collectors seeing it.

**`GET /roas`**:
```json
[{ "asn": "AS12654", "prefix": "84.205.76.0/24", "maximalLength": 24,
   "_numberOfValidsCaused": 1, "_numberOfInvalidsCaused": 0 }]
```
`_numberOfInvalidsCaused > 0` means that ROA is invalidating a live
announcement — the audit signal.

**`POST /roas/publish`** — atomic add + delete:
```json
{ "added": [{ "asn": "AS12654", "prefix": "2001:7fb:fd03::/48", "maximalLength": "48" }],
  "deleted": [] }
```

**`POST /announcements/affected`** — dry-run the blast radius. **Always run this
before publishing on production space.**
```json
{ "asn": "AS65411", "prefix": "193.0.24.0/21", "maximalLength": 21 }
```

**Alerts:**
```bash
curl -X POST -H "$H" -H 'Content-Type: application/json' "$API/alerts" \
  -d '{"emails":["noc@example.net"],
       "routeValidityStates":["INVALID_ASN","INVALID_LENGTH","UNKNOWN"]}'
curl -X POST -H "$H" -H 'Content-Type: application/json' "$API/alerts/suppress" \
  -d '[{"asn":"AS2121","prefix":"193.0.24.0/21"}]'
# /alerts/unsuppress takes the same body
```

**Errors:** `401` wrong/missing key (empty body) · `403`
`{"error":"You are not a holder of the prefix 194.0.24.0/21"}` · `400`
`{"error":"Bad request for '/api/rpki/roas/publish' with error 'Invalid Json'"}`.

---

## 5. Repository (relying-party side)

| Protocol | URL |
|---|---|
| RRDP (RFC 8182) | `https://rrdp.ripe.net/notification.xml` |
| rsync | `rsync://rpki.ripe.net/repository` (TA: `rsync://rpki.ripe.net/ta`) |

The RIPE TAL ships built into validators — no click-through, unlike ARIN.

---

## Official docs

- <https://docs.db.ripe.net/> — queries, updates, Appendix K (API keys), RDAP
- <https://stat.ripe.net/docs/data-api/ripestat-data-api>
- <https://www.ripe.net/publications/documentation/developer-documentation/rpki-management-api/>
- <https://www.ripe.net/publications/documentation/developer-documentation/>
