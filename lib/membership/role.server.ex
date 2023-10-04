defmodule Membership.Role.Server do
  use GenServer

  @moduledoc """
  Service
    this will store the member state
  """

  require Logger

  @name :membership_roles

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
    roles = Membership.Role.all()
    :ets.insert(@name, roles)
  end
end
