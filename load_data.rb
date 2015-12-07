#!/usr/bin/env ruby
require 'pg'
require 'csv'


conn = PG.connect( dbname: 'baseball_data' )
conn.prepare( "insert_game_log",
              "insert into game_logs \
                    ( \
                      game_date, \
                      year, \
                      visiting_team, \
                      home_team, \
                      visiting_team_score, \
                      home_team_score, \
                      visiting_team_lineup, \
                      home_team_lineup \
                    ) \
               values ($1, $2, $3, $4, $5, $6, $7, $8)")

conn.prepare( "insert_player_game_log",
              "insert into player_game_logs \
                    ( \
                      game_date, \
                      visiting_team, \
                      home_team, \
                      player_name, \
                      player_id, \
                      position, \
                      is_win, \
                      is_home_team \
                    ) \
               values ($1, $2, $3, $4, $5, $6, $7, $8)")

conn.prepare( "insert_players",
              "insert into players \
                    ( \
                      name, \
                      lahman_id, \
                      retro_id, \
                      birthdate \
                    ) \
               values ($1, $2, $3, $4)")

conn.prepare( "insert_teams",
              "insert into teams \
                    ( \
                      name, \
                      lahman_id, \
                      retro_id \
                    ) \
               values ($1, $2, $3)")


conn.prepare( "insert_batting_stats",
             "insert into batting_stats \
                   ( \
                     player_lahman_id, \
                     year, \
                     stint, \
                     team_lahman_id, \
                     games, \
                     at_bats, \
                     home_runs, \
                     triples, \
                     doubles, \
                     singles, \
                     hits, \
                     walks, \
                     intentional_walks, \
                     strike_outs, \
                     hit_by_pitch, \
                     sac_hits, \
                     sac_flys \
                   ) \
              values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)")

def do_insert(data, conn)

  conn.exec_prepared("insert",
                      [
                        data[ :game_date ],
                        data[ :visiting_team ],
                        data[ :home_team ],
                        data[ :visiting_team_score ],
                        data[ :home_team_score ],
                        data[ :visiting_team_lineup],
                        data[ :home_team_lineup]
                      ]
                     )
end

class PlayerGameLog
  attr_accessor( :player_name,
                 :player_id,
                 :position,
                 :game_date,
                 :home_team,
                 :visiting_team,
                 :is_home_team,
                 :is_win )


  def initialize attr
    @player_name   = attr[:player_name]
    @player_id     = attr[:player_id]
    @position      = attr[:position]
    @game_date     = attr[:game_date]
    @home_team     = attr[:home_team]
    @visiting_team = attr[:visiting_team]
    @is_home_team  = attr[:is_home_team]
    @is_win        = attr[:is_win]
  end

  def unique_id
    "#{game_date}#{home_team}#{player_id}"
  end

  def hash
    unique_id.hash
  end

  def eql? other
    self == other
  end

  def == other
    self.unique_id == other.unique_id
  end

  def to_s
    "#{game_date} #{player_name} #{is_home_team ? home_team : visiting_team} #{is_win}"
  end

  def save(conn)

      conn.exec_prepared("insert_player_game_log",
                          [
                            game_date,
                            visiting_team,
                            home_team,
                            player_name,
                            player_id,
                            position,
                            is_win,
                            is_home_team
                          ]
                         )
  end
end

