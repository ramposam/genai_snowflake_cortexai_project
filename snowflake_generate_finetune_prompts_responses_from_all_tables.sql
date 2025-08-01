
-- Run all the ddls, dmls available on each mark down file
-- Then run the below query to get sql queries which generates prompts and response that can be used to create trained tables


-- Query to generate select with expression for each row on a table
-- Generate fro all the available tables
-- when you you execute generate query, it gives you predicted prompts, responses for each row


show tables ->>
show columns  ->>
create or replace temporary table t_select_query as
with cols as ( select * from $1) ,
tabls as (select * from  $2)
select t."name",'create or replace table t_'||t."name"||'_prompt_reponses as
with table_results as (select snowflake.cortex.complete(''CLAUDE-3-5-SONNET'',''I am providing input data with column name and it''''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:''|| '||listagg(' '''||c."column_name"||':''||'||c."column_name",'||'';''||' )||'||''Response:'') as output from '|| t."name"||'),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, ''\\{[^\\{\\}]+\\}'')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);' as query  from tabls t
join cols c   on (c."table_name" = t."name")
where c."table_name" not in ('T_DOCUMENT_CHUNKS_EMBEDDINGS','T_DOCUMENTS','T_DOCUMENT_CHUNKS','T_ALL_COMBINED')
group by t."name";

-- When above query executes it results one of the response as below query


create or replace table T_CLOSE_VICTORY_MARGINS_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'WINNER_NAME:'||WINNER_NAME||';'|| 'WINNER_PARTY:'||WINNER_PARTY||';'|| 'WINNER_VOTES:'||WINNER_VOTES||';'|| 'WINNER_VOTE_SHARE:'||WINNER_VOTE_SHARE||';'|| 'RUNNER_UP_NAME:'||RUNNER_UP_NAME||';'|| 'RUNNER_UP_PARTY:'||RUNNER_UP_PARTY||';'|| 'RUNNER_UP_VOTES:'||RUNNER_UP_VOTES||';'|| 'RUNNER_UP_VOTE_SHARE:'||RUNNER_UP_VOTE_SHARE||';'|| 'MARGIN_OF_VICTORY:'||MARGIN_OF_VICTORY||';'|| 'MARGIN_PERCENTAGE:'||MARGIN_PERCENTAGE||'Response:') as output from T_CLOSE_VICTORY_MARGINS),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_HIGHEST_VOTE_SHARE_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'S_NO:'||S_NO||';'|| 'WINNER:'||WINNER||';'|| 'PARTY:'||PARTY||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'VOTES_POLLED_FOR_WINNER:'||VOTES_POLLED_FOR_WINNER||';'|| 'VOTE_SHARE_PERCENTAGE:'||VOTE_SHARE_PERCENTAGE||'Response:') as output from T_HIGHEST_VOTE_SHARE),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_HIGHEST_VOTE_SHARE_WINNERS_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'WINNER_NAME:'||WINNER_NAME||';'|| 'PARTY:'||PARTY||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'VOTES_POLLED:'||VOTES_POLLED||';'|| 'VOTE_SHARE_PERCENTAGE:'||VOTE_SHARE_PERCENTAGE||'Response:') as output from T_HIGHEST_VOTE_SHARE_WINNERS),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_NOTA_COMPARISON_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'YEAR:'||YEAR||';'|| 'NOTA_VOTE_SHARE_PERCENTAGE:'||NOTA_VOTE_SHARE_PERCENTAGE||'Response:') as output from T_NOTA_COMPARISON),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_LARGE_VICTORY_MARGINS_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'WINNER_NAME:'||WINNER_NAME||';'|| 'WINNER_PARTY:'||WINNER_PARTY||';'|| 'WINNER_VOTES:'||WINNER_VOTES||';'|| 'WINNER_VOTE_SHARE:'||WINNER_VOTE_SHARE||';'|| 'RUNNER_UP_NAME:'||RUNNER_UP_NAME||';'|| 'RUNNER_UP_PARTY:'||RUNNER_UP_PARTY||';'|| 'RUNNER_UP_VOTES:'||RUNNER_UP_VOTES||';'|| 'RUNNER_UP_VOTE_SHARE:'||RUNNER_UP_VOTE_SHARE||';'|| 'MARGIN_OF_VICTORY:'||MARGIN_OF_VICTORY||';'|| 'MARGIN_PERCENTAGE:'||MARGIN_PERCENTAGE||'Response:') as output from T_LARGE_VICTORY_MARGINS),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_HIGHEST_VOTER_TURNOUT_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_REGISTERED_VOTERS:'||TOTAL_REGISTERED_VOTERS||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'TURNOUT_PERCENTAGE:'||TURNOUT_PERCENTAGE||'Response:') as output from T_HIGHEST_VOTER_TURNOUT),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_POLITICAL_PARTIES_COMPARISON_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'CATEGORY:'||CATEGORY||';'|| 'PARTIES_2019:'||PARTIES_2019||';'|| 'CANDIDATES_2019:'||CANDIDATES_2019||';'|| 'PARTIES_2024:'||PARTIES_2024||';'|| 'CANDIDATES_2024:'||CANDIDATES_2024||'Response:') as output from T_POLITICAL_PARTIES_COMPARISON),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_VOTE_SHARE_MARGIN_VICTORY_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'S_NO:'||S_NO||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'WINNER:'||WINNER||';'|| 'WINNER_PARTY:'||WINNER_PARTY||';'|| 'VOTES_POLLED_FOR_WINNER:'||VOTES_POLLED_FOR_WINNER||';'|| 'WINNER_VOTE_SHARE_PERCENTAGE:'||WINNER_VOTE_SHARE_PERCENTAGE||';'|| 'RUNNER_UP:'||RUNNER_UP||';'|| 'RUNNER_UP_PARTY:'||RUNNER_UP_PARTY||';'|| 'VOTES_POLLED_FOR_RUNNER_UP:'||VOTES_POLLED_FOR_RUNNER_UP||';'|| 'RUNNER_UP_VOTE_PERCENTAGE:'||RUNNER_UP_VOTE_PERCENTAGE||';'|| 'MARGIN_OF_VICTORY:'||MARGIN_OF_VICTORY||';'|| 'MARGIN_OF_VICTORY_PERCENTAGE:'||MARGIN_OF_VICTORY_PERCENTAGE||';'|| 'NOTA_TOTAL_VOTES:'||NOTA_TOTAL_VOTES||';'|| 'NOTA_PERCENTAGE:'||NOTA_PERCENTAGE||'Response:') as output from T_VOTE_SHARE_MARGIN_VICTORY),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_LOWEST_VOTER_TURNOUT_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_REGISTERED_VOTERS:'||TOTAL_REGISTERED_VOTERS||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'TURNOUT_PERCENTAGE:'||TURNOUT_PERCENTAGE||'Response:') as output from T_LOWEST_VOTER_TURNOUT),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_PARTY_WISE_VOTE_SHARE_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'PARTY_NAME:'||PARTY_NAME||';'|| 'TOTAL_VOTES_POLLED:'||TOTAL_VOTES_POLLED||';'|| 'VOTE_SHARE_PERCENTAGE:'||VOTE_SHARE_PERCENTAGE||'Response:') as output from T_PARTY_WISE_VOTE_SHARE),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_LOWEST_VOTE_SHARE_WINNERS_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'WINNER_NAME:'||WINNER_NAME||';'|| 'PARTY:'||PARTY||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'VOTES_POLLED:'||VOTES_POLLED||';'|| 'VOTE_SHARE_PERCENTAGE:'||VOTE_SHARE_PERCENTAGE||'Response:') as output from T_LOWEST_VOTE_SHARE_WINNERS),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_PARTY_PERFORMANCE_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'PARTY:'||PARTY||';'|| 'TOTAL_SEATS_WON:'||TOTAL_SEATS_WON||';'|| 'TOTAL_VOTES_POLLED:'||TOTAL_VOTES_POLLED||';'|| 'VOTE_SHARE_PERCENTAGE:'||VOTE_SHARE_PERCENTAGE||'Response:') as output from T_PARTY_PERFORMANCE),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_VOTE_SHARE_REPRESENTATIVENESS_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'S_NO:'||S_NO||';'|| 'WINNER:'||WINNER||';'|| 'PARTY:'||PARTY||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_REGISTERED_VOTERS:'||TOTAL_REGISTERED_VOTERS||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'TOTAL_VOTES_POLLED_FOR_WINNER:'||TOTAL_VOTES_POLLED_FOR_WINNER||';'|| 'VOTE_SHARE_PERCENTAGE:'||VOTE_SHARE_PERCENTAGE||';'|| 'REPRESENTATIVENESS_PERCENTAGE:'||REPRESENTATIVENESS_PERCENTAGE||';'|| 'VOTERS_TURNOUT_PERCENTAGE:'||VOTERS_TURNOUT_PERCENTAGE||'Response:') as output from T_VOTE_SHARE_REPRESENTATIVENESS),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_GENERATE_PROMPT_REPONSES_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'LLM_RESPONSE:'||LLM_RESPONSE||';'|| 'INDEX:'||INDEX||';'|| 'PROMPT_RESPONSE:'||PROMPT_RESPONSE||'Response:') as output from T_GENERATE_PROMPT_REPONSES),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


