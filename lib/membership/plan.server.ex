defmodule Membership.Plan.Server do
  use GenServer

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

    {:ok, %{ref: ref}}
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
end
