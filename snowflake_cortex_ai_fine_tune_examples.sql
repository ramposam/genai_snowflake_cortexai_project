create TABLE if not exists  CORTEX_AI_DB.CORTEX_AI.T_DOCUMENTS (
	DOCUMENT_ID NUMBER(1,0),
	FILE_NAME VARCHAR(16777216),
	FILE_CONTENT TEXT,
	NO_OF_PAGES TEXT,
	FILE_MODE TEXT,
	UPDATED_DATE TIMESTAMP_LTZ(9),
	UPDATED_BY VARCHAR(16777216)
    );

 -- create snowflake internal stage
 CREATE STAGE  IF NOT EXISTS CORTEX_AI_DB.CORTEX_AI.STG_DOCUMENTS
	DIRECTORY = ( ENABLE = true )
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' ) ;

 -- Load file to snowflake internal stage
 PUT 'file:///tmp/69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf' @CORTEX_AI_DB.CORTEX_AI.STG_DOCUMENTS AUTO_COMPRESS=FALSE ;

 -- load into table
  INSERT INTO  CORTEX_AI_DB.CORTEX_AI.T_DOCUMENTS
        with tab as (
        SELECT '69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf' as file_name,
            SNOWFLAKE.CORTEX.PARSE_DOCUMENT (
            @CORTEX_AI_DB.CORTEX_AI.STG_DOCUMENTS,
            '69802168-Air-India-Ahmedabad-Crash-AAIB-preliminary-report.pdf',
            {'mode': 'LAYOUT'} )  AS document_data)
            select 8  as document_id,
            file_name,document_data['content']::TEXT file_content,
            document_data['metadata']['pageCount']::TEXT no_of_pages,
            'LAYOUT' as file_mode,
            current_timestamp() as updated_date, current_user() as updated_by
            from tab  ;



set prompt1 = 'I would like to fine tune one of base model llama-8b with following document data using snowflake cortex ai. I want you to analyze the document and suggest me some prompts and it''s result to fine tune model using snowflake.cortex.finetune.

This document has details of Vote Share and Margin of Victory of Winners Andhra Pradesh Assembly 2024. So, it''s all about election result , try to identify no constituencies, each constituent contested candidates, there win, votes, percentage, etc.';


select
snowflake.cortex.complete('claude-4-sonnet','Context:'||chr(13)||file_content||chr(13)||chr(13)||'Question:'||'I would like to fine tune one of base model llama-8b with following document data using snowflake cortex ai. I want you to analyze the document and suggest me some prompts and it''s result to fine tune model using snowflake.cortex.finetune.

This document has details of Vote Share and Margin of Victory of Winners Andhra Pradesh Assembly 2024. So, it''s all about election result , try to identify no constituencies, each constituent contested candidates, there win, votes, percentage, etc.'||chr(13)||chr(13)||'Response:'
) as Response from cortex_ai_db.cortex_ai.t_documents
where file_name='Analysis_of_Vote_Share_and_Margin_of_Victory_of_Winners_Andhra_Pradesh_Assembly_2024_Finalver_English.pdf';

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set prompt_2 = 'I want you to read each table layout and create a temporary table for layout and insert all of them.';


select
snowflake.cortex.complete('claude-4-sonnet','Context:'||chr(13)||file_content||chr(13)||chr(13)||'Question:'||'I want you to read each table layout and create a temporary table for layout and insert all of them.'||chr(13)||chr(13)||'Response:'
) from cortex_ai_db.cortex_ai.t_documents
where file_name='Analysis_of_Vote_Share_and_Margin_of_Victory_of_Winners_Andhra_Pradesh_Assembly_2024_Finalver_English.pdf';

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set prompt_3 = 'I want you to read each table layout and create a temporary table for layout and insert all of them. Focus on layout named Vote Share and Representativeness of Winners in Andhra Pradesh Assembly Elections which spreads to multiple pages and another layout named Vote Share and Margin of Victory of Winners in Andhra Pradesh Assembly Elections 2024 which is also spreads to multiple pages.';

select
snowflake.cortex.complete('claude-4-sonnet','Context:'||chr(13)||file_content||chr(13)||chr(13)||'Question:'||'I want you to read each table layout and create a temporary table for layout and insert all of them. Focus on layout named Vote Share and Representativeness of Winners in Andhra Pradesh Assembly Elections which spreads to multiple pages and another layout named Vote Share and Margin of Victory of Winners in Andhra Pradesh Assembly Elections 2024 which is also spreads to multiple pages. '||chr(13)||chr(13)||'Response:'
) from cortex_ai_db.cortex_ai.t_documents
where file_name='Analysis_of_Vote_Share_and_Margin_of_Victory_of_Winners_Andhra_Pradesh_Assembly_2024_Finalver_English.pdf';
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set prompt_4 = 'I want you to read each table layout and create a temporary table for layout and insert all of them. Focus only on layout named Vote Share and Representativeness of Winners in Andhra Pradesh Assembly Elections which spreads to multiple pages ';