create or replace table T_HIGHEST_NOTA_CONSTITUENCIES_prompt_reponses as
with table_results as (select snowflake.cortex.complete('CLAUDE-3-5-SONNET','I am providing input data with column name and it''s value separated by colon and would like you to generate a prompt and response as array that used further to fine tune llm models in snowflake. Input data:'||  'RANK_NO:'||RANK_NO||';'|| 'CONSTITUENCY:'||CONSTITUENCY||';'|| 'TOTAL_VALID_VOTES:'||TOTAL_VALID_VOTES||';'|| 'WINNER_VOTES:'||WINNER_VOTES||';'|| 'WINNER_VOTE_SHARE:'||WINNER_VOTE_SHARE||';'|| 'RUNNER_UP_VOTES:'||RUNNER_UP_VOTES||';'|| 'RUNNER_UP_VOTE_SHARE:'||RUNNER_UP_VOTE_SHARE||';'|| 'NOTA_VOTES:'||NOTA_VOTES||';'|| 'NOTA_PERCENTAGE:'||NOTA_PERCENTAGE||'Response:') as output from T_HIGHEST_NOTA_CONSTITUENCIES),
 json_blocks AS (
  -- Extract JSON-like blocks using regex
  SELECT
    output,(REGEXP_SUBSTR_ALL(output, '\{[^\{\}]+\}')) AS json_list
  FROM table_results
) select output llm_response,index, parse_json(value) as prompt_response  from json_blocks,
lateral flatten (input => json_list);


