defmodule Membership.Member.Server do
  use GenServer

  @moduledoc """
  Service
    this will store the member state
  """

  require Logger
  @registry_name :active_memberships

  defstruct identifier: nil, ref: nil

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
      :ets.new(:membership_members, [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: false
      ])

    :ets.insert(ref, {:default, init_arg})

    {:ok, %{identifier: init_arg.identifier, ref: ref}}
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

  @impl true
  def handle_call(_msg, state) do
    {:reply, state, state}
  end

  def show(params) do
    GenServer.call(via_tuple(params), :show)
  end
end
