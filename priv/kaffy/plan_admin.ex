defmodule Membership.PlanAdmin do
  @moduledoc """
  Configuration for plans in Kaffy admin.
  """

  import Phoenix.Component

  alias Membership.Plan

  def create_changeset(schema, attrs) do
    Plan.changeset(schema, attrs)
  end

  def update_changeset(schema, attrs) do
    Plan.changeset(schema, attrs)
  end

  def index(_) do
    [
      name: %{
        name: "plans"
      }
    ]
  end

  def form_fields(_) do
    [
      name: nil
    ]
  end

  def insert(conn, _changeset) do
    name = conn.params["plan"]["name"]

    Plan.create(name, name)
  end

  def delete(conn, _changeset) do
    with %{params: %{"ids" => id}} <- conn,
         {:ok, data} <- Plan.get(id),
         :ok <- Membership.delete_plan(data) do
      {:ok, data}
    else
      error ->
        {:error, error}
    end
  end
end
