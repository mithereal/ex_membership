defmodule Membership.Registry do
  @moduledoc false

  use GenServer

  @default []

  def start_link(args) do
    {:ok, pid} =
      __MODULE__
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

  def insert(identifier, name, value) when is_bitstring(identifier) do
    :ets.insert(identifier, {name, value})
  end

  def insert(identifier, name, value) when is_atom(identifier) do
    :ets.insert(identifier, {name, value})
  end

  def add(identifier, name, value) when is_binary(identifier) do
    current =
      case lookup(identifier, name) do
        {:ok, nil} -> @default
        {:ok, current} -> current
      end

    uniq = Enum.uniq(current ++ [value])

    :ets.insert(identifier, {name, uniq})
  end

  def add(identifier, name, value) when is_atom(identifier) do
    current =
      case lookup(identifier, name) do
        {:ok, nil} -> @default
        {:ok, current} -> current
      end

    uniq = Enum.uniq(current ++ [value])

    :ets.insert(identifier, {name, uniq})
  end

  def lookup(identifier, name) when is_binary(identifier) do
    case :ets.lookup(identifier, name) do
      [{^name, value}] -> {:ok, value}
      [] -> {:ok, nil}
    end
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
    __MODULE__
    |> :ets.lookup(name)
  end
end
