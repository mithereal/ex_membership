defmodule Membership.Repo do
  @moduledoc """
  Ecto repository
  """

  use Ecto.Repo,
    otp_app: :membership,
    adapter: Ecto.Adapters.Postgres
end
