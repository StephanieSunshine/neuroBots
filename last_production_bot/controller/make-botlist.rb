#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'pp'

PID = Process.pid 

#botlist = JSON.parse(open('http://www.neurobots.net/status').read)

File.open("botlist", "w") { |file| file.write(open('http://localhost/controller/status').read) }