select
snowflake.cortex.complete('claude-4-sonnet','Context:'||chr(13)||file_content||chr(13)||chr(13)||'Question:'||'I want you to read each table layout and create a temporary table for layout and insert all of them. Focus on layout named Vote Share and Representativeness of Winners in Andhra Pradesh Assembly Elections which spreads to multiple pages and another layout named Vote Share and Margin of Victory of Winners in Andhra Pradesh Assembly Elections 2024 which is also spreads to multiple pages. '||chr(13)||chr(13)||'Response:'
) from cortex_ai_db.cortex_ai.t_documents
where file_name='Analysis_of_Vote_Share_and_Margin_of_Victory_of_Winners_Andhra_Pradesh_Assembly_2024_Finalver_English.pdf';
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
set prompt_5 = 'I want you to read each table layout and create a temporary table for layout and insert all of them. Focus only on layout named Vote Share and Margin of Victory of Winners in Andhra Pradesh Assembly Elections 2024 which is also spreads to multiple pages.';


select
snowflake.cortex.complete('claude-4-sonnet','Context:'||chr(13)||file_content||chr(13)||chr(13)||'Question:'||'I want you to read each table layout and create a temporary table for layout and insert all of them. Focus only on layout named Vote Share and Margin of Victory of Winners in Andhra Pradesh Assembly Elections 2024 which is also spreads to multiple pages. '||chr(13)||chr(13)||'Response:'
) from cortex_ai_db.cortex_ai.t_documents
where file_name='Analysis_of_Vote_Share_and_Margin_of_Victory_of_Winners_Andhra_Pradesh_Assembly_2024_Finalver_English.pdf';

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Andhra Pradesh Election 2024 - Training Prompt-Response Pairs for Snowflake Cortex Fine-tuning

-- =============================================================================
-- TRAINING DATA TABLE STRUCTURE
-- =============================================================================
CREATE TABLE ap_election_training_data (
    id INT AUTOINCREMENT,
    prompt TEXT,
    response TEXT,
    category VARCHAR(50),
    difficulty_level VARCHAR(20), -- basic, intermediate, advanced
    data_source VARCHAR(50)
);

-- =============================================================================
-- CATEGORY 1: BASIC CONSTITUENCY QUERIES (40% of training data)
-- =============================================================================

-- Individual Winner Queries
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('Who won the Visakhapatnam South constituency in AP 2024?', 'Ch.Vamsi Krishna Srinivas from Janasena Party won Visakhapatnam South constituency with 97,868 votes, securing 70.24% vote share and defeating the runner-up by a margin of 46.36%.', 'constituency_winner', 'basic', 'detailed_constituency_results'),

('What was the vote share of winner in Nellore City?', 'Narayana Ponguru from Telugu Desam Party won Nellore City with 120,551 votes, achieving 68.99% vote share with a victory margin of 41.48%.', 'constituency_winner', 'basic', 'detailed_constituency_results'),

('Who was the runner-up in Palacole constituency?', 'Gudala Sri Hari Gopala Rao (Gudala Gopi) from YSRCP was the runner-up in Palacole constituency with 45,169 votes (27.67% vote share), losing to Dr.Nimmala Ramanaidu of TDP.', 'constituency_runner_up', 'basic', 'detailed_constituency_results'),

('Which party won Pithapuram constituency?', 'Janasena Party won Pithapuram constituency. Konidala Pawan Kalyan secured 134,394 votes with 64.87% vote share and 58.38% representativeness.', 'constituency_party', 'basic', 'constituency_wise_results'),

('What was the margin of victory in Gajuwaka?', 'In Gajuwaka constituency, Palla Srinivas Rao (TDP) won with a margin of 95,235 votes, which represents 40.64% margin of victory against YSRCP candidate.', 'constituency_margin', 'basic', 'detailed_constituency_results'),

('Who won Mangalagiri constituency and by what margin?', 'Nara Lokesh from Telugu Desam Party won Mangalagiri constituency with 167,710 votes (66.07% vote share) and a victory margin of 36.01% against YSRCP candidate Murugudu Lavanya.', 'constituency_winner_margin', 'basic', 'detailed_constituency_results'),

('What was the voter turnout in Kuppam constituency?', 'Kuppam constituency had a voter turnout of 91.07% with 203,367 valid votes out of 223,306 registered voters. Chandrababu Naidu Nara (TDP) won this constituency.', 'constituency_turnout', 'basic', 'constituency_wise_results'),

('Which constituency had Pawan Kalyan as winner?', 'Konidala Pawan Kalyan won from Pithapuram constituency with 134,394 votes, securing 64.87% vote share and 90.00% voter turnout.', 'candidate_constituency', 'basic', 'constituency_wise_results'),

-- =============================================================================
-- CATEGORY 2: PARTY PERFORMANCE QUERIES (25% of training data)
-- =============================================================================

-- Overall Party Performance
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('How many seats did TDP win in AP 2024?', 'Telugu Desam Party (TDP) won 135 seats out of 175 constituencies, achieving 77.14% win rate with 45.60% vote share and a strike rate of 1.69.', 'party_seats', 'basic', 'party_performance_2024'),

