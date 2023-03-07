require 'matrix'
require 'set'

# Implementation of cosine similarity using TF-IDF for vectorization.
#
# In information retrieval, tf–idf, short for term frequency–inverse document frequency,
# is a numerical statistic that is intended to reflect how important a word is to a
# document in a collection or corpus
#
# Cosine Similarity a measurement to determine how similar 2 documents are to each other.
#
# These weights and measures are used to suggest which account a transaction should be
# assigned to.
module Reckon
  class CosineSimilarity
    DocumentInfo = Struct.new(:tokens, :accounts)

    def initialize(options)
      @docs = DocumentInfo.new({}, {})
    end

    def add_document(account, doc)
      tokens = tokenize(doc)
      LOGGER.info "doc tokens: #{tokens}"
      tokens.each do |n|
        (token, count) = n

        @docs.tokens[token] ||= Hash.new(0)
        @docs.tokens[token][account] += count
        @docs.accounts[account] ||= Hash.new(0)
        @docs.accounts[account][token] += count
      end
    end

    # find most similar documents to query
    def find_similar(query)
      LOGGER.info "find_similar #{query}"

      accounts = docs_to_check(query).map do |a|
        [a, tfidf(@docs.accounts[a])]
      end

      q = tfidf(tokenize(query))

      suggestions = accounts.map do |a, d|
        {
          similarity: calc_similarity(q, d),
          account: a
        }
      end.select { |n| n[:similarity] > 0 }.sort_by { |n| -n[:similarity] }

      LOGGER.info "most similar accounts: #{suggestions}"

      return suggestions
    end

    private

    def docs_to_check(query)
      return tokenize(query).reduce(Set.new) do |corpus, t|
        corpus.union(Set.new(@docs.tokens[t[0]]&.keys))
      end
    end

    def tfidf(tokens)
      scores = {}

      tokens.each do |t, n|
        scores[t] = calc_tf_idf(
          n,
          tokens.length,
          @docs.tokens[t]&.length&.to_f || 0,
          @docs.accounts.length
        )
      end

      return scores
    end

    # Cosine similarity is used to compare how similar 2 documents are. Returns a float
    # between 1 and -1, where 1 is exactly the same and -1 is exactly opposite.
    #
    # see https://en.wikipedia.org/wiki/Cosine_similarity
    # cos(theta) = (A . B) / (||A|| ||B||)
    # where A . B is the "dot product" and ||A|| is the magnitude of A
    #
    # The variables A and B are the set of unique terms in q and d.
    #
    # For example, when q = "big red balloon" and d ="small green balloon" then the
    # variables are (big,red,balloon,small,green) and a = (1,1,1,0,0) and b =
    # (0,0,1,1,1).
    #
    # query and doc are hashes of token => tf/idf score
    def calc_similarity(query, doc)
      tokens = Set.new(query.keys + doc.keys)

      a = Vector.elements(tokens.map { |n| query[n] || 0 }, false)
      b = Vector.elements(tokens.map { |n| doc[n] || 0 }, false)

      return a.inner_product(b) / (a.magnitude * b.magnitude)
    end

    def calc_tf_idf(token_count, num_words_in_doc, df, num_docs)
      # tf(t,d) = count of t in d / number of words in d
      tf = token_count / num_words_in_doc.to_f

      # smooth idf weight
      # see https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Inverse_document_frequency_2
      # df(t) = num of documents with term t in them
      # idf(t) = log(N/(1 + df )) + 1
      idf = Math.log(num_docs.to_f / (1 + df)) + 1

      tf * idf
    end

    def tokenize(str)
      mk_tokens(str).each_with_object(Hash.new(0)) do |n, memo|
        memo[n] += 1
      end.to_a
    end

    def mk_tokens(str)
      str.downcase.tr(';', ' ').tr("'", '').split(/[^a-z0-9.]+/).reject(&:empty?)
    end
  end
end
