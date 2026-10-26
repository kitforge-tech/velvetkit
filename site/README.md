# velvetkit.com

The Rails app that serves https://velvetkit.com. It installs the kit from
`../registry` the way any app would, with `bin/sync-kit` (it runs
`velvetkit:install` and `velvetkit:add --all`). The copied files are
gitignored, so the registry is the only source.

The pages build themselves from the registry:

- each component page renders that component's Lookbook preview templates
  live, next to their source
- the "Comes with" list comes from the same dependency scan `add` uses
- the arguments and slots are read from the component's Ruby

To document a component, write or improve its preview. The site picks it up.

## Running it

```bash
bun install && bundle install
bin/dev            # sync the kit, then run Rails, JS and CSS watchers
bin/rails test     # every page renders, every live example, SEO and AI endpoints
bin/ux-check       # real clicks, keys and clipboard in headless Chrome (site on :3000)
```

## Deploying

The image is built from the `Dockerfile` at the repository root. It needs
the gem and the registry as well as `site/`.

**Dokploy:** create an Application from this repository with build type
**Dockerfile**. The defaults fit: Dockerfile path `Dockerfile`, context `.`.
Then:

- Environment:
  - `SECRET_KEY_BASE`, required: generate one with `openssl rand -hex 64`.
  - `SITE_URL`, if the site isn't served at https://velvetkit.com.
- Domains: `velvetkit.com` on container port **80**, with HTTPS on. Traefik
  terminates TLS and the app trusts it (`assume_ssl`).
- Health check: the image declares one against `GET /up`.

**Kamal:** fill in the TODOs in `config/deploy.yml`, then run
`bin/kamal deploy` from `site/`. It uses the same Dockerfile.

**Anywhere else**, from the repository root:

```bash
docker build -t velvetkit-site .
docker run -p 8080:80 -e SECRET_KEY_BASE=$(openssl rand -hex 64) -e FORCE_SSL=false velvetkit-site
```

## SEO and AI

Every page has its own title, description, canonical URL and Open Graph
and Twitter cards, using `public/og.png`. The home page carries JSON-LD for
`SoftwareApplication` and `WebSite`; docs pages carry `TechArticle` and
`BreadcrumbList`. `/sitemap.xml` and `/robots.txt` are built from the
routes, and robots explicitly welcomes AI crawlers and points them at
`/llms.txt`. Component pages link their Markdown version with
`rel="alternate"`.
