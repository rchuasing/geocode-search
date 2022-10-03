#! /usr/bin/env ruby

require 'bundler/inline'
require 'csv'

gemfile do
  source 'https://rubygems.org'
  gem 'geocoder'
end

csv = CSV.read("#{Dir.pwd}/output.csv")
limit = 300
counter = 1
file_count = 1
file_contents = []
csv.each_with_index do |row, index|
  # Limit will dictate the number of rows per file
  if counter == 1 || counter > limit
    counter = 1
    file_count += 1
    file_contents[file_count] = []
  end
  if counter <= limit
    file_contents[file_count] << row
  end
  counter += 1
end

file_contents.each_with_index do |content, index|
  unless content.nil?
    CSV.open("#{Dir.pwd}/split/#{index + 1}_output.csv", 'wb') do |csv|
      content.each do |row|
        csv << row
      end
    end
  end
end

