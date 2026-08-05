# ARIN — full endpoint reference

Read and write live on different hostnames; RPKI and IRR sit on top of the write
host.

| Surface | Base URL | Auth |
|---|---|---|
| Whois-RWS | `https://whois.arin.net/rest` | none |
| RDAP | `https://rdap.arin.net/registry` | none |
| Reg-RWS | `https://reg.arin.net/rest` | `Authorization: ApiKey` |
| RPKI REST | `https://reg.arin.net/rest/rpki` · `/rest/roa` · `/rest/aspa` | same |
| IRR REST | `https://reg.arin.net/rest/irr` | same |

**OT&E:** `https://reg.ote.arin.net` — production snapshot, feature parity,
isolated, **production API keys work**. Only the hostname changes.

**Auth header** (preferred over the `?apikey=` query form, which leaks into logs):

```
Authorization: ApiKey API-XXXX-XXXX-XXXX-XXXX
```

---

## 1. Whois-RWS — read only, `GET` only

### Direct lookups

| Resource | Path | Handle form |
|---|---|---|
| IP address | `/ip/{address}` | `192.149.252.75` |
| CIDR block | `/cidr/{addr}/{len}` | `192.149.252.0/24` |
| Network | `/net/{handle}` | `NET-…` / `NET6-…` |
| ASN | `/asn/{handle}` | `AS…` |
| Organization | `/org/{handle}` | no prefix |
| Point of Contact | `/poc/{handle}` | usually `…-ARIN` |
| Customer | `/customer/{handle}` | `C…` |
| rDNS delegation | `/rdns/{name}` | `0.192.in-addr.arpa` |

### Related-resource paths

```
/poc/{h}/orgs   /poc/{h}/asns   /poc/{h}/nets
/org/{h}/pocs   /org/{h}/asns   /org/{h}/nets
/asn/{h}/pocs
/net/{h}/pocs   /net/{h}/parent   /net/{h}/children   /net/{h}/rdns
/rdns/{name}/nets
```

### Search — matrix parameters on plural collections

Collections: `/orgs`, `/customers`, `/pocs`, `/asns`, `/nets`, `/rdns`.

```bash
curl 'https://whois.arin.net/rest/orgs;name=ARIN*'
curl 'https://whois.arin.net/rest/pocs;first=Mark;last=Kosters'
```

Keys: `handle`, `name`, `domain` (POC email domain), `first` / `middle` / `last`,
`company`, `city`, `dba`. Trailing `*` does prefix/substring matching.

### Params and formats

| Param | Effect |
|---|---|
| `showDetails=true` | inline referenced records instead of links |
| `showPocs=true` | only the POCs (org queries) |
| `showARIN=false` | exclude ARIN's own pool allocations (default `true`) |

Format via `Accept:` or extension — `.xml` (default), `.json`, `.txt`, `.html`.

**JSON is BadgerFish-mapped from XML**: `{"$": "value"}` wrappers, `@`-prefixed
attribute keys. Machine-readable, not hand-friendly. Prefer RDAP.

Data refreshes ~every 10 minutes; subject to ARIN's Whois Terms of Use.

---

## 2. RDAP

```
https://rdap.arin.net/registry/{ip|autnum|entity|domain}/{key}
```

Plain JSON, no BadgerFish, no auth, redirects to the authoritative RIR.
**Prefer this for any new read-only tooling.**

---

## 3. Reg-RWS — writes

XML payloads. Most writes are asynchronous and return a **ticket**.

### Nets

| Verb | Path | Returns |
|---|---|---|
| GET / PUT | `/rest/net/{netHandle}` | NET |
| DELETE | `/rest/net/{netHandle}` | Ticketed Request |
| PUT | `/rest/net/{netHandle}/remove` | Ticketed Request |
| GET | `/rest/net/{netHandle}/delegations` | list of Delegation |
| GET | `/rest/net/parentNet/{startIp}/{endIp}` | NET |
| GET | `/rest/net/netsByIpRange/{startIp}/{endIp}` | list of NET |
| GET | `/rest/net/mostSpecificNet/{startIp}/{endIp}` | NET |
| PUT | `/rest/net/{parentNetHandle}/reassign` | Ticketed Request |
| PUT | `/rest/net/{parentNetHandle}/reallocate` | Ticketed Request |

