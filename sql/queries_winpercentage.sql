with winning_percent as (
  select
  team
  , year
  , count(CASE WHEN won THEN 1 ELSE null END) as wins
  , count(game_date) as games
  , count(CASE WHEN won THEN 1 ELSE null END) / count(game_date)::decimal as winning_percent

  from
  (select
    home_team as team
  , visiting_team as vs
  , case when visiting_team_score < home_team_score
    then true::boolean
    else false::boolean
    end as won
  , home_team_score as runs
  , visiting_team_score as vs_runs
  , home_team_score - visiting_team_score as run_delta
  , year::int
  , game_date

  from game_logs

  union

  select
    visiting_team as team
  , home_team as vs
  , case when visiting_team_score > home_team_score
    then true::boolean
    else false::boolean
    end as won
  , visiting_team_score as runs
  , home_team_score as vs_runs
  , visiting_team_score - home_team_score as run_delta
  , year::int
  , game_date


  from game_logs
  ) x
  group by team, year
  order by winning_percent desc
)

, stats_year_team as (
  select 1
  , team_lahman_id
  , t.retro_id as team
  , year::int
  , sum(at_bats) at_bats
  , sum(home_runs) home_runs
  , sum(triples) triples
  , sum(doubles) doubles
  , sum(singles) singles
  , ( sum(walks) + sum(intentional_walks) + sum(hit_by_pitch) ) / sum(at_bats)::decimal on_base_non_hit
  , sum(hits) / sum(at_bats)::decimal batting_average
  , ( sum(hits) + sum(walks) + sum(intentional_walks) + sum(hit_by_pitch) ) / sum(at_bats)::decimal on_base_percentage
  from batting_stats s
  join teams t on t.lahman_id = s.team_lahman_id
  group by team_lahman_id, year, t.retro_id
)

select wp.team, wp.year, wp.winning_percent, sy.on_base_non_hit, sy.batting_average, sy.on_base_percentage
from winning_percent wp
join stats_year_team sy
  on sy.team = wp.team
  and sy.year = wp.year
  and sy.year = 2014
;
