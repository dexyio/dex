defmodule Dex.Cache.Adapters.ConCache do

  @behaviour Dex.Cache.Adapter

  use Dex.Common

  defmodule Supervisor do
    use DexyLib.Supervisor, otp_app: :dex
  end

  defmodule State do
    defstruct buckets: []
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end # defmacro

  def new_bucket(bucket) when is_atom(bucket) do
    new_child(bucket)
  end

  def buckets do
    Supervisor.members
  end

  def put(bucket, key, val), do: ConCache.put(bucket, key, val)
  def add(bucket, key, val), do: ConCache.insert_new(bucket, key, val)
  def get(bucket, key, default \\ nil), do: ConCache.get(bucket, key) || default
  def del(bucket, key), do: ConCache.delete(bucket, key)
  def update(bucket, key, fun), do: ConCache.update(bucket, key, fun)
  def update_existing(bucket, key, fun), do: ConCache.update_existing(bucket, key, fun)
  def get_or_store(bucket, key, fun), do: ConCache.get_or_store(bucket, key, fun)

  def size(bucket), do: ConCache.size(bucket)
  def touch(bucket, key), do: ConCache.touch(bucket, key)

  def dirty_put(bucket, key, val), do: ConCache.dirty_put(bucket, key, val)
  def dirty_add(bucket, key, val), do: ConCache.dirty_insert_new(bucket, key, val)
  def dirty_delete(bucket, key), do: ConCache.dirty_delete(bucket, key)
  def dirty_update(bucket, key, fun), do: ConCache.dirty_update(bucket, key, fun)
  def dirty_update_existing(bucket, key, fun),
      do: ConCache.dirty_update_existing(bucket, key, fun)
  def dirty_get_or_store(bucket, key, fun),
      do: ConCache.dirty_get_or_store(bucket, key, fun)

  defp new_child bucket, opts \\ nil do
    opts = opts || conf()[bucket] || conf()[:default_opts] || []
    args = [opts, [name: bucket]]
    Supervisor.start_child(:worker, ConCache, args, id: bucket)
  end

end

