defmodule ElixirGoogleScraper.Factory do
  use ExMachina.Ecto, repo: ElixirGoogleScraper.Repo

  use ElixirGoogleScraper.Accounts.UserFactory

  # Define your factories in /test/factories and declare it here,
  # eg: `use ElixirGoogleScraper.Accounts.UserFactory`
end
