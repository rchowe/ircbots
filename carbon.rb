#!/usr/bin/env ruby

require 'irc.rb'

class Carbon < IRCBot
	def initialize
		@memory = {}
		@away = false
	end
	
	def handle_server_msg irc, msg
		case msg
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/
			# Someone says something
				username = $1
				m = $5.strip
				case m
					when /^carbon[:,] (.+)/
					# To carbon...
						case $1.strip.downcase
							when /^(.+?) [^\\](is|are) (.+)/
								debug_puts "Storing #{$1} as #{$3}"
								irc.send_msg_delay "OK, #{username}. #{$1} is #{$3}."
								@memory[$1.downcase] = $3
							when /^hello$/
								irc.send_msg_delay "Hello, #{username}!"
						end
					
					# That might be in carbon's memory
					else
						return unless @memory.has_key? m.downcase
						irc.send_msg_delay @memory[m.downcase]
				end
		end
	end
	
	def name
		'carbon'
	end
	
	def fullname
		"Carbon"
	end
end

IRC.run 'rcnet.ath.cx', 6667, 'carbon', '#isp', Carbon.new
