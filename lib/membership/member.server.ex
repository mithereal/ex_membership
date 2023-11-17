defmodule Membership.Member.Server do
  use GenServer

  @moduledoc """
  Service
    this will store the member state
  """

  @registry_name :active_memberships

  defstruct identifier: nil, features: []

  def child_spec(data) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [data]},
      type: :worker
    }
  end

  @impl true
  def init(init_arg) do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    init_arg = Map.put(init_arg, :ref, agent)
    {:ok, init_arg}
  end

  def add_to_calculated_registry(member, data) do
    name = via_tuple(member.identifier)
    GenServer.call(name, {:add_to_calculated_registry, data})
  end

  def fetch_from_calculated_registry(member) do
    name = via_tuple(member.identifier)
    GenServer.call(name, :fetch_from_calculated_registry)
  end

  def fetch_from_calculated_registry(member, data) do
    name = via_tuple(member.identifier)
    GenServer.call(name, {:fetch_from_calculated_registry, data})
  end

  def start_link(data) do
    name = via_tuple(data.identifier)
    GenServer.start_link(__MODULE__, data, name: name)
  end

  def shutdown(data) do
    name = via_tuple(data.identifier)
    GenServer.call(name, :shutdown)
  end

  def shutdown() do
    GenServer.call(__MODULE__, :shutdown)
  end

  @impl true
  def handle_call(
        :shutdown,
        _from,
        state
      ) do
    {:stop, {:ok, "Normal Shutdown"}, state}
  end

  @impl true
  def handle_call({:add_to_calculated_registry, data}, _, state) do
    Agent.update(state.ref, fn state -> [data] end)

    {:reply, state, state}
  end

  @impl true
  def handle_call({:update, data}, _, state) do
    {:noreply, data}
  end

  @impl true
  def handle_call({:fetch_from_calculated_registry, key}, _, state) do
    reply =
      Agent.get(state.ref, fn state ->
        Enum.find(state, fn {x, _} -> x == key end)
      end)

    reply =
      case reply do
        nil -> []
        _ -> reply
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_call(:fetch_from_calculated_registry, _, state) do
    reply =
      Agent.get(state.ref, fn state -> state end)

    {:reply, reply, state}
  end

  @impl true
  def handle_call(_msg, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:load, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        :shutdown,
        state
      ) do
    {:stop, :normal, state}
  end

  @doc false
  def via_tuple(id, registry \\ @registry_name) do
    {:via, Registry, {registry, id}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, data) do
    {:noreply, data}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def show(params) do
    GenServer.call(via_tuple(params.identifier), :show)
  end
end
