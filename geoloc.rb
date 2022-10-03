#! /usr/bin/env ruby

require 'bundler/inline'
require 'csv'
require 'net/http'
require 'uri'
require 'erb'
require 'json'

gemfile do
  source 'https://rubygems.org'
  gem 'geocoder'
end

def zillow(address)
  address_encoded = ERB::Util.url_encode(address)
  result = Net::HTTP.get URI('https://www.zillowstatic.com/autocomplete/v3/suggestions?q=' + address_encoded)
  JSON.parse(result)
end

addresses = []
complete_records = []
output = []
with_errors = []
included_state = ["MD"]
included_cities = ['Towson', 'Owings Mills', 'Catonsville', 'Dundalk', 'White Marsh', 'Essex', 'Pikesville', 'Timonium', 'Parkville', 'Woodlawn', 'Middle River', 'Cockeysville', 'Randallstown', 'Reisterstown', 'Rosedale', 'Perry Hall', 'Milford Mill', 'Arbutus', 'Edgemere', 'Overlea', 'Kingsville', 'Bowleys Quarters', 'Lochearn', 'Carney', 'Rossville', 'Hampton', 'Garrison']
csv = CSV.read("#{Dir.pwd}/input.csv")
csv.each do |row|
  addresses << row[0]
  complete_records << row
end
addresses.uniq!

pp "PROCESSING: #{addresses.length} addresses"

row_counter = 1
file_limit = 300
file_count = 1
addresses.each_with_index do |address, index|
  pp "FETCHING: #{address[0]} / PROGRESS: #{index + 1} out of #{addresses.length}"
  # result = Geocoder.search("#{address}, United States")
  # pp result
  # info = result.first
  # pp info
  # if !info.nil?
  #   street_address = "#{info.house_number} #{info.street}"
  #   city = info.city
  #   zipcode = info.postal_code
  #   state = 'VA'
  #   if included_state.include?(state) && included_cities.include?(city)
  #     pp 'INSERTING ADDRESS TO OUTPUT'
  #     row_data = [street_address, city, zipcode, state]
  #     output << row_data
  #   else
  #     with_errors << [address]
  #   end
  #   # pp row_data
  # else
  #   with_errors << [address]
  # end


  result = zillow(address)
  info = result["results"].first["metaData"] rescue nil
  pp info
  if !info.nil? && included_state.include?(info["state"]) && included_cities.include?(info['city'])
    row_data = [address, "#{info['streetNumber']} #{info['streetName']}", info['city'], info['zipCode'], info['state'] ]
    output << row_data
    # pp row_data
  else
    if info.nil?
      with_errors << [address]
    else
      with_errors << [address, "#{info['streetNumber']} #{info['streetName']}", info['city'], info['zipCode'], info['state']]
    end
  end

  # pp output
  if row_counter == file_limit
    file_count += 1
    row_counter = 1
  end


  CSV.open("#{Dir.pwd}/split/output_#{file_count}.csv", "wb") do |csv|
    pp "GENERATING OUTPUT ##{file_count}"
    output.each do |row|
      # pp row
      csv << row
      row_counter += 1
    end
  end


  CSV.open("#{Dir.pwd}/split/with_errors_#{file_count}.csv", "wb") do |csv|
    pp "GENERATING ERRORS ##{file_count}"
    with_errors.each do |row|
      csv << row
    end
  end

  sleep(1)
end