class GameLogLine
  attr_reader :line

  def initialize line
    @line = line
  end

  def home_team_lineup
    (position_player_ids[10..18].map do |id|
      build_player(id).player_name
    end << home_pitcher.player_name).uniq
  end

  def visiting_team_lineup
    (position_player_ids[0..10].map do |id|
      build_player(id).player_name
    end << visiting_pitcher.player_name).uniq
  end

  def home_pitcher
    build_player line[103]
  end

  def visiting_pitcher
    build_player line[101]
  end

  def get_player_from player_id

    players_line = line[101..158]
    index        = players_line.index(player_id)
    id           = player_id
    name         = players_line[index+1]

    # if this is a position player
    if index > 3
      position     = players_line[index+2]
       # 3 for the pitcher places (0-3), 9 * 3 for 9 players each with id,name,position
      is_home      = index > ( 3 + (9 * 3) )

    # else this is a pitcher
    else
      position     = "1"
      is_home      = index > 1 # home pitcher is from 2-4
    end

    home_winner  = home_team_score > visiting_team_score

    {
      id: id,
      name: name,
      position: position,
      is_home: is_home,
      is_win: !(home_winner != is_home)
    }
  end

  def players
    all_players = position_players
    all_players << visiting_pitcher
    all_players << home_pitcher
    all_players.uniq
  end

  def position_players
    position_player_ids.map do |player_id|
      build_player player_id
    end
  end

  def position_player_ids
    players_line = line[105..158]
    # get every third element starting with the first one
    players_line.select.with_index{|_,i| i%3 == 0}
  end

  def position_player_ids
    players_line = line[105..158]
    # get every third element starting with the first one
    players_line.select.with_index{|_,i| i%3 == 0}
  end


  def visiting_team
    line[ 3 ]
  end

  def home_team
    line[ 6 ]
  end

  def home_team_score
    line[ 10 ]
  end

  def visiting_team_score
    line[ 9 ]
  end

  def game_date
    DateTime.strptime(line[ 0 ], "%Y%m%d").iso8601
  end

  def year
    DateTime.strptime(line[ 0 ], "%Y%m%d").year
  end

  def build_player player_id
    player = get_player_from(player_id)
    PlayerGameLog.new({
        player_name:   player[:name],
        player_id:     player[:id],
        position:      player[:position],
        game_date:     game_date,
        home_team:     home_team,
        visiting_team: visiting_team,
        is_home_team:  player[:is_home],
        is_win:        player[:is_win]
      })
  end

  def save(conn)

      conn.exec_prepared("insert_game_log",
                          [
                            game_date,
                            year,
                            visiting_team,
                            home_team,
                            visiting_team_score,
                            home_team_score,
                            visiting_team_lineup.join(','),
                            home_team_lineup.join(',')
                          ]
                         )
  end
end

puts ''
puts 'loading retro game log data'
Dir[ 'data/**/GL20*.*' ].each do |file|

  puts "running file: #{file}"
  CSV.foreach(file, :headers => false) do |c|
    gl = GameLogLine.new(c)

    players = gl.players

    players.each do |p|
      p.save(conn)
    end
    gl.save(conn)
  end
end



puts ''
puts 'loading lahman master data'
CSV.foreach('data/lahman/Master.csv', :headers => true) do |c|

  by = c['birthYear'].to_i
  bd = c['birthDay'].to_i == 0 ? 1 : c['birthDay'].to_i
  bm = c['birthMonth'].to_i == 0 ? 1 : c['birthMonth'].to_i

  conn.exec_prepared("insert_players",
                      [
                        "${c['nameFirst']} ${c['nameLast']}",
                        c['playerID'],
                        c['retroID'],
                        DateTime.new(by,bm,bd).iso8601
                      ]
                     )
end


puts 'loading lahman team data'
teams = {}
CSV.foreach('data/lahman/Teams.csv', :headers => true) do |c|

  if c['yearID'].to_i > 1990
    unless teams["#{c['name']}#{c['teamID']}#{c['teamIDretro']}"]
      conn.exec_prepared("insert_teams",
                          [
                            c['name'],
                            c['teamID'],
                            c['teamIDretro']
                          ]
                         )
      teams["#{c['name']}#{c['teamID']}#{c['teamIDretro']}"] = true
    end
  end

end

puts 'loading lahman batting data'
CSV.foreach('data/lahman/Batting.csv', :headers => true) do |c|

  if c['yearID'].to_i > 1990
    conn.exec_prepared("insert_batting_stats",
                        [
                          c['playerID'],
                          c['yearID'],
                          c['stint'],
                          c['teamID'],
                          c['G'],
                          c['AB'],
                          c['HR'].to_i,
                          c['3B'].to_i,
                          c['2B'].to_i,
                          c['H'].to_i - c['HR'].to_i - c['3B'].to_i - c['2B'].to_i,
                          c['H'],
                          c['BB'],
                          c['IBB'],
                          c['SO'],
                          c['HBP'],
                          c['SH'],
                          c['SF']
                        ]
                       )
  end

end
puts ''