('What was YSRCP performance in 2024?', 'YSRCP won only 11 seats out of 175 constituencies (6.29% win rate) despite securing 39.37% vote share, resulting in a poor strike rate of 0.16. This was a significant decline from their previous performance.', 'party_performance', 'intermediate', 'party_performance_2024'),

('Which party had the best strike rate in AP 2024?', 'Jana Sena Party had the best strike rate of 1.75, winning 21 seats (12.00%) with just 6.87% vote share, showing highly concentrated and efficient vote conversion.', 'party_efficiency', 'intermediate', 'party_performance_2024'),

('What was BJP vote share and seat count?', 'Bharatiya Janata Party secured 2.83% vote share and won 8 seats (4.57% of total), with a decent strike rate of 1.61, performing better than their vote share would suggest.', 'party_performance', 'basic', 'party_performance_2024'),

('How did Congress perform in AP 2024?', 'Indian National Congress won 0 seats despite securing 1.72% vote share, resulting in a strike rate of 0.00, indicating complete failure to convert votes into seats.', 'party_performance', 'basic', 'party_performance_2024'),

-- Vote Share Distribution by Party
('How many TDP winners had 50%+ vote share?', 'Out of 135 TDP winners, 117 candidates (86.7%) won with 50%+ vote share - with 95 in 51-60% range and 22 in 61-70% range. Only 18 won with 41-50% vote share.', 'party_vote_distribution', 'intermediate', 'party_wise_winner_distribution'),

('What was YSRCP winners vote share pattern?', 'Out of 11 YSRCP winners, 1 won with 31-40% vote share, 8 with 41-50%, 1 with 51-60%, and 1 with 61-70%, showing most winners had relatively low vote shares.', 'party_vote_distribution', 'intermediate', 'party_wise_winner_distribution'),

('How many Janasena winners had 60%+ vote share?', 'Out of 21 Janasena winners, 11 candidates (52.4%) won with 61-70% vote share, showing strong concentrated support. 9 won with 51-60% and only 1 with 41-50%.', 'party_vote_distribution', 'intermediate', 'party_wise_winner_distribution'),

-- =============================================================================
-- CATEGORY 3: STATISTICAL & COMPARATIVE ANALYSIS (20% of training data)
-- =============================================================================

-- Overall Election Statistics
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('What was the average vote share of winners in AP 2024?', 'Winners in AP 2024 elections achieved an average vote share of 55.82%, which was an improvement from 50.70% in 2019, indicating stronger mandate for winners.', 'election_stats', 'basic', 'election_summary_stats'),

('How did voter turnout change from 2019 to 2024?', 'Voter turnout increased from 79.70% in 2019 to 82.68% in 2024, showing a positive increase of 2.98 percentage points, indicating higher voter engagement.', 'turnout_comparison', 'basic', 'election_summary_stats'),

('What was the representativeness of winners in 2024?', 'Winners in 2024 represented an average of 46.15% of total registered voters compared to 40.48% in 2019, showing improved representativeness by 5.67 percentage points.', 'representativeness', 'intermediate', 'election_summary_stats'),

('How did NOTA performance change from 2019?', 'NOTA votes decreased from 1.28% in 2019 to 1.09% in 2024, showing a decline of 0.19 percentage points. In absolute terms, 3,69,320 NOTA votes were cast in 2024.', 'nota_comparison', 'intermediate', 'election_summary_stats'),

('How many political parties contested in 2024 vs 2019?', 'The number of political parties increased from 69 in 2019 to 88 in 2024 (27.54% increase), while total candidates rose from 2,118 to 2,387 (12.70% increase).', 'parties_comparison', 'intermediate', 'election_summary_stats'),

-- Highest and Lowest Performers
('Which constituency had the highest voter turnout?', 'Darsi constituency had the highest voter turnout of 92.50% with 207,106 valid votes out of 223,901 registered voters.', 'highest_turnout', 'basic', 'highest_voter_turnout'),

('Which constituency had the lowest voter turnout?', 'Tirupati constituency had the lowest voter turnout of 64.94% with 193,742 valid votes out of 298,335 registered voters.', 'lowest_turnout', 'basic', 'lowest_voter_turnout'),

('Who achieved the highest vote share in AP 2024?', 'Ch.Vamsi Krishna Srinivas from Janasena Party achieved the highest vote share of 70.24% in Visakhapatnam South constituency with 97,868 votes.', 'highest_vote_share', 'basic', 'highest_vote_share_winners'),

('Who won with the lowest vote share?', 'Regam Matyalingam from YSRCP won Araku Valley constituency with the lowest vote share of 36.71% (65,658 votes), indicating a highly fragmented contest.', 'lowest_vote_share', 'basic', 'lowest_vote_share_winners'),

-- =============================================================================
-- CATEGORY 4: VICTORY MARGINS & CLOSE CONTESTS (15% of training data)
-- =============================================================================

-- Narrow and Wide Margins
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('Which was the closest contest in AP 2024?', 'Madakasira was the closest contest where M.S.Raju (TDP) defeated Iralakkappa.S.L (YSRCP) by just 351 votes (0.19% margin), with vote shares of 42.97% vs 42.78%.', 'closest_contest', 'intermediate', 'narrow_victory_margins'),

