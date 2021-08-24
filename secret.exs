use Mix.Config

config :pleroma, Pleroma.Web.Endpoint,
   http: [ ip: {0, 0, 0, 0}, ],
   url: [host: "localhost", scheme: "http", port: 4000],
   secret_key_base: "QHGdmWPAXj2h1NsTnfW/a9YZ508U9Y0CasyLeKt3uKITtF1S6lt5AGOcHVjfYmLI"

config :pleroma, :instance,
  name: "Pleroma",
  email: "admin@email.tld",
  limit: 5000,
  registrations_open: true

config :pleroma, :media_proxy,
  enabled: false,
  redirect_on_failure: true,
  base_url: "https://cache.domain.tld"

# Configure your database
config :pleroma, Pleroma.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "pleroma",
  password: "pleroma",
  database: "pleroma",
  hostname: "postgres",
  pool_size: 10

config :web_push_encryption, :vapid_details,
  subject: "mailto:administrator@example.com",
  public_key: "BF8JvIU7kTBNHTZWRdpqSka6EX64qWVAa8MOFr6VStHmDEGkhPe2WiQGF6x7FcgLvDBSrsgNnTOVw3UVWHZSFxs",
  private_key: "HU0tjymRBa4rslPkeNAcJAzFojq4USOrJ49PfuQICgQ"

config :pleroma, Oban,
  repo: Pleroma.Repo,
  log: false,
  queues: [],
  plugins: [Oban.Plugins.Pruner],
  crontab: []
