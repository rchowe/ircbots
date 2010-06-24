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
						expr = $1.strip
						case expr
							when /^(.+?) (is|are) (.+)/
								debug_puts "Storing #{$1} as #{expr}"
								irc.send_msg_delay "OK, #{username}. #{$1} #{$2} #{$3}."
								@memory[$1.downcase] = expr
							when /^(.+?)<reply>(.+)$/
								debug_puts "Storing #{$1} as #{$3}"
								irc.send_msg_delay "OK, #{username}. I will reply to #{$1} with #{$2}."
								@memory[$1.downcase] = $2
							when /^(say something random|random)$/
								if @memory.size == 0
									irc.send_msg_delay "I have nothing random to say"
								else
									a = @memory.to_a.sort_by{rand}.slice(0...1)[0][1].to_s
									puts a
									irc.send_msg_delay a
								end
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