-- You can use to fine tune your models.

-- Once you create all tables like above try create training data table by extracting only prompt and response
show tables like '%PROMPT_REPONSES' ->> select LISTAGG('SELECT PROMPT_RESPONSE[''prompt'']::text as prompt,PROMPT_RESPONSE[''response'']::text as completion FROM  '||"name"||CHR(13),' UNION ALL ') AS QUERY FROM $1 ;

-- output of above query is here


create or replace table  t_training_data as
SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_CLOSE_VICTORY_MARGINS_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_GENERATE_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_GENERATE_PROMPT_REPONSES_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_HIGHEST_NOTA_CONSTITUENCIES_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_HIGHEST_VOTER_TURNOUT_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_HIGHEST_VOTE_SHARE_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_HIGHEST_VOTE_SHARE_WINNERS_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_LARGE_VICTORY_MARGINS_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_LOWEST_VOTER_TURNOUT_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_LOWEST_VOTE_SHARE_WINNERS_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_NOTA_COMPARISON_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_PARTY_PERFORMANCE_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_PARTY_WISE_VOTE_SHARE_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_POLITICAL_PARTIES_COMPARISON_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_VOTE_SHARE_MARGIN_VICTORY_PROMPT_REPONSES
 UNION ALL SELECT PROMPT_RESPONSE['prompt']::text as prompt,PROMPT_RESPONSE['response']::text as completion FROM  T_VOTE_SHARE_REPRESENTATIVENESS_PROMPT_REPONSES;

-- Fine tune queries
-- Support for this feature is available to accounts in the following regions:

--AWS US West 2 (Oregon)
--
--AWS US East 1 (N. Virginia)
--
--AWS Europe Central 1 (Frankfurt)
--
--Azure East US 2 (Virginia)

SELECT SNOWFLAKE.CORTEX.FINETUNE(
  'CREATE',
  'election2024-ap-mistral-7b',
  'mistral-7b',
  'SELECT prompt, completion FROM t_training_data',
  'SELECT prompt, completion FROM t_training_data'
);


SELECT SNOWFLAKE.CORTEX.FINETUNE(
  'DESCRIBE',
  '<finetune_job_id>'
);

select SNOWFLAKE.CORTEX.FINETUNE('SHOW');

select SNOWFLAKE.CORTEX.FINETUNE(
  'CANCEL',
  '<finetune_job_id>'
);
