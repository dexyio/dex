use Mix.Config

config :riak_core,
  node: 'dev_c@127.0.0.1',
  web_port: 18298,
  handoff_port: 18299,
  ring_state_dir: 'cluster/ring_data_dir_c',
  platform_data_dir: 'cluster/data_c',
  schema_dirs: ['priv']