('How many constituencies had victory margins less than 1000 votes?', 'Only 2 constituencies had victory margins less than 1000 votes: Madakasira (351 votes margin) and Giddalur (973 votes margin), both won by TDP candidates.', 'narrow_margins', 'intermediate', 'narrow_victory_margins'),

('Which constituency had the highest victory margin?', 'Visakhapatnam South had the highest victory margin where Ch.Vamsi Krishna Srinivas (Janasena) defeated YSRCP candidate by 64,594 votes, representing 46.36% margin of victory.', 'highest_margin', 'basic', 'high_victory_margins'),

('How many constituencies had 40%+ victory margins?', 'Four constituencies had victory margins above 40%: Visakhapatnam South (46.36%), Palacole (41.63%), Nellore City (41.48%), and Gajuwaka (40.64%).', 'high_margins', 'intermediate', 'high_victory_margins'),

('What was the margin pattern in high-victory constituencies?', 'All four constituencies with 40%+ margins were won by either TDP (3 seats) or Janasena (1 seat), with vote shares ranging from 67.30% to 70.24%, indicating dominant victories against YSRCP candidates.', 'margin_analysis', 'advanced', 'high_victory_margins'),

-- =============================================================================
-- CATEGORY 5: NOTA AND SPECIAL CASES (10% of training data)
-- =============================================================================

-- NOTA Analysis
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('Which constituency had the highest NOTA votes?', 'Tekkali constituency had the highest NOTA votes with 7,342 votes representing 3.79% of total votes, despite the winner securing 55.71% vote share.', 'nota_highest', 'basic', 'highest_nota_constituencies'),

('What was the NOTA pattern in top constituencies?', 'Top 3 NOTA constituencies were Tekkali (3.79%), Rampachodavaram (3.45%), and Salur (3.63%). Notably, Rampachodavaram had a close contest with winner getting only 42.80% vote share.', 'nota_pattern', 'intermediate', 'highest_nota_constituencies'),

('How much total NOTA votes were polled in AP 2024?', 'Total NOTA votes were 3,69,320 out of 3,37,40,584 total votes polled, representing 1.09% of total votes, which was lower than 1.28% in 2019.', 'nota_total', 'basic', 'election_summary_stats'),

-- =============================================================================
-- CATEGORY 6: COMPLEX ANALYTICAL QUERIES (Advanced - 20% of training data)
-- =============================================================================

-- Multi-factor Analysis
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('Compare TDP and Janasena performance efficiency', 'TDP won 135 seats with 45.60% votes (strike rate 1.69) while Janasena won 21 seats with 6.87% votes (strike rate 1.75). Janasena was more efficient in vote conversion despite fewer total votes.', 'party_efficiency_comparison', 'advanced', 'party_performance_2024'),

('What does the YSRCP performance indicate about voter sentiment?', 'YSRCP secured 39.37% vote share but won only 11 seats (strike rate 0.16), indicating their votes were widely distributed but not concentrated enough to win constituencies, suggesting anti-incumbency and tactical voting.', 'electoral_analysis', 'advanced', 'party_performance_2024'),

('Analyze the turnout vs victory margin correlation', 'High turnout constituencies like Darsi (92.50%) and Jaggayyapeta (91.82%) showed competitive results, while low turnout areas like Tirupati (64.94%) still produced decisive victories, indicating varied engagement patterns across regions.', 'correlation_analysis', 'advanced', 'multiple_tables'),

('What was the impact of alliance strategy on results?', 'The TDP-Janasena-BJP alliance won 164 out of 175 seats (93.7%) with combined vote share of 55.30%, while YSRCP despite 39.37% vote share won only 11 seats, showing successful alliance vote consolidation.', 'alliance_analysis', 'advanced', 'party_performance_2024'),

('Compare representativeness across party winners', 'TDP winners averaged higher representativeness due to higher voter turnout in their winning constituencies, while YSRCP winners, despite lower count, maintained decent individual representativeness in their winning seats.', 'representativeness_analysis', 'advanced', 'constituency_wise_results'),

-- =============================================================================
-- CATEGORY 7: SPECIFIC CANDIDATE AND LEADER QUERIES
-- =============================================================================

-- Key Political Leaders
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('What was Chandrababu Naidu performance in Kuppam?', 'Chandrababu Naidu Nara won Kuppam constituency with 121,929 votes securing 59.96% vote share, 54.60% representativeness, and 91.07% voter turnout in his constituency.', 'leader_performance', 'basic', 'constituency_wise_results'),

('How did Pawan Kalyan perform in his constituency?', 'Konidala Pawan Kalyan won Pithapuram with 134,394 votes, achieving 64.87% vote share, 58.38% representativeness, and 90.00% voter turnout, showing strong personal support.', 'leader_performance', 'basic', 'constituency_wise_results'),

('What was Jagan Mohan Reddy result in Pulivendla?', 'YS Jagan Mohan Reddy won Pulivendla with 116,315 votes, securing 61.38% vote share and defeating TDP candidate B.Tech Ravi by 32.55% margin with 83.16% voter turnout.', 'leader_performance', 'basic', 'detailed_constituency_results'),

