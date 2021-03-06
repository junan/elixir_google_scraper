defmodule ElixirGoogleScraper.Scraper.Keywords do
  use Ecto.Schema

  import Ecto.Query, warn: false

  alias ElixirGoogleScraper.Account.Schemas.User
  alias ElixirGoogleScraper.Repo
  alias ElixirGoogleScraper.Scraper.CSVKeyword
  alias ElixirGoogleScraper.Scraper.Schemas.Keyword
  alias ElixirGoogleScraper.Scraper.Worker.ScrapingWorker

  def paginated_user_keywords(user, params \\ %{}) do
    user
    |> user_keywords_query
    |> filtered_keywords_query(params["name"])
    |> Repo.paginate(params)
  end

  def get_user_keyword(user, id) do
    user
    |> user_keywords_query
    |> preload(:search_result)
    |> Repo.get(id)
  end

  def save_keywords(file, %User{} = user) do
    case CSVKeyword.validate(file) do
      {:ok, keyword_list} ->
        keywords =
          Enum.map(keyword_list, fn keyword ->
            {_, keyword} =
              create_keyword(%{
                name: List.first(keyword),
                user_id: user.id
              })

            keyword
          end)

        enqueue_keywords(keywords)

        :ok

      {:error, :file_is_empty} ->
        {:error, :file_is_empty}

      {:error, :keyword_list_exceeded} ->
        {:error, :keyword_list_exceeded}
    end
  end

  def mark_as_completed(keyword) do
    keyword
    |> Keyword.complete_changeset()
    |> Repo.update!()
  end

  # There will be 3 seconds interval between each job starting time.
  # This is to avoid Google blocking for mass requests.
  # For example the first job will be run at 3 second, second job will be run at 6 second,
  # then third job will be run at 9 second and so on.
  defp enqueue_keywords(keywords) do
    keywords
    |> Enum.with_index()
    |> Enum.each(fn {keyword, index} ->
      %{keyword_id: keyword.id}
      |> ScrapingWorker.new(schedule_in: index + 3)
      |> Oban.insert()
    end)
  end

  defp create_keyword(attrs) do
    %Keyword{}
    |> Keyword.changeset(attrs)
    |> Repo.insert()
  end

  def get_keyword!(id) do
    Keyword
    |> preload(:search_result)
    |> Repo.get!(id)
  end

  defp user_keywords_query(user) do
    where(Keyword, [k], k.user_id == ^user.id)
  end

  defp filtered_keywords_query(query, nil) do
    query
  end

  defp filtered_keywords_query(query, query_string) do
    where(query, [k], ilike(k.name, ^"#{query_string}%"))
  end
end
