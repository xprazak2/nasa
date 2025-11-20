defmodule Nasa.Repo do
  use Ecto.Repo,
    otp_app: :nasa,
    adapter: Ecto.Adapters.Postgres
end