('Which TDP leader achieved highest vote share?', 'Dr.Nimmala Ramanaidu achieved the highest vote share among TDP candidates with 69.30% in Palacole constituency, securing 113,114 votes and defeating YSRCP candidate by 41.63% margin.', 'party_leader_best', 'intermediate', 'highest_vote_share_winners'),

-- =============================================================================
-- COMPLEX QUERY EXAMPLES FOR ADVANCED TRAINING
-- =============================================================================

-- Cross-referential Queries
INSERT INTO ap_election_training_data (prompt, response, category, difficulty_level, data_source) VALUES
('Find constituencies where winner had less than 45% vote share but high victory margin', 'In constituencies like Madakasira, M.S.Raju won with only 42.97% vote share but had a close contest (0.19% margin), while Ashok Reddy Muthumula in Giddalur won with 47.60% and 0.47% margin, showing fragmented contests.', 'complex_analysis', 'advanced', 'multiple_tables'),

('Compare NOTA votes in high vs low turnout constituencies', 'High turnout constituencies like Darsi (92.50%) and Dharmavaram (91.67%) had moderate NOTA votes, while low turnout areas like Tirupati (64.94%) had 1,281 NOTA votes (0.66%), showing varied protest voting patterns.', 'nota_turnout_analysis', 'advanced', 'multiple_tables'),

('Identify pattern in constituencies with 60%+ winner vote share', 'Constituencies with 60%+ winner vote share include Visakhapatnam South (70.24%), Palacole (69.30%), Nellore City (68.99%), and Gajuwaka (67.30%), mostly won by TDP and Janasena with high victory margins.', 'high_performance_pattern', 'advanced', 'constituency_analysis'),

-- =============================================================================
-- TRAINING DATA SUMMARY QUERY
-- =============================================================================

-- Query to check training data distribution
/*
SELECT
    category,
    difficulty_level,
    COUNT(*) as prompt_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ap_election_training_data), 2) as percentage
FROM ap_election_training_data
GROUP BY category, difficulty_level
ORDER BY category, difficulty_level;
*/

-- Query to validate data sources
/*
SELECT
    data_source,
    COUNT(*) as usage_count,
    COUNT(DISTINCT category) as categories_covered
FROM ap_election_training_data
GROUP BY data_source
ORDER BY usage_count DESC;
*/

SELECT SNOWFLAKE.CORTEX.FINETUNE(
    'CREATE',
    'election-llama-8b-chat',
    'llama-8b',
    'SELECT prompt, response FROM ap_election_training_data',
    'SELECT prompt, response FROM ap_election_training_data',
);


-- ===============================================================================
-- AP ELECTION 2024 - SQL QUERIES WITH PROMPT-COMPLETION TEMPLATES FOR FINE-TUNING
-- ===============================================================================

-- =============================================================================
-- 1. HIGHEST VOTER TURNOUT CONSTITUENCIES
-- Purpose: Identify constituencies with maximum voter participation
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Which constituency had the ',
           CASE WHEN rank = 1 THEN 'highest'
                WHEN rank = 2 THEN 'second highest'
                ELSE 'third highest' END,
           ' voter turnout in AP 2024?", ',
           '"completion": "', constituency, ' constituency had the ',
           CASE WHEN rank = 1 THEN 'highest'
                WHEN rank = 2 THEN 'second highest'
                ELSE 'third highest' END,
           ' voter turnout of ', voter_turnout_percentage, '% with ',
           FORMAT(total_valid_votes, 0), ' valid votes out of ',
           FORMAT(total_registered_voters, 0), ' registered voters"}') as training_data
FROM highest_voter_turnout;

-- Alternative query for specific constituency turnout
SELECT
    CONCAT('{"prompt": "What was the voter turnout in ', constituency, ' constituency?", ',
           '"completion": "', constituency, ' constituency recorded ',
           voter_turnout_percentage, '% voter turnout with ',
           FORMAT(total_valid_votes, 0), ' valid votes cast out of ',
           FORMAT(total_registered_voters, 0), ' total registered voters"}') as training_data
FROM highest_voter_turnout;

-- =============================================================================
-- 2. LOWEST VOTER TURNOUT CONSTITUENCIES
-- Purpose: Identify constituencies with minimum voter participation
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Which constituency had the lowest voter turnout in AP 2024?", ',
           '"completion": "', constituency, ' constituency had the lowest voter turnout of ',
           voter_turnout_percentage, '% with only ',
           FORMAT(total_valid_votes, 0), ' valid votes out of ',
           FORMAT(total_registered_voters, 0), ' registered voters"}') as training_data
FROM lowest_voter_turnout
WHERE rank = 1;

-- Query for all low turnout constituencies
SELECT
    CONCAT('{"prompt": "What was the voter turnout pattern in low-participation constituencies?", ',
           '"completion": "The constituencies with lowest voter turnout were ',
           GROUP_CONCAT(CONCAT(constituency, ' (', voter_turnout_percentage, '%)') SEPARATOR ', '),
           ', all recording below 66% participation"}') as training_data
FROM lowest_voter_turnout;

