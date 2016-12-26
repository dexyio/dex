use Mix.Config

#
# Bucket indexes
#
g_CORE_BUCKET_IDX_START = 200
g_CORE_BUCKET_IDX_END = 209

g_PLUGIN_BUCKET_IDX_START = 210
g_PLUGIN_BUCKET_IDX_END = 219

g_CORE_BUCKET_IDX = [
  :USER,
  :APP,
] |> Enum.with_index(g_CORE_BUCKET_IDX_START)

g_PLUGIN_BUCKET_IDX = [
  :KV,
] |> Enum.with_index(g_PLUGIN_BUCKET_IDX_START)


(g_CORE_BUCKET_IDX |> Enum.at(g_CORE_BUCKET_IDX_END)) && throw :core_buckets_exceeded
(g_PLUGIN_BUCKET_IDX |> Enum.at(g_PLUGIN_BUCKET_IDX_END)) && throw :plugin_buckets_exceeded

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
# Lager
#
config :lager,
  error_logger_hwm: 5000,
  handlers: [
    lager_console_backend: :debug,
  ]
