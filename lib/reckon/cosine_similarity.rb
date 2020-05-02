require 'matrix'
require 'set'

# Implementation of consine similarity using TF-IDF for vectorization.
# Used to suggest which account a transaction should be assigned to
module Reckon
  class CosineSimilarity
    def initialize(options)
      @options = options
      @tokens = {}
      @accounts = Hash.new(0)
    end

    def add_document(account, doc)
      tokenize(doc).each do |n|
        (token, count) = n

        @tokens[token] ||= {}
        @tokens[token][account] ||= 0
        @tokens[token][account] += count
        @accounts[account] += count
      end
    end

    # find most similar documents to query
    def find_similar(query)
      (query_scores, corpus_scores) = td_idf_scores_for(query)

      query_vector = Vector.elements(query_scores, false)

      # For each doc, calculate the similarity to the query
      suggestions = corpus_scores.map do |account, scores|
        acct_vector = Vector.elements(scores, false)

        acct_query_dp = acct_vector.inner_product(query_vector)
        # similarity is a float between 1 and -1, where 1 is exactly the same and -1 is
        # exactly opposite
        # see https://en.wikipedia.org/wiki/Cosine_similarity
        # cos(theta) = (A . B) / (||A|| ||B||)
        # where A . B is the "dot product" and ||A|| is the magnitude of A
        # ruby has the 'matrix' library we can use to do these calculations.
        {
          similarity: acct_query_dp / (acct_vector.magnitude * query_vector.magnitude),
          account: account,
        }
      end.select { |n| n[:similarity] > 0 }.sort_by { |n| -n[:similarity] }

      LOGGER.info "most similar accounts: #{suggestions}"

      return suggestions
    end

    private

    def td_idf_scores_for(query)
      query_tokens = tokenize(query)
      corpus = Set.new
      corpus_scores = {}
      query_scores = []
      num_docs = @accounts.length

      query_tokens.each do |n|
        (token, _count) = n
        next unless @tokens[token]
        corpus = corpus.union(Set.new(@tokens[token].keys))
      end

      query_tokens.each do |n|
        (token, count) = n

        # if no other docs have token, ignore it
        next unless @tokens[token]

        ## First, calculate scores for our query as we're building scores for the corpus
        query_scores << calc_tf_idf(
          count,
          query_tokens.length,
          @tokens[token].length,
          num_docs
        )

        ## Next, calculate for the corpus, where our "account" is a document
        corpus.each do |account|
          corpus_scores[account] ||= []

          corpus_scores[account] << calc_tf_idf(
            (@tokens[token][account] || 0),
            @accounts[account].to_f,
            @tokens[token].length.to_f,
            num_docs
          )
        end
      end
      [query_scores, corpus_scores]
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
      mk_tokens(str).inject(Hash.new(0)) do |memo, n|
        memo[n] += 1
        memo
      end.to_a
    end

    def mk_tokens(str)
      str.downcase.tr(';', ' ').tr("'", '').split(/[^a-z0-9.]+/)
    end
  end
end
