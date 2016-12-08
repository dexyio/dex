# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"


config :dex, Dex.Supervisor,
  children: [
    supervisor: :pooler_sup,
    supervisor: Dex.Service.Bot.Supervisor,
    supervisor: Dex.Cache.Adapters.ConCache.Supervisor,
    worker: {Dex.Service.Seater, _args = [[name: Dex.Service.Seater]]},
    worker: {:riak_core_vnode_master,
     _args = [Dex.Service.Vnode],
     _opts = [id: Vnode_master_worker]
    },
  ]

config :dex, Dex.JS, 
  adapter: Dex.JS.Adapters.ErlangJS,
  #adapter: Dex.JS.Adapters.ErlangV8,
  libs: [
    ## ErlangJS (SpiderMonkey 1.8)
    "es5-shim.min.js",
    "es5-sham.min.js",
    "coffee-script.min.js",
    "jsbundle_common.js",
    #"jsbundle_ml.js",
  ],
  _libs: [
    ## ErlangV8 (Google V8)
    #"coffee-script.min.js",
    "v8bundle_common.js",
    #"v8bundle_ml.js"
  ]

config :dex, Dex.Cache,
  adapter: Dex.Cache.Adapters.ConCache

config :dex, Dex.Cache.Adapters.ConCache,
  default_opts: [
    ttl: :timer.seconds(10),
    ttl_check: :timer.seconds(1),
    touch_on_read: true
  ]

config :dex, Dex.KV,
  adapter: Dex.KV.Adapters.Riak

config :dex, Dex.KV.Adapters.Riak,
  search_schemes: [
    {"schema_userdata",
        file: "priv/schemas/schema_userdata.xml"
    }
  ],
  search_indices: [
    {"idx_userdata",
        schema: "schema_userdata",
        n_val: 3
    }
  ],
  bucket_types: [
    {"userdata",
        allow_mult: false,
        search_index: "idx_userdata",
        n_val: 3
    }
  ]

config :dex, Dex.Service.Seater, [
  total_seats: 1000,
]

config :dex, Dex.Service.Plugins, [
  core:   Dex.Service.Plugins.Core,
  user:   Dex.Service.Plugins.User,
  app:    Dex.Service.Plugins.App,
  json:   Dex.Service.Plugins.JSON,
  auth:   Dex.Service.Plugins.Auth,
  mail:   Dex.Service.Plugins.Mail,
]

config :dex, Dex.Service.Plugins.Mail, [
  adapter: Bamboo.MailgunAdapter,
  api_key: "your-api-key",
  domain: "your-domain",
]

# pooler
config :pooler, :pools, [
  [
    name: Dex.KV,
    group: :riak,
    max_count: 100,
    init_count: 10,
    start_mfa: {Dex.KV, :start_link, []}
  ],
  [
    name: Dex.JS,
    group: :js,
    max_count: 100,
    init_count: 10,
    start_mfa: {Dex.JS, :start_link, []}
  ]
]

config :pooler, :backup, [
]

config :sasl,
  errlog_type: :error

config :riak_core,
  web_port: 18098,
  handoff_port: 18099,
  handoff_ip: '127.0.0.1',
  ring_state_dir: 'cluster/ring_data_dir',
  platform_data_dir: 'cluster/data',
  platform_log_dir: 'cluster/log',
  sasl_error_log: './log/sasl-error.log',
  sasl_log_dir: './log/sasl',
  schema_dirs: ['priv']

config :lager,
  error_logger_hwm: 5000

# Imports new or overrides configs
# $ MIX_ENV=foo iex -S mix
import_config "#{Mix.env}.exs"
import_config ".secret.exs"
