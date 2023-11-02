defmodule Membership.Member.Server do
  use GenServer

  @moduledoc """
  Service
    this will store the member state
  """

  require Logger
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
    registry_name = "#{init_arg.identifier}_calculated_modules"
    supervisor_name = "#{init_arg.identifier}_calculated_modules_supervisor"
    Registry.start_link(keys: :unique, name: String.to_atom(registry_name))

    GenServer.start_link(Membership.Calculated.Supervisor, name: String.to_atom(supervisor_name))
    {:ok, init_arg}
  end

  def add_to_calculated_registry(member, data) do
    #    GenServer.call(via_tuple(member.identifier), {:add_to_calculated_registry, data})
    #    rules = []
    #    func_name = "test"
    #
    #    Membership.Registry.add(
    #      __MODULE__,
    #      func_name,
    #      rules
    #    )
    %{required_features: [], calculated_as_authorized: []}
  end

  def fetch_from_calculated_registry(member, module, data) do
    data = Tuple.append(data, module)
    GenServer.call(via_tuple(member.identifier), {:fetch_from_calculated_registry, data})
  end

  def start_link(data) do
    name = via_tuple(data.identifier)
    GenServer.start_link(__MODULE__, data, name: name)
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
  def handle_call(_msg, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:add_to_calculated_registry, data}, _, state) do
    supervisor_name = "#{state.identifier}_calculated_modules_supervisor"
    Membership.Calculated.Supervisor.start(data, supervisor_name)
    {:reply, state, state}
  end

  @impl true
  def handle_call({:fetch_from_calculated_registry, data}, _, state) do
    ## TODO:: logic
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
