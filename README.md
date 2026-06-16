# Weather Forecast

Takes an address, resolves it to a postal code, and shows the current forecast.
Results are cached for 30 minutes per postal code, with a badge showing whether a
result was served fresh or from cache. Works worldwide and is localized for
English (°F) and Brazilian Portuguese (°C). No database and no API keys required.

## Running with Docker

**Development** (live reload):

```bash
docker compose up
```

App on <http://localhost:3000>. Use the EN / PT-BR switch or `?locale=pt-BR`.

**Tests:**

```bash
docker compose run --rm web bundle exec rspec
```

## Design decisions

- **Service objects + value objects** (`app/services/weather/`): `Geocoding`
  (address → postal code + coordinates), `Client` (Open-Meteo), `ForecastService`
  (orchestration + caching). Immutable `Data.define` objects flow between them.
- **No Active Record** — nothing is persisted; the only state is the cache, so
  setup stays minimal.
- **Open-Meteo + Nominatim** — both keyless, so the app runs with no credentials,
  and querying by coordinates makes it global rather than US-only.
- **Two-layer cache** — geocoding cached 1 day (stable), forecast cached 30 min
  per postal code (the requirement). The "from cache" flag is computed with an
  explicit `read`-then-`write`, since `fetch` can't report a hit/miss.
- **i18n** — UI fully localized (en/pt-BR); temperature unit follows the locale,
  and the cache key includes the unit so a locale switch never shows a wrong unit.
- **Hotwire** — the result loads into a Turbo Frame (no full reload, URL stays
  shareable); a small Stimulus controller handles the loading state.
- **Tests** — RSpec with WebMock + Geocoder test mode (unit), a request spec for
  the full flow, and one VCR contract test against the real Open-Meteo response.

## Notes & next steps

- Postal code is required (it is the cache key), so a vague landmark that the
  geocoder can't resolve to one is reported as not found.
- The in-memory cache is per-process; a shared store (Redis / Solid Cache) would
  be the production choice.
- With more time: recent-searches history (a real use for a database), a unit
  toggle independent of language, and HTTP retries with backoff.
