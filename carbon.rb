#!/usr/bin/env ruby

require 'irc.rb'

class Carbon
	def handle_server_input irc, msg
		case msg
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/
			# Someone says something
				username = $1
				m = $5.strip
				case m
					when /^[Cc]arbon[,:]\w(.+)/
					# To carbon...
						case $1.strip
							when /^(.+?)\w(is|are)\w(.+)/
								debug_puts "Storing #{$1} as #{$3}"
								@memory[$1.downcase] = $3
						end
					
					# That might be in carbon's memory
					else
						return unless @memory.has_key? m.downcase
						
				end
		end
	end
end
