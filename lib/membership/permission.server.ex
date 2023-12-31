defmodule Membership.Permission.Server do
  use GenServer

  @moduledoc """
  Service
    this will store the member state
  """

  @registry_name :module_permissions
  @default []

  def child_spec(data) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [data]},
      type: :worker
    }
  end

  @impl true
  def init(init_arg) when is_bitstring(init_arg) do
    ref =
      :ets.new(String.to_atom(init_arg), [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: false
      ])

    {:ok, %{ref: ref}}
  end

  @impl true
  def init(init_arg) when is_atom(init_arg) do
    ref =
      :ets.new(init_arg, [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: false
      ])

    {:ok, %{ref: ref}}
  end

  def start_link(data) do
    name = via_tuple(data)
    GenServer.start_link(__MODULE__, data, name: name)
  end

  @doc false
  def via_tuple(id, registry \\ @registry_name) do
    {:via, Registry, {registry, id}}
  end

  def insert(module, name, value) do
    module = via_tuple(module)
    GenServer.cast(module, {:insert, {name, value}})
  end

  def add(module, name, value) do
    module = via_tuple(module)
    GenServer.cast(module, {:add, {name, value}})
  end

  @impl true
  def handle_cast({:insert, value}, state) do
    :ets.insert(state.ref, value)
    {:noreply, state}
  end

  def handle_cast({:add, {name, value}}, state) do
    current =
      case lookup(name, state.ref) do
        {:ok, nil} -> @default
        {:ok, current} -> current
      end

    uniq = Enum.uniq(current ++ [value])

    :ets.insert(state.ref, {name, uniq})
    {:noreply, state}
  end

  def lookup(name, ref \\ __MODULE__) do
    case :ets.lookup(ref, name) do
      [{^name, value}] -> {:ok, value}
      [] -> {:ok, nil}
    end
  end
end