-- =============================================================================
-- 3. HIGHEST VOTE SHARE WINNERS
-- Purpose: Identify winners with maximum vote percentage
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Who achieved the highest vote share in AP 2024 elections?", ',
           '"completion": "', winner_name, ' from ', party,
           ' achieved the highest vote share of ', vote_share_percentage,
           '% in ', constituency, ' constituency with ',
           FORMAT(votes_for_winner, 0), ' votes out of ',
           FORMAT(total_valid_votes, 0), ' total valid votes"}') as training_data
FROM highest_vote_share_winners
WHERE rank = 1;

-- Query for individual constituency winner vote share
SELECT
    CONCAT('{"prompt": "What was the vote share of winner in ', constituency, ' constituency?", ',
           '"completion": "', winner_name, ' from ', party,
           ' won ', constituency, ' constituency with ',
           FORMAT(votes_for_winner, 0), ' votes, securing ',
           vote_share_percentage, '% vote share"}') as training_data
FROM highest_vote_share_winners;

-- =============================================================================
-- 4. LOWEST VOTE SHARE WINNERS
-- Purpose: Identify winners with minimum winning vote percentage
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Who won with the lowest vote share in AP 2024?", ',
           '"completion": "', winner_name, ' from ', party,
           ' won ', constituency, ' constituency with the lowest vote share of ',
           vote_share_percentage, '% (', FORMAT(votes_for_winner, 0),
           ' votes), indicating a highly fragmented contest"}') as training_data
FROM lowest_vote_share_winners
WHERE rank = 1;

-- Query for constituencies with sub-50% winners
SELECT
    CONCAT('{"prompt": "How many winners won with less than 50% vote share?", ',
           '"completion": "', COUNT(*), ' winners won with less than 50% vote share, including ',
           GROUP_CONCAT(CONCAT(winner_name, ' in ', constituency, ' (', vote_share_percentage, '%)') SEPARATOR ', '),
           ', indicating fragmented electoral contests"}') as training_data
FROM lowest_vote_share_winners;

-- =============================================================================
-- 5. PARTY WISE VOTE SHARE
-- Purpose: Overall party performance in terms of votes received
-- =============================================================================

SELECT
    CONCAT('{"prompt": "What was ', party, ' vote share in AP 2024?", ',
           '"completion": "', party, ' secured ',
           FORMAT(total_votes, 0), ' votes, representing ',
           vote_share_percentage, '% of total votes polled in AP 2024 elections"}') as training_data
FROM party_wise_vote_share
WHERE rank <= 5;

-- Query for top performing parties
SELECT
    CONCAT('{"prompt": "Which parties secured the highest vote shares in AP 2024?", ',
           '"completion": "The top vote share winners were: 1) TDP with ',
           (SELECT vote_share_percentage FROM party_wise_vote_share WHERE rank = 1), '%, 2) YSRCP with ',
           (SELECT vote_share_percentage FROM party_wise_vote_share WHERE rank = 2), '%, and 3) Janasena with ',
           (SELECT vote_share_percentage FROM party_wise_vote_share WHERE rank = 3), '% of total votes polled"}') as training_data;

-- Query for NOTA performance
SELECT
    CONCAT('{"prompt": "How many NOTA votes were polled in AP 2024?", ',
           '"completion": "NOTA received ', FORMAT(total_votes, 0),
           ' votes representing ', vote_share_percentage,
           '% of total votes polled, showing voter dissatisfaction with available candidates"}') as training_data
FROM party_wise_vote_share
WHERE party = 'None of the Above (NOTA)';

-- =============================================================================
-- 6. PARTY WISE WINNER DISTRIBUTION
-- Purpose: Analysis of vote share ranges for winning candidates by party
-- =============================================================================

SELECT
    CONCAT('{"prompt": "How many ', party, ' winners had vote share above 50%?", ',
           '"completion": "Out of ', SUM(number_of_winners), ' ', party, ' winners, ',
           SUM(CASE WHEN vote_share_range IN ('51%-60%', '61%-70%') THEN number_of_winners ELSE 0 END),
           ' candidates won with above 50% vote share, with ',
           MAX(CASE WHEN vote_share_range = '61%-70%' THEN number_of_winners ELSE 0 END),
           ' achieving 61-70% vote share"}') as training_data
FROM party_wise_winner_distribution
WHERE party IN ('TDP', 'YSRCP', 'Janasena Party', 'BJP')
GROUP BY party;

-- Query for dominant performance analysis
SELECT
    CONCAT('{"prompt": "Which party had the most dominant winners in terms of vote share?", ',
           '"completion": "', party, ' had the most dominant performance with ',
           number_of_winners, ' winners achieving 61-70% vote share range, ',
           'demonstrating strong constituency-level support"}') as training_data
FROM party_wise_winner_distribution
WHERE vote_share_range = '61%-70%'
ORDER BY number_of_winners DESC
LIMIT 1;

