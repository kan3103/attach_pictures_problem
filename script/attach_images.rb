# This script attaches 100 dummy image files to the first Post record in the database.
# If no Post exists, it creates one with the title "Test" and content "Test".
# Images are attached in batches of 20 for performance measurement.
# For each batch, the script measures and outputs the time taken to attach the images.
# 
# Prerequisites:
# - The script assumes a Rails environment with Active Storage configured.
# - A dummy image file must exist at 'tmp/dummy.png' relative to the Rails root.
#
# Usage:
# Run this script 'bin/rails runner script/attach_images.rb'
require_relative '../config/environment'
require 'benchmark'

post = Post.first_or_create!(title: "Test", content: "Test")

dummy_path = Rails.root.join('test/fixtures/files', 'dummy.png')
dummy_path2 = Rails.root.join('test/fixtures/files', 'dummy2.png')

(1..50).each_slice(10) do |batch|
  time = Benchmark.realtime do
    batch.each do |i|
    post.images.attach([
      { io: File.open(dummy_path), filename: "image_#{i}.png", content_type: 'image/png' },
      { io: File.open(dummy_path2), filename: "image2_#{i}.png", content_type: 'image/png' }
    ])
    end
  end
  puts "Attached #{batch.last*2} images - Time taken: #{time.round(2)}s"
end
