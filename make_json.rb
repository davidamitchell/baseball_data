#!/usr/bin/env ruby
require 'pg'
require 'json'

conn = PG.connect( dbname: 'baseball_data' )

select_query = %{
  SELECT  visiting_team,
          home_team,
          visiting_team_score,
          home_team_score,
          visiting_team_lineup,
          home_team_lineup
          from game_logs
          order by game_date asc
}.split.join(" ")


players = Hash.new{ |h,k| h[k] = {wins:0, games: 0, percent: 0.0} }

conn.exec( select_query ) do |result|
  result.each do |row|

    visiting_team        = row['visiting_team']
    home_team            = row['home_team']
    visiting_team_score  = row['visiting_team_score']
    home_team_score      = row['home_team_score']
    visiting_team_lineup = row['visiting_team_lineup']
    home_team_lineup     = row['home_team_lineup']

    home_winner = home_team_score > visiting_team_score
    visiting_team_lineup.split(',').uniq.each do |player|
      players[player][:games] += 1
      players[player][:team]   = visiting_team
      players[player][:wins]  += 1 unless home_winner
    end

    home_team_lineup.split(',').uniq.each do |player|
      players[player][:games] += 1
      players[player][:team]   = home_team
      players[player][:wins]  += 1 if home_winner
    end


  end
end

players_array = []
players = players.delete_if{|k,v| v[:games] < 200}
players = players.each{|k,v| v[:percent] = 1.0 * v[:wins] / v[:games]}
players = players.sort_by{|k,v| v[:percent]}.reverse
# players = players.sort_by{|k,v| v[:percent]}

players.each do |name, data|
  players_array << {
    name: name,
    team: data[:team],
    wins: data[:wins],
    games: data[:games],
    percent: data[:percent]
  }
end

File.open( 'www/data.json', "w" ) { |f| f.write( players_array.to_json )}
# players_array.each_with_index do |player, index|
#   puts "#{player} - #{index}"
# end
