#!/usr/bin/env ruby

require './irc.rb'
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
				retry
			end
			
			begin
				db.execute("SELECT COUNT(*) FROM Inventory")
			rescue SQLite3::SQLException
				db.execute "CREATE TABLE Inventory (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, item TEXT NOT NULL)"
				retry
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
	
	def random_factoid
		@db.get_first_value "SELECT response FROM Carbon ORDER BY RANDOM()"
	end
	
	def store_item item
		@db.transaction do |db|
			db.execute "INSERT INTO Inventory VALUES (null, ?)", item
		end
	end
	
	def pop_random_item
		row = @db.get_first_row "SELECT id, item FROM Inventory ORDER BY RANDOM() LIMIT 0, 1"
		puts row
		return nil if row.nil?
		@db.execute "DELETE FROM Inventory WHERE id = ?", row[0]
		return row[1]
	end
	
	def size
		begin
			return @db.get_first_value "SELECT COUNT(*) FROM Carbon"
		rescue SQLite3::SQLException
		end
	end
	
	def inventory_size
		return @db.get_first_value "SELECT COUNT(*) FROM Inventory"
	end
end

class Carbon < IRCBot
	def initialize
		@db = CarbonDB.new "carbon.db"
		@away = false
		@max_inventory_size = 2
		
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
								irc.send_msg_delay "OK, #{@last_user}."
								@db.store $1.strip.downcase, $2.strip
							
							when /^(.+?)<action>(.+)$/
								debug_puts "Storing #{$1} as #{$3}"
								irc.send_msg_delay "OK, #{@last_user}."
								@db.store $1.strip.downcase, "\1ACTION #{$2.strip}\1"

							# Possesssives
							when /^(.+?)<'s> (.+)$/
								irc.send_msg_delay "OK, #{@last_user}."
								@db.store $1.strip.downcase, "#{$1.strip}'s #{$2.strip}"
							
							# Item Requests
							when /^give me (something|an item)([,]? please[\.?]?)?$/
								item = @db.pop_random_item
								if item.nil?
									irc.send_msg_delay "I have nothing to give you!"
									return
								end
								irc.send_msg_delay "\1ACTION gives #{@last_user} #{item}.\1"
							
							# Random
							when /^(something random|random)[\.?]?$/
								if @db.size == 0
									irc.send_msg_delay "I have nothing random to say"
								else
#									a = @memory.to_a.sort_by{rand}.slice(0...1)[0][1].to_s
#									puts a
									irc.send_msg_delay "No."
								end
							when /^hello[\.]?$/
								irc.send_msg_delay "Hello, #{@last_user}!"
							else
								irc.send_msg_delay @db.random_factoid
						end
					
					when /^[\1]ACTION gives carbon (.+?)[\.]?[\1]$/
						# Strip out articles for display
						item = $1.strip
						item_s = item.gsub( /^(the|a|)/, '' ).strip
					
						if @db.inventory_size.to_i < @max_inventory_size
							irc.send_msg_delay "\1ACTION takes #{@last_user}'s #{item_s}.\1"
						else
							irc.send_msg_delay "\1ACTION takes #{@last_user}'s #{item_s} and gives #{@last_user} #{@db.pop_random_item}.\1"
						end
						@db.store_item $1.strip
					
					when /^[\1]ACTION (.+?) carbon[\.]?[\1]$/
						irc.send_msg_delay "\1ACTION #{$1} #{@last_user}\1"
					
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

IRC.run 'localhost', 6667, 'carbon', '#test', Carbon.new
