use Mix.Config

config :riak_core,
  node: 'dev_a@127.0.0.1',
  web_port: 18098,
  handoff_port: 18099,
  ring_state_dir: 'cluster/ring_data_dir_a',
  platform_data_dir: 'cluster/data_a',
  schema_dirs: ['priv']
