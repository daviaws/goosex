defmodule Goosex.Repo do
  use Ecto.Repo,
    otp_app: :goosex,
    adapter: Ecto.Adapters.Postgres
end
