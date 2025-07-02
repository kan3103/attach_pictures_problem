# How to run this script:
#
# 1. Ensure you have set up the Rails environment and the required database.
# 2. Place a dummy image file named 'dummy.png' in the 'test/fixtures/files' directory of your Rails project.
# 3. Run this script using the following command from your Rails project root:
#     bin/rails runner script/n_1_queries.rb
#
# The script will:
# - Reset the database and create a sample Post.
# - Attach 500 images to the Post, first one by one, then in batches of 50.
# - Measure and print the time taken for each method, and compare their performance.
require_relative '../config/environment'
require_relative '../config/application'

require 'benchmark'

Rails.application.load_tasks

def before_attach
    Rake::Task['db:reset'].reenable
    Rake::Task['db:reset'].invoke
    Post.first_or_create!(title: "Test", content: "Test")
end

dummy_path = Rails.root.join('test/fixtures/files', 'dummy.png')

def attach_one_by_one(dummy_path, total: 500)
    post = before_attach
    Benchmark.realtime do
        total.times do |i|
            post.images.attach(io: File.open(dummy_path), filename: "image_#{i}.png", content_type: 'image/png')
        end
    end
end

def attach_in_batches(dummy_path, total: 500, batch_size: 50)
    post = before_attach
    Benchmark.realtime do
        (0...total).each_slice(batch_size) do |batch|
            files = batch.map { |i| { io: File.open(dummy_path), filename: "image_#{i}.png", content_type: 'image/png' } }
            post.images.attach(files)
        end
    end
end

time_one_by_one = attach_one_by_one(dummy_path)
puts "Attach one by one: #{time_one_by_one.round(2)}s"

time_in_batches = attach_in_batches(dummy_path)
puts "Attach in batches: #{time_in_batches.round(2)}s"

if time_one_by_one > time_in_batches
    puts "Batch attaching is faster by #{(time_one_by_one - time_in_batches).round(2)}s"
else
    puts "Attaching one by one is faster by #{(time_in_batches - time_one_by_one).round(2)}s"
end
