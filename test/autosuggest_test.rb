require_relative "test_helper"

class AutosuggestTest < Minitest::Test
  def test_fields
    top_queries = {"hello" => 2}
    autosuggest = Autosuggest.new(top_queries)
    suggestion = autosuggest.suggestions.last
    assert_equal suggestion[:query], "hello"
    assert_nil suggestion[:original_query]
    assert_equal 2, suggestion[:score]
    assert_nil suggestion[:duplicate]
    assert_empty suggestion[:concepts]
    refute suggestion[:misspellings]
    refute suggestion[:profane]
    refute suggestion[:blocked]
    assert_empty suggestion[:notes]
  end

  def test_similar_queries
    top_queries = {"chili" => 2, "chilli" => 1}
    autosuggest = Autosuggest.new(top_queries)
    suggestion = autosuggest.suggestions.last
    assert_equal "chili", suggestion[:duplicate]
    assert_equal ["duplicate of chili"], suggestion[:notes]
  end

  def test_stemming
    top_queries = {"tomato" => 2, "tomatoes" => 1}
    autosuggest = Autosuggest.new(top_queries)
    suggestion = autosuggest.suggestions.last
    assert_equal "tomato", suggestion[:duplicate]
    assert_equal ["duplicate of tomato"], suggestion[:notes]
  end

  def test_profanity
    top_queries = {"hell" => 2}
    autosuggest = Autosuggest.new(top_queries)
    suggestion = autosuggest.suggestions.first
    assert suggestion[:profane]
    assert_equal ["profane"], suggestion[:notes]
  end

  def test_duplicates
    top_queries = {"cage free eggs" => 2, "eggs cage free" => 1}
    autosuggest = Autosuggest.new(top_queries)
    assert autosuggest.suggestions.last[:duplicate]
  end

  def test_not_duplicates
    top_queries = {"straws" => 2, "straus" => 1}
    autosuggest = Autosuggest.new(top_queries)
    autosuggest.not_duplicates([%w(straus straws)])
    assert !autosuggest.suggestions.any? { |s| s[:duplicate] }
  end

  def test_block_words
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest.new(top_queries)
    autosuggest.block_words(["boom"])
    assert autosuggest.suggestions.first[:blocked]
  end

  def test_block_words_phrase
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest.new(top_queries)
    autosuggest.block_words(["test boom"])
    assert autosuggest.suggestions.first[:blocked]
  end

  def test_blacklist
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest.new(top_queries)
    assert_output(nil, /deprecated/) do
      autosuggest.blacklist_words(["boom"])
    end
    assert autosuggest.suggestions.first[:blacklisted]
  end

  def test_blacklist_phrase
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest.new(top_queries)
    assert_output(nil, /deprecated/) do
      autosuggest.blacklist_words(["test boom"])
    end
    assert autosuggest.suggestions.first[:blacklisted]
  end

  def test_prefer
    top_queries = {"amys" => 2}
    autosuggest = Autosuggest.new(top_queries)
    autosuggest.prefer(["amy's"])
    assert_equal "amy's", autosuggest.suggestions.first[:query]
  end

  def test_add_concept
    top_queries = {"amys" => 2}
    autosuggest = Autosuggest.new(top_queries)
    autosuggest.add_concept("brand", ["amys"])
    assert_equal ["brand"], autosuggest.suggestions.first[:concepts]
  end

  def test_parse_words
    top_queries = {"tomato" => 2, "tomoto" => 1}
    autosuggest = Autosuggest.new(top_queries)
    autosuggest.parse_words ["tomato soup"]
    refute autosuggest.suggestions.first[:misspelling]
    assert autosuggest.suggestions.last[:misspelling]
  end

  def test_long_query
    top_queries = {50.times.map { |i| "word#{i}" }.join(" ") => 1}
    autosuggest = Autosuggest.new(top_queries)
    assert autosuggest.suggestions
  end
end
