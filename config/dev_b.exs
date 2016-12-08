use Mix.Config

config :riak_core,
  node: 'dev_b@127.0.0.1',
  web_port: 18198,
  handoff_port: 18199,
  ring_state_dir: 'cluster/ring_data_dir_b',
  platform_data_dir: 'cluster/data_b',
  schema_dirs: ['priv']
