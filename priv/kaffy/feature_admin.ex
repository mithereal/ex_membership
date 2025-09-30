defmodule Membership.FeatureAdmin do
  @moduledoc """
  Configuration for prices in Kaffy admin.
  """

  import Phoenix.Component

  alias Membership.Feature

  def create_changeset(schema, attrs) do
    Feature.changeset(schema, attrs)
  end

  def update_changeset(schema, attrs) do
    Feature.changeset(schema, attrs)
  end

  def index(_) do
    [
      name: %{
        name: "features"
      }
    ]
  end

  def form_fields(_) do
    [
      name: nil
    ]
  end

  def insert(conn, _changeset) do
    name = conn.params["feature"]["name"]

    Feature.create(name, name)
  end

  def delete(conn, _changeset) do
    with %{params: %{"ids" => id}} <- conn,
         {:ok, data} <- Feature.get(id),
         :ok <- Membership.delete_feature(data) do
      {:ok, data}
    else
      error ->
        {:error, error}
    end
  end
end
