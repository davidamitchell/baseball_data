drop table if exists game_logs;
create table game_logs (
  game_date text,
  year text,
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


drop table if exists players;
create table players (
  name text,
  lahman_id text,
  retro_id text,
  birthdate text
);

drop table if exists teams;
create table teams (
  name text,
  lahman_id text,
  retro_id text
);

drop table if exists batting_stats;
create table batting_stats (
  player_lahman_id text,
  year text,
  stint text,
  team_lahman_id text,
  games int,
  at_bats int,
  home_runs int,
  triples int,
  doubles int,
  singles int,
  hits int,
  walks int,
  intentional_walks int,
  strike_outs int,
  hit_by_pitch int,
  sac_hits int,
  sac_flys int
);
