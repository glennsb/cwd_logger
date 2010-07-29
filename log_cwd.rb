#!/usr/bin/env ruby1.9

# Stuart Glenn 2010-07-04
# Loggin directory frequency & access time
# based on some ideas from http://matt.might.net/articles/console-hacks-exploiting-frequency/
# You will probably want to change that database name below

require 'mongo'

@collection = Mongo::Connection.new("localhost").db("glennsb")['logged_dirs']

def log_current
  path = ENV["PWD"]
  unless path == ENV['HOME'] 
    doc = {'$set' => {:path => path, :last_access => Time.now}, '$inc' => {:count => 1}}
    @collection.update({:path => path}, doc, {:upsert => true})
  end
end

def frequency(target = nil)
  dirs = @collection.find({},{:limit => 15, :sort =>[:count,Mongo::DESCENDING]})
  change_to_dir(dirs,target)
end

def dampen_frequency()
  @collection.find().each do |doc|
    doc['count'] = doc['count']/2.0
    @collection.update({:_id => doc['_id']},doc)
  end
end

# clear out oldest dirs with a threshold left in count
# we limit to a % of the total collection & only do if that % is over a certain number
def remove_dead()
  limit = (0.1*@collection.count).to_i
  return if limit <= 15
  @collection.find({:count  =>  { "$lte" =>  0.25 }}, {:limit => limit, :sort =>[:last_access,Mongo::ASCENDING]}).each do |doc|
    puts "Forgetting about #{doc['path']}"
    @collection.remove({:_id => doc['_id']})
  end
end

def recently(target)
  dirs = @collection.find({},{:limit => 15, :sort =>[:last_access,Mongo::DESCENDING]})  
  change_to_dir(dirs,target)
end

def change_to_dir(dirs,target=nil)
  if target && target.to_i < dirs.count
    dir = dirs.skip(target.to_i).next_document["path"]
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
  when /cwd_dampen_frequency.rb/
    dampen_frequency()
    remove_dead()
  else
    log_current()
end
