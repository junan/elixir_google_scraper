defmodule ElixirGoogleScraper.Scraper do
  @moduledoc """
  The Scraper context.
  """

  import Ecto.Query, warn: false

  alias ElixirGoogleScraper.Accounts.User
  alias ElixirGoogleScraper.Repo
  alias ElixirGoogleScraper.Scraper.{CSVKeyword, Keyword}

  defp create_keyword(attrs) do
    %Keyword{}
    |> Keyword.changeset(attrs)
    |> Repo.insert()
  end

  def save_keywords(file, %User{} = user) do
    case CSVKeyword.validate(file) do
      {:ok, keyword_list} ->
        Enum.each(keyword_list, fn keyword ->
          create_keyword(%{
            name: List.first(keyword),
            user_id: user.id
          })
        end)

        :ok

      {:error, :file_is_empty} ->
        {:error, :file_is_empty}

      {:error, :keyword_list_exceeded} ->
        {:error, :keyword_list_exceeded}
    end
  end
end
