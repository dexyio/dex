use Mix.Config

#
# Bucket Indexes
#
g_CORE_BUCKET_IDX_START = 0
g_CORE_BUCKET_IDX_END = 99

g_PLUGIN_BUCKET_IDX_START = 100
g_PLUGIN_BUCKET_IDX_END = 199

g_CORE_BUCKET_IDX = [
  :USER,
  :APP,
] |> Enum.with_index(g_CORE_BUCKET_IDX_START)

g_PLUGIN_BUCKET_IDX = [
  :KV,
] |> Enum.with_index(g_PLUGIN_BUCKET_IDX_START)


(g_CORE_BUCKET_IDX |> Enum.at(g_CORE_BUCKET_IDX_END+1)) && throw :core_buckets_exceeded
(g_PLUGIN_BUCKET_IDX |> Enum.at(g_PLUGIN_BUCKET_IDX_END+1)) && throw :plugin_buckets_exceeded


#
# Module Configuration
#
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

config :dex, Dex.Service.User,
  bucket: <<g_CORE_BUCKET_IDX[:USER]>>

config :dex, Dex.Service.App,
  bucket: <<g_CORE_BUCKET_IDX[:APP]>> 

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

config :dex, Dex.Service.Seater,
  total_seats: 1000

# Warning:
#   If the module name changes, the user code must be recompiled.
#   Because the module is determined when user code is compiled.
#   We are planning to automate this process.
config :dex, Dex.Service.Plugins,
  core:   Dex.Service.Plugins.Core,
  user:   Dex.Service.Plugins.User,
  app:    Dex.Service.Plugins.App,
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
  adapter: DexyPluginHTTP.Adapters.HTTPoison

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
  backends: [:console]

config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module]


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
    name: Dex.JS,
    group: :js,
    max_count: 100,
    init_count: 10,
    start_mfa: {Dex.JS, :start_link, []}
  ], [
    name: DexyPluginKV.Adapters.Riak,
    group: :riak,
    max_count: 100,
    init_count: 10,
    start_mfa: {DexyPluginKV.Adapters.Riak, :start_link, []}
  ]
]

config :pooler, :backup, []

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
