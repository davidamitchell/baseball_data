drop table if exists game_logs;
create table game_logs (
  game_date text,
  visiting_team text,
  home_team text,
  visiting_team_score int,
  home_team_score int,
  visiting_team_lineup text,
  home_team_lineup text
);

drop table if exists player_game_logs;
create table player_game_logs (
  game_date text,
  visiting_team text,
  home_team text,
  player_name text,
  player_id text,
  position text,
  is_win boolean,
  is_home_team boolean
);
