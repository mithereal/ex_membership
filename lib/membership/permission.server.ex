defmodule Membership.Permission.Server do
  use GenServer

  @moduledoc """
  Service
    this will store the member state
  """

  require Logger
  @registry_name :module_permissions

  def child_spec(data) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [data]},
      type: :worker
    }
  end

  @impl true
  def init(init_arg) do
    {:ok, nil}
  end

  def start_link(data) do
    name = via_tuple(data)
    GenServer.start_link(__MODULE__, data, name: name)
  end
end
