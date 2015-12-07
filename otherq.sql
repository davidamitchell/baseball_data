
select * from (
  select

  year
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
where year = '2014'
and winner = 'BAL';

select count(*) from game_logs;
