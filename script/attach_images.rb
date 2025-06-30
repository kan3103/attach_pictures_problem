# This script benchmarks two methods:
# 1. attach_every_image: Attaches images one by one to a Post, 50 images per batch, repeated 10 times (total 500 images).
# 2. attach_array_images: Attaches an array of 50 images to a Post in one go, repeated 10 times (total 500 images).
# After each batch of 50 images, the script prints the execution time.
# The result will show that attaching images one by one becomes increasingly slower compared to attaching an array.
#
# Additional Notes:
# - The script resets the database before each method to ensure a clean state.
# - Requires Rails with Active Storage configured and a dummy image at `test/fixtures/files/dummy.png`.
# - Run the script using: `bin/rails runner script/attach_images.rb`
# - Observation: As the number of already attached images increases, the time to attach subsequent images becomes longer, especially when attaching images one by one.

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

def attach_every_image(dummy_path)
    post = before_attach
    sum = 0
    prev = nil
    (1..500).each_slice(50) do |batch|
        time = Benchmark.realtime do
            batch.each do |i|
                post.images.attach(io: File.open(dummy_path), filename: "image_#{i}.png", content_type: 'image/png')
            end
        end
        if prev.present?
            puts "Time difference: #{(time - prev).round(2)}s"
        end
        prev = time
        sum += time
        puts "Attached #{batch.last} images - Time taken: #{time.round(2)}s"
    end
    puts "Total time: #{sum.round(2)}s"
end

def attach_array_images(dummy_path)
    post = before_attach
    sum = 0
    prev = nil
    (1..10).each do |batch|
        array = Array.new(50) { |i| { io: File.open(dummy_path), filename: "image_#{batch}_#{i}.png", content_type: 'image/png' } }
        time = Benchmark.realtime do
            post.images.attach(array)
        end
        if prev.present?
            puts "Time difference: #{(time - prev).round(2)}s"
        end
        prev = time
        sum += time
        puts "Attached #{batch * 50} images - Time taken: #{time.round(2)}s"
    end
    puts "Total time: #{sum.round(2)}s"
end


attach_every_image(dummy_path)
attach_array_images(dummy_path)

