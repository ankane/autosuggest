require_relative "test_helper"

class AutosuggestTest < Minitest::Test
  def test_similar_queries
    top_queries = {"chili" => 2, "chilli" => 1}
    autocomplete = Autosuggest.new(top_queries)
    assert autocomplete.suggestions.last[:duplicate]
  end

  def test_stemming
    top_queries = {"tomato" => 2, "tomatoes" => 1}
    autocomplete = Autosuggest.new(top_queries)
    assert autocomplete.suggestions.last[:duplicate]
  end

  def test_profanity
    top_queries = {"hell" => 2}
    autocomplete = Autosuggest.new(top_queries)
    assert autocomplete.suggestions.first[:profane]
  end

  def test_duplicates
    top_queries = {"cage free eggs" => 2, "eggs cage free" => 1}
    autocomplete = Autosuggest.new(top_queries)
    assert autocomplete.suggestions.last[:duplicate]
  end

  def test_not_duplicates
    top_queries = {"straws" => 2, "straus" => 1}
    autocomplete = Autosuggest.new(top_queries)
    autocomplete.not_duplicates([%w(straus straws)])
    assert !autocomplete.suggestions.any? { |s| s[:duplicate] }
  end

  def test_block_words
    top_queries = {"test boom" => 2}
    autocomplete = Autosuggest.new(top_queries)
    autocomplete.block_words(["boom"])
    assert autocomplete.suggestions.first[:blocked]
  end

  def test_block_words_phrase
    top_queries = {"test boom" => 2}
    autocomplete = Autosuggest.new(top_queries)
    autocomplete.block_words(["test boom"])
    assert autocomplete.suggestions.first[:blocked]
  end

  def test_blacklist
    top_queries = {"test boom" => 2}
    autocomplete = Autosuggest.new(top_queries)
    assert_output(nil, /deprecated/) do
      autocomplete.blacklist_words(["boom"])
    end
    assert autocomplete.suggestions.first[:blacklisted]
  end

  def test_blacklist_phrase
    top_queries = {"test boom" => 2}
    autocomplete = Autosuggest.new(top_queries)
    assert_output(nil, /deprecated/) do
      autocomplete.blacklist_words(["test boom"])
    end
    assert autocomplete.suggestions.first[:blacklisted]
  end

  def test_prefer
    top_queries = {"amys" => 2}
    autocomplete = Autosuggest.new(top_queries)
    autocomplete.prefer(["amy's"])
    assert_equal "amy's", autocomplete.suggestions.first[:query]
  end
end
