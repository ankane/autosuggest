# dependencies
require "set"
require "lingua/stemmer"
require "yaml" # for obscenity
require "obscenity"

# modules
require "autosuggest/version"

class Autosuggest
  def initialize(top_queries)
    @top_queries = top_queries
    @concepts = {}
    @words = Set.new
    @non_duplicates = Set.new
    @blacklisted_words = Set.new
    @preferred_queries = {}
    @profane_words = Set.new(Obscenity::Base.blacklist)
  end

  def add_concept(name, values)
    @concepts[name] = Set.new(values.compact.uniq.map(&:downcase))
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

  def blacklist_words(words)
    words.each do |word|
      @blacklisted_words << word.downcase
    end
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

      # exclude misspellings that are not brands
      misspelling = @words.any? && misspellings?(query)

      profane = blacklisted?(query, @profane_words)

      blacklisted = blacklisted?(query, @blacklisted_words)

      notes = []
      notes << "duplicate of #{duplicate}" if duplicate
      notes.concat(concepts)
      notes << "misspelling" if misspelling
      notes << "profane" if profane
      notes << "blacklisted" if blacklisted
      notes << "originally #{original_query}" if original_query

      {
        query: query,
        original_query: original_query,
        score: count,
        duplicate: duplicate,
        concepts: concepts,
        misspelling: misspelling,
        profane: profane,
        blacklisted: blacklisted,
        notes: notes
      }
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

  def misspellings?(query)
    recurse(tokenize(query)).each do |terms|
      if terms.all? { |t| @concepts.any? { |_, values| values.include?(t) } || @words.include?(t) }
        return false
      end
    end
    true
  end

  def blacklisted?(query, blacklisted_words)
    recurse(tokenize(query)).each do |terms|
      return true if terms.any? { |t| blacklisted_words.include?(t) }
    end
    false
  end

  def recurse(words)
    if words.size == 1
      [words]
    else
      result = [[words.join(" ")]]
      i = 0
      while i < words.size - 1
        recurse(words[0..i]).each do |v1|
          recurse(words[i + 1..-1]).each do |v2|
            result << v1 + v2
          end
        end
        i += 1
      end
      result.uniq
    end
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
end
