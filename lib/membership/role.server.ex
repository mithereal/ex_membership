defmodule Membership.Role.Server do
  use GenServer

  @update_check_time 50000

  @moduledoc """
  Role
    this will store/fetch the {role, features} into ets
  """

  require Logger

  @config Membership.Config.new()

  @name :membership_roles

  def child_spec(data) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [data]},
      type: :worker
    }
  end

  @impl true
  def init(_init_arg) do
    ref =
      :ets.new(@name, [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: false
      ])

    {:ok, %{ref: ref}, {:continue, :start_task}}
  end

  def start_link(data) do
    GenServer.start_link(__MODULE__, data, name: @name)
  end

  def reload() do
    GenServer.cast(@name, :load)
  end

  @impl true
  def handle_cast(:load, state) do
    roles =
      Membership.Role.all(@config)

    :ets.insert(@name, roles)
    {:noreply, state}
  end

  @impl true
  def handle_info(:check_update, state) do
    Logger.info("Reloading Roles.")

    plans =
      Membership.Role.all(@config)

    :ets.insert(@name, plans)
    Process.send_after(self(), :check_update, @update_check_time)
    {:noreply, state}
  end

  @impl true
  def handle_continue(:start_task, state) do
    Process.send_after(self(), :check_update, @update_check_time)
    {:noreply, state}
  end
end
