#!/usr/bin/env ruby

require 'pp'

require 'reckon'

ledger_file = ARGV[0]
account = ARGV[1]
seed = ARGV[2] ? ARGV[2].to_i : Random.new_seed

ledger = Reckon::LedgerParser.new(File.new(ledger_file))
matcher = Reckon::CosineSimilarity.new({})

train = []
test = []

def has_account(account, entry)
  entry[:accounts].map { |a| a[:name] }.include?(account)
end

entries = ledger.entries.select { |e| has_account(account, e) }

r = Random.new(seed)
entries.length.times do |i|
  r.rand < 0.9 ? train << i : test << i
end

train.each do |i|
  entry = entries[i]
  entry[:accounts].each do |a|
    matcher.add_document(
      a[:name],
      [entry[:desc], a[:amount]].join(" ")
    )
  end
end

result = [nil] * test.length
test.each do |i|
  entry = entries[i]
  matches = matcher.find_similar(
    entry[:desc] + " " + entry[:accounts][0][:amount].to_s
  )

  if !matches[0] || !has_account(matches[0][:account], entry)
    result[i] = [entry, matches]
  end
end

# pp result.compact
puts "using #{seed} as random seed"
puts "true: #{result.count(nil)} false: #{result.count { |v| !v.nil? }}"
