# stdlib
require "set"
require "yaml" # for obscenity

# dependencies
require "lingua/stemmer"
require "obscenity"

# modules
require "autosuggest/version"

class Autosuggest
  def initialize(top_queries)
    @top_queries = top_queries
    @concepts = {}
    @words = Set.new
    @non_duplicates = Set.new
    @blocked_words = {}
    @blacklisted_words = {}
    @preferred_queries = {}
    @profane_words = {}
    @concept_tree = {}
    add_nodes(@profane_words, Obscenity::Base.blacklist)
  end

  def add_concept(name, values)
    values = values.compact.uniq
    add_nodes(@concept_tree, values)
    @concepts[name] = Set.new(values.map(&:downcase))
  end

  def parse_words(phrases, options = {})
    min = options[:min] || 1

    word_counts = Hash.new(0)
    phrases.each do |phrase|
      words = tokenize(phrase)
      words.each do |word|
        word_counts[word] += 1
      end
    end

    word_counts.select { |_, c| c >= min }.each do |word, _|
      @words << word
    end

    word_counts
  end

  def not_duplicates(pairs)
    pairs.each do |pair|
      @non_duplicates << pair.map(&:downcase).sort
    end
  end

  def block_words(words)
    add_nodes(@blocked_words, words)
    words
  end

  def blacklist_words(words)
    warn "[autosuggest] blacklist_words is deprecated. Use block_words instead."
    add_nodes(@blacklisted_words, words)
    words
  end

  def prefer(queries)
    queries.each do |query|
      @preferred_queries[normalize_query(query)] ||= query
    end
  end

  def suggestions
    stemmed_queries = {}
    added_queries = Set.new
    @top_queries.sort_by { |_query, count| -count }.map do |query, count|
      query = query.to_s

      # TODO do not ignore silently
      next if query.length < 2

      stemmed_query = normalize_query(query)

      # get preferred term
      preferred_query = @preferred_queries[stemmed_query]
      if preferred_query && preferred_query != query
        original_query, query = query, preferred_query
      end

      # exclude duplicates
      duplicate = stemmed_queries[stemmed_query]
      stemmed_queries[stemmed_query] ||= query

      # also detect possibly misspelled duplicates
      # TODO use top query as duplicate
      if !duplicate && query.length > 4
        edits(query).each do |edited_query|
          if added_queries.include?(edited_query)
            duplicate = edited_query
            break
          end
        end
      end
      if duplicate && @non_duplicates.include?([duplicate, query].sort)
        duplicate = nil
      end
      added_queries << query unless duplicate

      # find concepts
      concepts = []
      @concepts.each do |name, values|
        concepts << name if values.include?(query)
      end

      tokens = tokenize(query)

      # exclude misspellings that are not brands
      misspelling = @words.any? && misspellings?(tokens)

      profane = blocked?(tokens, @profane_words)
      blocked = blocked?(tokens, @blocked_words)
      blacklisted = blocked?(tokens, @blacklisted_words)

      notes = []
      notes << "duplicate of #{duplicate}" if duplicate
      notes.concat(concepts)
      notes << "misspelling" if misspelling
      notes << "profane" if profane
      notes << "blocked" if blocked
      notes << "blacklisted" if blacklisted
      notes << "originally #{original_query}" if original_query

      result = {
        query: query,
        original_query: original_query,
        score: count,
        duplicate: duplicate,
        concepts: concepts,
        misspelling: misspelling,
        profane: profane,
        blocked: blocked
      }
      result[:blacklisted] = blacklisted if @blacklisted_words.any?
      result[:notes] = notes
      result
    end
  end

  def pretty_suggestions
    str = "%-30s   %5s   %s\n" % %w(Query Score Notes)
    suggestions.each do |suggestion|
      str << "%-30s   %5d   %s\n" % [suggestion[:query], suggestion[:score], suggestion[:notes].join(", ")]
    end
    str
  end

  protected

  def misspellings?(tokens)
    pos = [0]
    while i = pos.shift
      return false if i == tokens.size

      if @words.include?(tokens[i])
        pos << i + 1
      end

      node = @concept_tree[tokens[i]]
      j = i
      while node
        j += 1
        pos << j if node[:eos]
        break if j == tokens.size
        node = node[tokens[j]]
      end

      pos.uniq!
    end
    true
  end

  def blocked?(tokens, blocked_words)
    tokens.each_with_index do |token, i|
      node = blocked_words[token]
      j = i
      while node
        return true if node[:eos]
        j += 1
        break if j == tokens.size
        node = node[tokens[j]]
      end
    end
    false
  end

  def tokenize(str)
    str.to_s.downcase.split(" ")
  end

  # from https://blog.lojic.com/2008/09/04/how-to-write-a-spelling-corrector-in-ruby/
  LETTERS = ("a".."z").to_a.join + "'"
  def edits(word)
    n = word.length
    deletion = (0...n).collect { |i| word[0...i] + word[i + 1..-1] }
    transposition = (0...n - 1).collect { |i| word[0...i] + word[i + 1, 1] + word[i, 1] + word[i + 2..-1] }
    alteration = []
    n.times { |i| LETTERS.each_byte { |l| alteration << word[0...i] + l.chr + word[i + 1..-1] } }
    insertion = []
    (n + 1).times { |i| LETTERS.each_byte { |l| insertion << word[0...i] + l.chr + word[i..-1] } }
    deletion + transposition + alteration + insertion
  end

  def normalize_query(query)
    tokenize(query.to_s.gsub("&", "and")).map { |q| Lingua.stemmer(q) }.sort.join
  end

  def add_nodes(var, words)
    words.each do |word|
      node = var
      tokenize(word).each do |token|
        node = (node[token] ||= {})
      end
      node[:eos] = true
    end
    var
  end
end
