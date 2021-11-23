require_relative "test_helper"

class ModelTest < Minitest::Test
  def test_works
    top_queries = {"apple" => 3, "banana" => 2, "carrot" => 1}
    autosuggest = Autosuggest.new(top_queries)
    suggestions = autosuggest.suggestions(filter: true)

    now = Time.now
    records = suggestions.map { |s| s.slice(:query, :score).merge(updated_at: now) }
    Autosuggest::Suggestion.transaction do
      Autosuggest::Suggestion.upsert_all(records, unique_by: :query)
      # remove previous suggestions (optional)
      Autosuggest::Suggestion.where("updated_at < ?", now).delete_all
    end

    results = Autosuggest::Suggestion.order(score: :desc).pluck(:query)
    assert_equal ["apple", "banana", "carrot"], results

    prefix = "ap"
    results = Autosuggest::Suggestion.order(score: :desc).where("query LIKE ?", "%#{Autosuggest::Suggestion.sanitize_sql_like(prefix.downcase)}%").pluck(:query)
    assert_equal ["apple"], results

    prefix = "ap%"
    results = Autosuggest::Suggestion.order(score: :desc).where("query LIKE ?", "%#{Autosuggest::Suggestion.sanitize_sql_like(prefix.downcase)}%").pluck(:query)
    assert_empty results
  end
end
