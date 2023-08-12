defmodule Membership.Registry do
  @moduledoc false

  use GenServer

  def start_link(args) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{table: nil})
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

  def add(identifier,name, value) do
    current =
      case lookup(identifier,name) do
        {:ok, nil} -> []
        {:ok, current} -> current
      end

    uniq = Enum.uniq(current ++ [value])

    :ets.insert(name, uniq)
  end

  def lookup(identifier, name) do
    case :ets.lookup(identifier, name) do
      [{^name, value}] -> {:ok, value}
      [] -> {:ok, nil}
    end
  end
end