### POCs

| Verb | Path |
|---|---|
| GET / PUT / DELETE | `/rest/poc/{pocHandle}` |
| POST | `/rest/poc;makeLink={true\|false}` |
| PUT | `/rest/poc/{pocHandle}/phone` |
| DELETE | `/rest/poc/{pocHandle}/phone/{number};type={type}` |
| POST / DELETE | `/rest/poc/{pocHandle}/email/{email}` |

### Orgs

| Verb | Path |
|---|---|
| POST | `/rest/org` → Ticket |
| GET / PUT / DELETE | `/rest/org/{orgHandle}` |
| PUT / DELETE | `/rest/org/{orgHandle}/poc/{pocHandle};pocFunction={fn}` |

### Customers

| Verb | Path |
|---|---|
| POST | `/rest/net/{parentNetHandle}/customer` |
| GET / PUT / DELETE | `/rest/customer/{customerHandle}` |

### Delegations (reverse DNS)

| Verb | Path |
|---|---|
| GET / PUT | `/rest/delegation/{name}` |
| POST | `/rest/delegation/{name}/nameserver/{ns}?ttl={ttl}` |
| DELETE | `/rest/delegation/{name}/nameserver/{ns}` |
| DELETE | `/rest/delegation/{name}/nameservers` |

### Tickets

```
GET /rest/ticket/{n}?msgRefs={bool}
GET /rest/ticket/{n}/summary
PUT /rest/ticket/{n}
PUT /rest/ticket/{n}/ticketStatus/{status}
PUT /rest/ticket/{n}/message
GET /rest/ticket/{n}/message/{id}
GET /rest/ticket/{n}/message/{id}/attachment/{id}
GET /rest/ticket;ticketType={t};ticketStatus={s}
```

### Reports

```
GET /rest/report/whoWas/asn/{asn}
GET /rest/report/whoWas/net/{ip}
GET /rest/report/associations
GET /rest/report/reassignment/{netHandle}
```

---

## 4. RPKI REST — ROAs and ASPAs

Three RPKI flavours at ARIN: **hosted** (ARIN runs the CA — ~95% of
participants, and what this API drives), **delegated** (your own CA and
publication server over RFC 6492 up/down), and **hybrid** Repository Publication
Service (your CA, ARIN publishes).

Under hosted RPKI: ROAs have a **90-day lifespan and auto-renew**, the repository
regenerates ~every 5 min, and ARIN estimates 30–60 min to propagate. Up to
100,000 ROAs per org.

| Verb | Path | Purpose |
|---|---|---|
| POST | `/rest/rpki/{orgHandle}` | create **and** delete ROAs in one transaction |
| GET | `/rest/roa/{orgHandle}` | list ROAs |
| POST | `/rest/rpki/{orgHandle}` | create/delete ASPAs (different body) |
| GET | `/rest/aspa/{orgHandle}` | list ASPAs |

### ROA transaction payload

```xml
<rpkiTransaction xmlns="http://www.arin.net/regrws/rpki/v1">
  <roaSpecDelete>
    <roaHandle autoLink=""></roaHandle>
  </roaSpecDelete>
  <roaSpecAdd>
    <roaSpec>
      <autoLink></autoLink>
      <asNumber></asNumber>
      <name></name>
      <resources>
        <roaSpecResource>
          <autoLinked></autoLinked>
          <startAddress></startAddress>
          <cidrLength></cidrLength>
          <maxLength></maxLength>
        </roaSpecResource>
      </resources>
    </roaSpec>
  </roaSpecAdd>
</rpkiTransaction>
```

- Prefixes are `startAddress` + `cidrLength`, with `maxLength` separate — **not**
  a single `a.b.c.d/len` string.
- `autoRenewed` and `roaSpecAdd.roaSpec.roaHandle` are **server-set** — send them
  empty, read them back.
- `autoLink` / `autoLinked` drive the **IRR Auto-Manager** (since 2024-11-04):
  creating a ROA also creates the matching ARIN IRR `route`/`route6` object,
  generated without a `maxLength` to narrow hijack surface.
- **Batch deletion is API-only** — the web UI cannot do it.

### ROA listing payload

