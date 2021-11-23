require_relative "test_helper"

class ModelTest < Minitest::Test
  def setup
    Autosuggest::Suggestion.delete_all
  end

  def test_works
    top_queries = {"apple" => 3, "banana" => 2, "carrot" => 1}
    autosuggest = Autosuggest.new(top_queries)
    update_suggestions(autosuggest)

    results = Autosuggest::Suggestion.order(score: :desc).pluck(:query)
    assert_equal ["apple", "banana", "carrot"], results

    prefix = "ap"
    results = Autosuggest::Suggestion.order(score: :desc).where("query LIKE ?", "%#{Autosuggest::Suggestion.sanitize_sql_like(prefix.downcase)}%").pluck(:query)
    assert_equal ["apple"], results

    prefix = "ap%"
    results = Autosuggest::Suggestion.order(score: :desc).where("query LIKE ?", "%#{Autosuggest::Suggestion.sanitize_sql_like(prefix.downcase)}%").pluck(:query)
    assert_empty results
  end

  def test_update
    top_queries = {"apples" => 3, "apple" => 2}
    autosuggest = Autosuggest.new(top_queries)
    update_suggestions(autosuggest)

    assert_equal ["apples"], Autosuggest::Suggestion.pluck(:query)

    autosuggest = Autosuggest.new(top_queries)
    autosuggest.prefer ["apple"]
    update_suggestions(autosuggest)

    assert_equal ["apple"], Autosuggest::Suggestion.pluck(:query)
  end

  def update_suggestions(autosuggest)
    now = Time.now
    records = autosuggest.suggestions(filter: true).map { |s| s.slice(:query, :score).merge(updated_at: now) }
    Autosuggest::Suggestion.transaction do
      if ENV["ADAPTER"] == "mysql"
        Autosuggest::Suggestion.upsert_all(records)
      else
        Autosuggest::Suggestion.upsert_all(records, unique_by: :query)
      end
      Autosuggest::Suggestion.where("updated_at < ?", now).delete_all
    end
  end
end