-- =============================================================================
-- 7. NARROW VICTORY MARGINS (< 1000 votes)
-- Purpose: Identify closest electoral contests
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Which was the closest contest in AP 2024 elections?", ',
           '"completion": "', constituency, ' was the closest contest where ',
           winner_name, ' (', winner_party, ') defeated ', runner_up_name,
           ' (', runner_up_party, ') by just ', margin_of_victory,
           ' votes (', margin_percentage, '% margin) with vote shares of ',
           winner_vote_share, '% vs ', runner_up_vote_share, '%"}') as training_data
FROM narrow_victory_margins
WHERE rank = 1;

-- Query for all narrow margins
SELECT
    CONCAT('{"prompt": "How many constituencies had victory margins below 1000 votes?", ',
           '"completion": "Only ', COUNT(*), ' constituencies had victory margins below 1000 votes: ',
           GROUP_CONCAT(CONCAT(constituency, ' (', margin_of_victory, ' votes)') SEPARATOR ', '),
           ', indicating most contests were decisive"}') as training_data
FROM narrow_victory_margins;

-- =============================================================================
-- 8. HIGH VICTORY MARGINS (> 40%)
-- Purpose: Identify most dominant electoral victories
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Which constituency had the highest victory margin in AP 2024?", ',
           '"completion": "', constituency, ' had the highest victory margin where ',
           winner_name, ' (', winner_party, ') defeated ', runner_up_name,
           ' by ', FORMAT(margin_of_victory, 0), ' votes representing ',
           margin_percentage, '% margin with ', winner_vote_share, '% vote share"}') as training_data
FROM high_victory_margins
WHERE rank = 1;

-- Query for dominant victories pattern
SELECT
    CONCAT('{"prompt": "How many constituencies had victory margins above 40%?", ',
           '"completion": "', COUNT(*), ' constituencies had victory margins above 40%: ',
           GROUP_CONCAT(CONCAT(constituency, ' (', margin_percentage, '%)') SEPARATOR ', '),
           '. All were won by either TDP or Janasena Party candidates"}') as training_data
FROM high_victory_margins;

-- =============================================================================
-- 9. NOTA COMPARISON (2019 vs 2024)
-- Purpose: Analyze NOTA vote trend over elections
-- =============================================================================

SELECT
    CONCAT('{"prompt": "How did NOTA performance change from 2019 to 2024 in AP?", ',
           '"completion": "NOTA votes ',
           CASE WHEN (SELECT nota_vote_share_percentage FROM nota_comparison WHERE year = 2024) <
                     (SELECT nota_vote_share_percentage FROM nota_comparison WHERE year = 2019)
                THEN 'decreased' ELSE 'increased' END,
           ' from ', (SELECT nota_vote_share_percentage FROM nota_comparison WHERE year = 2019),
           '% in 2019 to ', (SELECT nota_vote_share_percentage FROM nota_comparison WHERE year = 2024),
           '% in 2024, showing ',
           CASE WHEN (SELECT nota_vote_share_percentage FROM nota_comparison WHERE year = 2024) <
                     (SELECT nota_vote_share_percentage FROM nota_comparison WHERE year = 2019)
                THEN 'reduced voter dissatisfaction' ELSE 'increased voter dissatisfaction' END, '"}') as training_data;

-- =============================================================================
-- 10. HIGHEST NOTA CONSTITUENCIES
-- Purpose: Identify constituencies with highest protest votes
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Which constituency had the highest NOTA votes in AP 2024?", ',
           '"completion": "', constituency, ' constituency had the highest NOTA votes with ',
           FORMAT(nota_votes, 0), ' votes representing ', nota_percentage,
           '% of total votes, despite the winner securing ', winner_vote_share, '% vote share"}') as training_data
FROM highest_nota_constituencies
WHERE rank = 1;

-- Query for NOTA pattern analysis
SELECT
    CONCAT('{"prompt": "What was the pattern of NOTA votes in AP 2024?", ',
           '"completion": "Top NOTA constituencies were ',
           GROUP_CONCAT(CONCAT(constituency, ' (', nota_percentage, '%)') SEPARATOR ', '),
           '. Higher NOTA votes often correlated with closer contests and lower winner vote shares"}') as training_data
FROM highest_nota_constituencies
WHERE rank <= 5;

-- =============================================================================
-- 11. CONSTITUENCY WISE RESULTS
-- Purpose: Complete winner information with representativeness
-- =============================================================================

SELECT
    CONCAT('{"prompt": "Who won ', constituency, ' constituency in AP 2024?", ',
           '"completion": "', winner_name, ' from ', party,
           ' won ', constituency, ' constituency with ',
           FORMAT(votes_for_winner, 0), ' votes (', vote_share_percentage,
           '% vote share), representing ', representativeness_percentage,
           '% of total registered voters with ', voter_turnout_percentage, '% turnout"}') as training_data
FROM constituency_wise_results;

-- Query for highest representativeness
SELECT
    CONCAT('{"prompt": "Which winner had the highest representativeness in AP 2024?", ',
           '"completion": "', winner_name, ' from ', party,
           ' in ', constituency, ' constituency had the highest representativeness of ',
           representativeness_percentage, '% of total registered voters with ',
           vote_share_percentage, '% vote share and ', voter_turnout_percentage, '% turnout"}') as training_data
FROM constituency_wise_results
ORDER BY representativeness_percentage DESC
LIMIT 1;

