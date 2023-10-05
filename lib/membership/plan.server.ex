defmodule Membership.Plan.Server do
  use GenServer

  @update_check_time 50000

  @moduledoc """
  Plan
    this will store/fetch the {plan, features} into ets
  """

  require Logger

  @name :membership_plans

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
      :ets.new(@name, [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: false
      ])

    Process.send_after(self(), :check_update, @update_check_time)
    {:ok, %{ref: ref}, {:continue, :start_task}}
  end

  def start_link(data) do
    GenServer.start_link(__MODULE__, data, name: @name)
  end

  def load() do
    GenServer.cast(@name, :load)
  end

  def handle_cast(:load, state) do
    plans = Membership.Plan.all() |> Enum.map(fn x -> {x.identifier, x.features} end)
    :ets.insert(@name, plans)
    {:noreply, state}
  end

  def handle_info(:check_update, state) do
    Logger.info("OTP UpdateChecker check update tasks were sent.")
    plans = Membership.Plan.all() |> Enum.map(fn x -> {x.identifier, x.features} end)
    :ets.insert(@name, plans)
    Process.send_after(self(), :check_update, @update_check_time)
    {:noreply, state}
  end

  def handle_continue(:start_task, state) do
    Process.send_after(self(), :check_update, @update_check_time)
    {:noreply, state}
  end
end
