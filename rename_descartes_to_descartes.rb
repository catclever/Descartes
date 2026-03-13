# frozen_string_literal: true

require "fileutils"
require "pathname"

# Renaming directories and files
Dir.glob("**/*descartes*").sort_by(&:length).reverse.each do |path|
  next if path.start_with?(".git") || path.start_with?(".agent")

  new_path = path.gsub("descartes", "descartes")
  puts "Renaming #{path} to #{new_path}"
  if File.directory?(path)
  end
  FileUtils.mv(path, new_path)
end

# Replacing contents
Dir.glob("**/*").each do |path|
  next if File.directory?(path)
  next if path.start_with?(".git/") || path.start_with?(".agent/") || path.end_with?(".lock") || File.extname(path) == ".png"

  content = File.read(path)
  new_content = content.gsub("Descartes", "Descartes").gsub("descartes", "descartes")
  if content != new_content
    puts "Updating contents of #{path}"
    File.write(path, new_content)
  end
end

puts "Done mass renaming in Descartes."
