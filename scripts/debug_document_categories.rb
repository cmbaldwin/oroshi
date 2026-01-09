# frozen_string_literal: true

# Debug script to check document categories in production
puts "\n=== Document Categories Debug ==="
puts "\nSettings in database:"
setting = Setting.find_by(name: 'document_categories')
if setting
  puts "Found setting: #{setting.inspect}"
  puts "Settings hash: #{setting.settings.inspect}"
else
  puts "No 'document_categories' setting found in database!"
end

puts "\n\nDocument.categories result:"
puts Document.categories.inspect

puts "\n\nAll documents and their categories:"
Document.find_each do |doc|
  puts "ID: #{doc.id}, Name: #{doc.name}, Category: #{doc.category}"
end

puts "\n\nGrouped by category:"
grouped = Document.grouped_by_category
grouped.each do |category_key, documents|
  puts "#{category_key}: #{documents.count} documents"
  documents.each do |doc|
    puts "  - #{doc.name}"
  end
end

puts "\n\nDocuments by actual category values in DB:"
Document.group(:category).count.each do |category, count|
  puts "#{category}: #{count} documents"
end
