defmodule Dex.Digraph do

  def new(type \\ []) do
    :digraph.new(type)
  end

  def delete(graph) do
    :digraph.delete(graph)
  end

  def new_node(graph) do
    :digraph.add_vertex(graph)
  end

  def new_node(graph, node, label \\ nil) do
    if exist_node?(graph, node),
    do: :error,
    else: :digraph.add_vertex(graph, node, label)
  end

  def put_node(graph, node, label \\ nil) do
    :digraph.add_vertex(graph, node, label)
  end

  def put_nodes(graph, nodes) do
    for n <- nodes, do: put_node(graph, n)
  end

  def del_node(graph, node) do
    :digraph.del_vertex(graph, node)
  end

  def del_nodes(graph, nodes) do
    :digraph.del_vertices(graph, nodes)
  end

  def in_edges(graph, node) do
    :digraph.in_edges(graph, node)
  end

  def out_edges(graph, node) do
    :digraph.out_edges(graph, node)
  end

  def set_node(graph, old_node, new_node, label \\ nil) do
    in_nodes = in_nodes(graph, old_node)
    out_nodes = out_nodes(graph, old_node)
    del_node(graph, old_node)
    put_node(graph, new_node)
    for n <- in_nodes, do: new_edge(graph, n, new_node, label)
    for n <- out_nodes, do: new_edge(graph, new_node, n, label)
  end

  def new_edge(graph, from, to, label \\ nil) do
    case :digraph.add_edge(graph, from, to, label) do
      {:error, {reason_atom, _item}} ->
        {:error, reason_atom}
      edge ->
        edge
    end
  end

  def put_edge(graph, edge, from, to, label \\ nil) do
    case :digraph.add_edge(graph, edge, from, to, label) do
      {:error, {:bad_edge, _item}} ->
        new_edge(graph, from, to, label)
      {:error, {reason_atom, _item}} ->
        {:error, reason_atom}
      edge ->
        edge
    end
  end

  def connected?(graph, from, to) do
    from in in_nodes(graph, to)
  end

  def connect(graph, from, to, label \\ nil) do
    new_edge(graph, from, to, label)
  end

  def ensure_conn(graph, from, to, label \\ nil) do
    unless connected?(graph, from, to),
      do: connect(graph, from, to, label)
  end

  def reconnect(graph, conn, from, to, label \\ nil) do
    put_edge(graph, conn, from, to, label)
  end

  def exist_node?(graph, key) do
    node(graph, key) && true || false
  end

  def edge(graph, edge), do: :digraph.edge(graph, edge) 

  def edge(graph, edge, :from) do
    edge = edge(graph, edge)
    edge && elem(edge, 1) || nil
  end

  def edge(graph, edge, :to) do
    edge = edge(graph, edge)
    edge && elem(edge, 2) || nil
  end

  def edge(graph, edge, :label) do
    edge = edge(graph, edge)
    edge && elem(edge, 3) || nil
  end

  def node(graph, node), do: :digraph.vertex(graph, node) || nil

  def node(graph, node, :label) do
    node = node(graph, node)
    node && elem(node, 1)
  end

  def nodes(graph) do
    :digraph.vertices(graph)
  end

  def in_nodes(graph, node) do
    :digraph.in_neighbours(graph, node)
  end

  def out_nodes(graph, node) do
    :digraph.out_neighbours(graph, node)
  end

  def in_count(graph, node) do
    :digraph.in_degree(graph, node)
  end

  def out_count(graph, node) do
    :digraph.out_degree(graph, node)
  end

  def sort_nodes(graph) do
    nodes(graph) |> Enum.sort
  end

end

