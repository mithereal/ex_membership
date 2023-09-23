defmodule Membership.Permission.Server do
  use GenServer

  @moduledoc """
  Service
    this will store the member state
  """

  require Logger
  @registry_name :module_permissions
  @default %{required_features: []}

  def child_spec(data) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [data]},
      type: :worker
    }
  end

  @impl true
  def init(init_arg) do
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

  def start_link(data) do
    name = via_tuple(data)
    GenServer.start_link(__MODULE__, data, name: name)
  end

  @doc false
  def via_tuple(id, registry \\ @registry_name) do
    {:via, Registry, {registry, id}}
  end

  def insert(name, value) do
    :ets.insert(self.ref, {name, value})
  end

  def add(name, value) do
    current =
      case lookup(self.ref, name) do
        {:ok, nil} -> @default
        {:ok, current} -> current
      end

    uniq = %{current | required_features: Enum.uniq(current.required_features ++ [value])}

    :ets.insert(self.ref, {name, uniq})
  end

  def add(name, value) do
    current =
      case lookup(self.ref, name) do
        {:ok, nil} -> @default
        {:ok, current} -> current
      end

    uniq = %{current | required_features: Enum.uniq(current.required_features ++ [value])}

    :ets.insert(self.ref, {name, uniq})
  end

  def lookup(name) do
    case :ets.lookup(self.ref, name) do
      [{^name, value}] -> {:ok, value}
      [] -> {:ok, nil}
    end
  end
end
