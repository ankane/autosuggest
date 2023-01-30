require_relative "test_helper"

class GeneratorTest < Minitest::Test
  def test_fields
    top_queries = {"hello" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    suggestion = autosuggest.suggestions(filter: false).first
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
    autosuggest = Autosuggest::Generator.new(top_queries)
    suggestion = autosuggest.suggestions(filter: false).last
    assert_equal "chili", suggestion[:duplicate]
    assert_equal ["duplicate of chili"], suggestion[:notes]
  end

  def test_stemming
    top_queries = {"tomato" => 2, "tomatoes" => 1}
    autosuggest = Autosuggest::Generator.new(top_queries)
    suggestion = autosuggest.suggestions(filter: false).last
    assert_equal "tomato", suggestion[:duplicate]
    assert_equal ["duplicate of tomato"], suggestion[:notes]
  end

  def test_stemming_language
    top_queries = {"tomate" => 2, "tomates" => 1}
    autosuggest = Autosuggest::Generator.new(top_queries, language: "spanish")
    suggestion = autosuggest.suggestions(filter: false).last
    assert_equal "tomate", suggestion[:duplicate]
    assert_equal ["duplicate of tomate"], suggestion[:notes]
  end

  def test_stemming_language_invalid
    top_queries = {"hello" => 2}
    error = assert_raises(ArgumentError) do
      Autosuggest::Generator.new(top_queries, language: "bad")
    end
    assert_equal "Language not available", error.message
  end

  def test_profanity
    top_queries = {"hell" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    suggestion = autosuggest.suggestions(filter: false).first
    assert suggestion[:profane]
    assert_equal ["profane"], suggestion[:notes]
  end

  def test_duplicates
    top_queries = {"cage free eggs" => 2, "eggs cage free" => 1}
    autosuggest = Autosuggest::Generator.new(top_queries)
    suggestion = autosuggest.suggestions(filter: false).last
    assert_equal "cage free eggs", suggestion[:duplicate]
    assert_equal ["duplicate of cage free eggs"], suggestion[:notes]
  end

  def test_not_duplicates
    top_queries = {"straws" => 2, "straus" => 1}
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.not_duplicates([["straus", "straws"]])
    assert !autosuggest.suggestions(filter: false).any? { |s| s[:duplicate] }
  end

  def test_block_words
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.block_words(["boom"])
    suggestion = autosuggest.suggestions(filter: false).first
    assert suggestion[:blocked]
    assert_equal ["blocked"], suggestion[:notes]
  end

  def test_block_words_phrase
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.block_words(["test boom"])
    suggestion = autosuggest.suggestions(filter: false).first
    assert suggestion[:blocked]
    assert_equal ["blocked"], suggestion[:notes]
  end

  def test_blacklist
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    assert_output(nil, /deprecated/) do
      autosuggest.blacklist_words(["boom"])
    end
    suggestion = autosuggest.suggestions(filter: false).first
    assert suggestion[:blacklisted]
    assert_equal ["blacklisted"], suggestion[:notes]
  end

  def test_blacklist_phrase
    top_queries = {"test boom" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    assert_output(nil, /deprecated/) do
      autosuggest.blacklist_words(["test boom"])
    end
    suggestion = autosuggest.suggestions(filter: false).first
    assert suggestion[:blacklisted]
    assert_equal ["blacklisted"], suggestion[:notes]
  end

  def test_prefer
    top_queries = {"amys" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.prefer(["amy's"])
    suggestion = autosuggest.suggestions(filter: false).first
    assert_equal "amy's", suggestion[:query]
    assert_equal "amys", suggestion[:original_query]
    assert_equal ["originally amys"], suggestion[:notes]
  end

  def test_add_concept
    top_queries = {"amys" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.add_concept("brand", ["amys"])
    suggestion = autosuggest.suggestions(filter: false).first
    assert_equal ["brand"], suggestion[:concepts]
    assert_equal ["brand"], suggestion[:notes]
  end

  def test_parse_words
    top_queries = {"tomato" => 2, "tomoto" => 1}
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.parse_words ["tomato soup"]
    refute autosuggest.suggestions(filter: false).first[:misspelling]
    assert autosuggest.suggestions(filter: false).last[:misspelling]
  end

  def test_misspelling
    top_queries = {
      "hello" => 9,
      "world" => 8,
      "multiple words" => 7,
      "hello multiple words" => 6,
      "multiple words hello" => 5,
      "multiple hello words" => 4,
      "hello multiple" => 3,
      "multiple" => 2
    }
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.parse_words ["hello"]
    autosuggest.add_concept("brand", ["multiple words"])
    assert_equal [false, true, false, false, false, true, true, true], autosuggest.suggestions(filter: false).map { |s| s[:misspelling] }
  end

  def test_misspelling_overlap
    top_queries = {
      "word hello brand" => 3,
      "word hello brand great" => 2,
      "hello hello brand word" => 1
    }
    autosuggest = Autosuggest::Generator.new(top_queries)
    autosuggest.parse_words ["hello", "word"]
    autosuggest.add_concept("brand", ["hello", "hello brand", "hello brand great"])
    assert_equal [false, false, false], autosuggest.suggestions(filter: false).map { |s| s[:misspelling] }
  end

  def test_short_query
    top_queries = {"a" => 1, "ab" => 2}
    autosuggest = Autosuggest::Generator.new(top_queries)
    assert_equal 1, autosuggest.suggestions.size
    assert_equal 1, autosuggest.suggestions(filter: false).size
  end

  def test_long_query
    top_queries = {50.times.map { |i| "word#{i}" }.join(" ") => 1}
    autosuggest = Autosuggest::Generator.new(top_queries)
    assert_equal 1, autosuggest.suggestions(filter: false).size
  end

  def test_filter
    top_queries = {"tomato" => 2, "tomatoes" => 1}
    autosuggest = Autosuggest::Generator.new(top_queries)
    suggestions = autosuggest.suggestions
    assert_equal 1, suggestions.size
    assert_equal "tomato", suggestions.first[:query]
  end
end
