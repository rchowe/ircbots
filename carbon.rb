#!/usr/bin/env ruby

require 'irc.rb'
require 'sqlite3'

class CarbonDB
	def initialize filename
		@db = SQLite3::Database.new filename
		create_table
	end
	
	def create_table
		@db.transaction do |db|
			begin
				db.execute("SELECT COUNT(*) FROM Carbon")
			rescue SQLite3::SQLException
				db.execute "CREATE TABLE Carbon (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, key TEXT NOT NULL, response TEXT NOT NULL)"
			end
		end
	end
	
	def store key, value
		@db.transaction do |db|
			db.execute "INSERT INTO Carbon VALUES (null, ?, ?)", key, value
		end
	end
	
	def retrieve key
		@db.get_first_value "SELECT response FROM Carbon WHERE key = ? ORDER BY RANDOM()", key
	end
	
	def size
		begin
			return @db.execute "SELECT COUNT(*) FROM Carbon"
		rescue SQLite3::SQLException
		end
	end
end

class Carbon < IRCBot
	def initialize
		@db = CarbonDB.new "carbon.db"
		@away = false
		
		@variables = { "$user" => Proc.new { @last_user }, "$time" => Proc.new { Time.now.hour.to_s + ":" + Time.now.min.to_s }}
	end
	
	def handle_server_msg irc, msg
		case msg
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/
			# Someone says something
				@last_user = $1
				m = $5.strip
				case m
					when /^carbon[:,] (.+)/
					# To carbon...
						expr = $1.strip
						case expr
							when /^(.+?) (is|are) (.+)/
								debug_puts "Storing #{$1} as #{expr}"
								irc.send_msg_delay "OK, #{@last_user}. #{$1} #{$2} #{$3}."
								@db.store $1.downcase, expr
							
							# Replies
							when /^(.+?)<reply>(.+)$/
								debug_puts "Storing #{$1} as #{$3}"
								irc.send_msg_delay "OK, #{@last_user}. I will reply to #{$1.strip} with #{$2.strip}."
								@db.store $1.strip.downcase, $2.strip
							
							when /^(.+?)<action>(.+)$/
								debug_puts "Storing #{$1} as #{$3}"
								irc.send_msg_delay "OK, #{@last_user}. I will reply to #{$1.strip} with the action #{$2.strip}."
								@db.store $1.strip.downcase, "\1ACTION #{$2.strip}\1"

							# Possesssives
							when /^(.+?)<'s> (.+)$/
								irc.send_msg_delay "OK, #{@last_user}. I will remember #{$1} as #{$1}'s #{$2}."
								@db.store $1.strip.downcase, "#{$1.strip}'s #{$2.strip}"
							
							# Random
							when /^(something random|random)$/
								if @db.size == 0
									irc.send_msg_delay "I have nothing random to say"
								else
#									a = @memory.to_a.sort_by{rand}.slice(0...1)[0][1].to_s
#									puts a
									irc.send_msg_delay "No."
								end
							when /^hello$/
								irc.send_msg_delay "Hello, #{@last_user}!"
						end
					
					# That might be in carbon's memory
					else
						response = @db.retrieve m.downcase
						irc.send_msg_delay replace_vars( response ) unless response.nil?
				end
		end
	end
	
	def replace_vars str
		@variables.each do |key, value|
			begin
				str[key] = value.call
			rescue IndexError
			end
		end
		str
	end
	
	def name
		'carbon'
	end
	
	def fullname
		"Carbon"
	end
end

IRC.run 'rcnet.ath.cx', 6667, 'carbon', '#isp', Carbon.new
