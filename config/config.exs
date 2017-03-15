use Mix.Config

#
# Bucket Indexes
#
bucket_idx_start = 0
bucket_idx_end = 99

plugin_bucket_idx_start = 100
plugin_bucket_idx_end = 199

bucket_idx = [
  Dex.User,
  Dex.App,
] |> Enum.with_index(bucket_idx_start)

plugin_bucket_idx = [
  DexyPluginKV
] |> Enum.with_index(plugin_bucket_idx_start)


(bucket_idx |> Enum.at(bucket_idx_end+1)) && throw :bucket_idx_exceeded
(plugin_bucket_idx |> Enum.at(plugin_bucket_idx_end+1)) && throw :plugin_buckets_exceeded


#
# Module Configuration
#
config :dex, Dex,
  compiler_options: [
    ignore_module_conflict: true
  ]

config :dex, Dex.Supervisor,
  children: [
    supervisor: :pooler_sup,
    supervisor: Dex.Bot.Supervisor,
    supervisor: Dex.Seater.Supervisor,
    supervisor: Dex.Cache.Supervisor,
    worker: {Dex.Event, _args = [[name: Dex.Event]]},
    worker: {:riak_core_vnode_master,
     _args = [Dex.Vnode],
     _opts = [id: Vnode_master_worker]
    },
  ]


config :dex, Dex.Seater.Supervisor,
  children: [
    worker: {Dex.Seater, [test: 1000], id: :test},
    worker: {Dex.Seater, [prod: 1000], id: :prod}
  ]

config :dex, Dex.User,
  bucket: <<bucket_idx[Dex.User]>>,
  event_handlers: [
    {Dex.User.EventHandler, []}
  ]

config :dex, Dex.App,
  bucket: <<bucket_idx[Dex.App]>>,
  event_handlers: [
    {Dex.App.EventHandler, []}
  ]

config :dex, Dex.Event,
  managers: [Dex.App, Dex.User]

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
  adapter: Dex.Cache.Adapters.ConCache,
  initial_buckets: [
  ]

config :dex, Dex.Cache.Adapters.ConCache,
  default_opts: [
    #ttl: :timer.seconds(60),
    #ttl_check: :timer.seconds(1),
    #touch_on_read: true
  ],
  seater: []

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
        n_val: 1
    }
  ],
  bucket_types: [
    {"userdata",
     #backend: "leveldb_mult",
        n_val: 1,
        allow_mult: false,
        last_write_wins: true,
        dvv_enabled: false,
        search_index: "idx_userdata",
    }
  ]

config :dex, Dex.Seater,
  ttl_secs: 60,
  purge_after_msecs: 10_000

# Warning:
#   If the module name changes, the user code must be recompiled.
#   Because the module is determined when user code is compiled.
#   We are planning to automate this process.
config :dex, Dex.Plugins,
  core:   Dex.Plugins.Core,
  now:    Dex.Plugins.Core,
  user:   Dex.Plugins.User,
  app:    Dex.Plugins.App,
  kv:     DexyPluginKV,
  json:   DexyPluginJson,
  http:   DexyPluginHTTP,
  mail:   DexyPluginMail,
  crypto: DexyPluginCrypto,
  datetime: DexyPluginDatetime


#
# Dexy Core Library
#
config :dexy_lib, DexyLib.JSON,
  adapter: DexyLib.JSON.Adapters.Poison


#
# Dexy Plugins
#
config :dexy_plugin_json, DexyPluginJson, []

config :dexy_plugin_json, DexyPluginHTTP,
  #adapter: DexyPluginHTTP.Adapters.HTTPoison
  adapter: DexyPluginHTTP.Adapters.Gun

config :dexy_plugin_kv, DexyPluginKV,
  adapter: DexyPluginKV.Adapters.Riak

config :dexy_plugin_kv, DexyPluginKV.Adapters.Riak, [
  userdata_bucket_type: "userdata",
  userdata_content_type: "application/dexyml",
  userdata_index: "idx_userdata",
]

config :dexy_plugin_mail, DexyPluginMail,
  adapter: DexyPluginMail.Adapters.Bamboo

config :dexy_plugin_mail, DexyPluginMail.Adapters.Bamboo,
  adapter: Bamboo.MailgunAdapter,
  api_key: "your-api-key",
  domain: "your-domain"

#
# Elixir Logger
#
config :logger,
  backends: [
    :console,
    {LoggerFileBackend, :info},
    {LoggerFileBackend, :error},
  ]

config :logger, :console,
  level: :debug,
  format: "$time [$level] $metadata$message\n",
  metadata: [:module]

config :logger, :info,
  level: :info, path: "log/info.log"

config :logger, :warn,
  level: :warn, path: "log/warn.log" 

config :logger, :error,
  level: :error, path: "log/error.log" 

#
# Erlang/OTP SASL
#
config :sasl,
  errlog_type: :error

#
# Pooler
#
config :pooler, :pools, [
  [
    name: Dex.KV,
    group: :riak,
    max_count: 100,
    init_count: 10,
    start_mfa: {Dex.KV, :start_link, []}
  ], [
    name: DexyPluginKV.Adapters.Riak,
    group: :riak,
    max_count: 100,
    init_count: 10,
    start_mfa: {DexyPluginKV.Adapters.Riak, :start_link, []}
  ]
]

config :pooler, :pools_backup, [
  [
    name: Dex.JS,
    group: :js,
    max_count: 100,
    init_count: 10,
    start_mfa: {Dex.JS, :start_link, []}
  ]
]

#
# Riak Core
#
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

#
# Lager for logging
#
config :lager,
  error_logger_hwm: 5000

# Imports new or overrides configs
# $ MIX_ENV=foo iex -S mix
import_config "#{Mix.env}.exs"
import_config ".secret.exs"
