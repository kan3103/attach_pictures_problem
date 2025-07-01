require_relative '../config/environment'
require_relative '../config/application'

require 'benchmark'

Rails.application.load_tasks

def before_attach
    Rake::Task['db:reset'].reenable
    Rake::Task['db:reset'].invoke
end

dummy_path = Rails.root.join('test/fixtures/files', 'dummy.png')

def attach_in_batches(dummy_path, num: 2, total: 1000, batch_size: 200)
    times = 0
    1..num.times do |n|
        post = Post.create!(title: "Batch #{n + 1}", content: "Attaching images in batches")
        temp = Benchmark.realtime do
            (0...total).each_slice(batch_size) do |batch|
                files = batch.map { |i| { io: File.open(dummy_path), filename: "image_#{i}.png", content_type: 'image/png' } }
                post.images.attach(files)
            end
        end
        puts "Batch #{n + 1} - Attached #{total} images in batches of #{batch_size} - Time taken: #{temp.round(2)}s"
        times += temp
    end
    puts "Sum of all batches: #{times.round(2)}s"
end

def attach_insert_all(dummy_path, num: 2, total: 1000)
    times = 0
    1..num.times do |n|
        post = Post.create!(title: "Fast attach #{n + 1}", content: "Attaching images without reload")
        temp = Benchmark.realtime do
            blobs = total.times.map do |i|
                ActiveStorage::Blob.create_and_upload!(
                    io: File.open(dummy_path),
                    filename: "image_#{i}.png",
                    content_type: 'image/png',
                    identify: false
                )
            end 
            now = Time.current
            attachments = blobs.map do |blob|
                {
                    name: "images",
                    record_type: "Post",
                    record_id: post.id,
                    blob_id: blob.id,
                    created_at: now
                }
            end
            ActiveStorage::Attachment.insert_all!(attachments)
        end
        puts "Fast attach #{n + 1} - Attached 500 images using insert_all! - Time taken: #{temp.round(2)}s"
        times += temp
    end
    puts "Sum of all fast attaches: #{times.round(2)}s"
end

before_attach
attach_in_batches(dummy_path)
attach_insert_all(dummy_path)