-- =============================================================================
-- 12. DETAILED CONSTITUENCY RESULTS (Winner + Runner-up)
-- Purpose: Complete contest information including margins
-- =============================================================================

SELECT
    CONCAT('{"prompt": "What was the complete result of ', constituency, ' constituency?", ',
           '"completion": "In ', constituency, ', ', winner_name, ' (', winner_party,
           ') won with ', FORMAT(winner_votes, 0), ' votes (', winner_vote_share,
           '% vote share), defeating ', runner_up_name, ' (', runner_up_party,
           ') who got ', FORMAT(runner_up_votes, 0), ' votes (', runner_up_vote_share,
           '%) by a margin of ', FORMAT(margin_of_victory, 0), ' votes (',
           margin_percentage, '%). NOTA got ', nota_votes, ' votes (', nota_percentage, '%)"}') as training_data
FROM detailed_constituency_results;

-- Query for runner-up information
SELECT
    CONCAT('{"prompt": "Who was the runner-up in ', constituency, ' constituency?", ',
           '"completion": "', runner_up_name, ' from ', runner_up_party,
           ' was the runner-up in ', constituency, ' with ',
           FORMAT(runner_up_votes, 0), ' votes (', runner_up_vote_share,
           '% vote share), losing by ', FORMAT(margin_of_victory, 0), ' votes"}') as training_data
FROM detailed_constituency_results;

-- =============================================================================
-- 13. ELECTION SUMMARY STATS
-- Purpose: Overall election metrics and comparisons
-- =============================================================================

SELECT
    CONCAT('{"prompt": "What was the ', LOWER(REPLACE(metric, '%', ' percentage')), ' in AP 2024?", ',
           '"completion": "The ', LOWER(metric), ' in AP 2024 was ', value_2024,
           CASE WHEN value_2019 IS NOT NULL
                THEN CONCAT('%, compared to ', value_2019, '% in 2019, showing a ',
                           CASE WHEN change_percentage > 0 THEN 'positive' ELSE 'negative' END,
                           ' change of ', ABS(change_percentage), ' percentage points')
                ELSE '%' END, '"}') as training_data
FROM election_summary_stats;

-- Query for overall election comparison
SELECT
    CONCAT('{"prompt": "How did AP 2024 elections compare with 2019 in key metrics?", ',
           '"completion": "Key improvements in 2024: Voter turnout increased from 79.70% to 82.68% (+2.98pp), ',
           'average winner vote share rose from 50.70% to 55.82% (+5.12pp), and representativeness improved from 40.48% to 46.15% (+5.67pp). ',
           'NOTA votes decreased from 1.28% to 1.09% (-0.19pp). More parties contested (88 vs 69) with more candidates (2,387 vs 2,118)"}') as training_data;

-- =============================================================================
-- 14. PARTY PERFORMANCE 2024
-- Purpose: Comprehensive party-wise seat and vote analysis
-- =============================================================================

SELECT
    CONCAT('{"prompt": "How many seats did ', party, ' win in AP 2024?", ',
           '"completion": "', party, ' won ', seats_won, ' seats out of ',
           total_constituencies, ' constituencies (', win_percentage,
           '% win rate) with ', vote_share_percentage, '% vote share, ',
           'achieving a strike rate of ', strike_rate, '"}') as training_data
FROM party_performance_2024
WHERE seats_won > 0;

-- Query for strike rate analysis
SELECT
    CONCAT('{"prompt": "Which party had the best strike rate in AP 2024?", ',
           '"completion": "', party, ' had the best strike rate of ', strike_rate,
           ', winning ', seats_won, ' seats (', win_percentage, '%) with only ',
           vote_share_percentage, '% vote share, showing highly efficient vote conversion"}') as training_data
FROM party_performance_2024
ORDER BY strike_rate DESC
LIMIT 1;

-- Query for alliance performance
SELECT
    CONCAT('{"prompt": "What was the overall performance of TDP alliance in AP 2024?", ',
           '"completion": "The TDP-Janasena-BJP alliance won ',
           SUM(seats_won), ' out of 175 seats (',
           ROUND(SUM(seats_won) * 100.0 / 175, 1), '% win rate) with combined vote share of ',
           ROUND(SUM(vote_share_percentage), 2), '%, demonstrating successful alliance strategy"}') as training_data
FROM party_performance_2024
WHERE party IN ('Telugu Desam Party', 'Jana Sena Party', 'Bharatiya Janata Party');

-- =============================================================================
-- SUMMARY TEMPLATE GENERATOR
-- =============================================================================

-- Generate training data count by table
SELECT
    'Table Analysis Summary' as summary,
    CONCAT('Total training prompts generated: ',
           '- Constituency queries: ~175 prompts per constituency table',
           '- Party analysis: ~20 prompts per party table',
           '- Statistical analysis: ~15 prompts per stats table',
           '- Comparative analysis: ~10 prompts per comparison table',
           'Total estimated: 500+ unique prompt-completion pairs') as details;


-- Test the fine-tuned model
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'election-llama-8b-chat',
    'What was the strike rate of Janasena Party?'
);