```xml
<roaSpec xmlns="http://www.arin.net/regrws/rpki/v1">
  <asNumber></asNumber>
  <name></name>
  <notValidAfter></notValidAfter>
  <notValidBefore></notValidBefore>
  <resources>
    <cidrLength></cidrLength>
    <endAddress></endAddress>
    <ipVersion></ipVersion>
    <maxLength></maxLength>
    <startAddress></startAddress>
    <autoLinked></autoLinked>
  </resources>
  <roaHandle></roaHandle>
</roaSpec>
```

`roaHandle` is what you feed back into `roaSpecDelete`.

### ASPA payloads

```xml
<!-- POST /rest/rpki/{orgHandle} -->
<rpkiTransaction>
  <aspaDelete><customerAsId></customerAsId></aspaDelete>
  <aspaAdd>
    <aspa>
      <customerAsId></customerAsId>
      <providerAsIds><providerAsId></providerAsId></providerAsIds>
    </aspa>
  </aspaAdd>
</rpkiTransaction>
```

```xml
<!-- GET /rest/aspa/{orgHandle} -->
<aspa>
  <customerAsId></customerAsId>
  <providerAsIds><providerAsId></providerAsId></providerAsIds>
</aspa>
```

### The older signed-ROA flow

ARIN historically accepted **signed ROA requests** — a pipe-delimited line
(version, timestamp, name, origin AS, validity dates, prefix, length, maxLength)
signed with the org's ROA key pair via `openssl dgst -sha256 -sign`. Still
reachable in ARIN Online for orgs that set up a ROA key pair, but the REST API
above is the supported automation path and needs **no request signing** — the API
key is the credential. A script doing `openssl` gymnastics predates this API.

---

## 5. IRR REST

| Object | Paths |
|---|---|
| `route` / `route6` | `POST`/`GET`/`PUT`/`DELETE` `/rest/irr/route/{ip}/{prefixLength}/{originAs}` |
| `aut-num` | `POST`/`GET`/`PUT`/`DELETE` `/rest/irr/aut-num/{asn}` |
| `as-set` | `POST /rest/irr/as-set?orgHandle={h}` · `GET\|PUT\|DELETE /rest/irr/as-set/{name}` |
| `route-set` | `POST /rest/irr/route-set?orgHandle={h}` · `GET\|PUT\|DELETE /rest/irr/route-set/{name}` |

Listing:

```
GET /rest/net/{netHandle}/routes
GET /rest/net/{netHandle}/routes?reassignments=true
GET /rest/org/{orgHandle}/routes
GET /rest/org/{orgHandle}/aut-nums
GET /rest/org/{orgHandle}/as-sets
GET /rest/org/{orgHandle}/route-sets
```

Payloads may be **RPSL or XML** — RPSL is easier if you already generate IRR
objects for other registries.

---

## 6. TAL and repository (relying-party side)

Straight from `arin.tal`:

```
rsync://rpki.arin.net/repository/arin-rpki-ta.cer
https://rrdp.arin.net/arin-rpki-ta.cer
```

RRDP notification: `https://rrdp.arin.net/notification.xml`.

**ARIN's TAL needs a click-through.** Download from
<https://www.arin.net/resources/manage/rpki/tal/> after accepting the **Relying
Party Agreement** (`https://www.arin.net/resources/manage/rpki/rpa.pdf`).
Routinator requires `routinator init --accept-arin-rpa`. A validator missing the
ARIN TAL reports all ARIN-region space as **`unknown`** — the classic cause of
"our RPKI filter catches nothing in North America".

---

## Official docs

- Whois-RWS — <https://www.arin.net/resources/registry/whois/rws/api/>
- RDAP — <https://www.arin.net/resources/registry/whois/rdap/>
- Reg-RWS — <https://www.arin.net/resources/manage/regrws/> · methods:
  <https://www.arin.net/resources/registry/regrws/methods/>
- RPKI REST — <https://www.arin.net/resources/manage/rpki/rpki-restful/>
- ROAs — <https://www.arin.net/resources/manage/rpki/roas/> · FAQ:
  <https://www.arin.net/resources/manage/rpki/help/faq/>
- TAL — <https://www.arin.net/resources/manage/rpki/tal/>
- IRR REST — <https://www.arin.net/resources/manage/irr/irr-restful/>
- OT&E — <https://www.arin.net/reference/tools/testing/>
