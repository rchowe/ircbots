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
end

class Carbon < IRCBot
	def initialize
		@db = CarbonDB.new "carbon.db"
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
								@db.store $1.downcase, expr
							when /^(.+?)<reply>(.+)$/
								debug_puts "Storing #{$1.strip} as #{$3.strip}"
								irc.send_msg_delay "OK, #{username}. I will reply to #{$1.strip} with #{$2.strip}."
								@db.store $1.strip.downcase, $2.strip
							when /^(say something random|random)$/
								if @memory.items == 0
									irc.send_msg_delay "I have nothing random to say"
								else
#									a = @memory.to_a.sort_by{rand}.slice(0...1)[0][1].to_s
#									puts a
									irc.send_msg_delay "No."
								end
							when /^hello$/
								irc.send_msg_delay "Hello, #{username}!"
						end
					
					# That might be in carbon's memory
					else
						response = @db.retrieve m.downcase
						irc.send_msg_delay response unless response.nil?
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
