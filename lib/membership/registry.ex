defmodule Membership.Registry do
  @moduledoc false

  use GenServer

  def start_link(args) do
    {:ok, pid} =
      normalize_struct_name(__MODULE__)
      |> GenServer.start_link(%{table: nil})

    GenServer.call(pid, {:init_table, args.identifier})
    {:ok, pid}
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call({:init_table, identifier}, _from, _state) do
    table = :ets.new(identifier, [:named_table, :set, :public, read_concurrency: true])
    {:reply, table, %{table: table}}
  end

  def insert(identifier, name, value) do
    :ets.insert(identifier, {name, value})
  end

  def add(identifier, name, value) do
    current =
      case lookup(identifier, name) do
        {:ok, nil} -> %{}
        {:ok, current} -> current
      end

    uniq = %{current | required_features: Enum.uniq(current.required_features ++ [value])}

    :ets.insert(identifier, {name, uniq})
  end

  def lookup(identifier, name) do
    case :ets.lookup(identifier, name) do
      [{^name, value}] -> {:ok, value}
      [] -> {:ok, nil}
    end
  end

  def lookup(name) when is_binary(name) do
    Membership.Member.Server.show(name)
  end

  def lookup(name) when is_atom(name) do
    normalize_struct_name(__MODULE__)
    |> :ets.lookup(name)
  end

  def normalize_struct_name(name) do
    name
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
    |> String.to_atom()
  end
end
