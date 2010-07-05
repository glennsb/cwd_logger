#!/usr/bin/env ruby1.9

# Stuart Glenn 2010-07-04
# Loggin directory frequency & access time
# based on some ideas from http://matt.might.net/articles/console-hacks-exploiting-frequency/
# You will probably want to change that database name below

require 'mongo'

@collection = Mongo::Connection.new("localhost").db("glennsb")['logged_dirs']

def log_current
  path = Dir.getwd
  unless path == ENV['HOME'] 
    doc = {'$set' => {:path => path, :last_access => Time.now}, '$inc' => {:count => 1}}
    @collection.update({:path => path}, doc, {:upsert => true})
  end
end

def frequency(target = nil)
  dirs = @collection.find({},{:limit => 10, :sort =>[:count,Mongo::DESCENDING]})
  change_to_dir(dirs,target)
end

def recently(target)
  dirs = @collection.find({},{:limit => 10, :sort =>[:last_access,Mongo::DESCENDING]})  
  change_to_dir(dirs,target)
end

def change_to_dir(dirs,target=nil)
  if target && target.to_i < dirs.count
    require 'shellwords'
    dir = dirs.skip(target.to_i).next_document["path"]
    # dir = Shellwords.shellescape(dir)
    puts "#{dir}"
  else
    puts "usage: #{File.basename($0)} index"
    dirs.each_with_index do |doc,i|
      puts "#{i}- #{doc["path"]}"
    end
  end
end

case $0
  when /log_cwd.rb/ #test for it first since it will be the most common
    log_current()
  when /cwd_frequency.rb/
    frequency(ARGV.shift)
  when /cwd_recently.rb/
    recently(ARGV.shift)
  else
    log_current()
end
