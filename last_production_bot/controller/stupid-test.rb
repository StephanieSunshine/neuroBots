#!/usr/bin/env ruby

require 'pp'

class Stupid
	attr_accessor :aa, :bb, :cc, :dd
  def initialize(name, artist, duration, something)
		self.aa = name
  	self.bb = artist
  	self.cc = duration
		self.dd = something
	end
end

def make_array_of_stupid
my_output = []
	(1..10).each do |x|
	my_output.push(Stupid.new(1,2,3,4))
	end
return my_output
end

pp make_array_of_stupid
