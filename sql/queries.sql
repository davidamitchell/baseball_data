-- select count(*) from game_logs;
--
--
-- select * from game_logs limit 2;


-- select *
-- from game_logs gl
-- join teams ht on ht.retro_id = gl.home_team
-- join teams vt on vt.retro_id = gl.visiting_team
-- join batting_stats hts on hts.team_lahman_id = gl.home_team
--   and hts.year = gl.year
-- join batting_stats vts on vts.team_lahman_id = gl.home_team
--   and vts.year = gl.year
-- limit 10;
--
--
-- select game_date, substring( game_date, 0, 5) from game_logs limit 10;
--
-- select * from batting_stats
-- where year = '2014' limit 2;
--
-- select 1
-- , team_lahman_id
-- , sum(at_bats) at_bats
-- , sum(home_runs) home_runs
-- , sum(triples) triples
-- , sum(doubles)
-- , sum(singles)
-- , sum(walks) + sum(intentional_walks) + sum(hit_by_pitch)
-- , sum(hits) / sum(at_bats)::decimal
-- , ( sum(hits) + sum(walks) + sum(intentional_walks) + sum(hit_by_pitch) ) / sum(at_bats)::decimal
-- from batting_stats
-- where 1=1
-- -- and team_lahman_id = 'BOS'
-- and year = '2014'
-- group by team_lahman_id, year
-- order by ( sum(hits) + sum(walks) + sum(intentional_walks) + sum(hit_by_pitch) ) / sum(at_bats)::decimal desc;


with stats_year_team as (
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
, game_wins as (

  select count(game_date) as wins, year, winner as team from (
    select
    distinct
    year::int
    , game_date
    , visiting_team
    , home_team
    , visiting_team_score
    , home_team_score
    , case when visiting_team_score > home_team_score
      then visiting_team
      else home_team
      end as winner
    from game_logs
  ) x
  group by year, team
)


select * from
stats_year_team s
join game_wins w on s.team = w.team
  and s.year = w.year
where s.year = 2014
order by on_base_percentage desc;
