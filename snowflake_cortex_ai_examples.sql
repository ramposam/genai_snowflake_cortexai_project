SHOW TABLES;

SHOW VIEWS;


create or replace TABLE  T_APP_REVIEWS_SCORES
AS 
select REVIEWID,CONTENT AS REVIEW,SCORE AS RATING,APP AS APP_NAME,FILENAME AS FILE_NAME,FILE_LAST_MODIFIED FROM  T_ALL_COMBINED
WHERE NOT (CONTENT IS NULL and  APP is null  )
ORDER BY LENGTH(CONTENT) DESC;

select top 10 * from T_APP_REVIEWS_SCORES;

create or replace TABLE T_APP_REVIEWS_SCORES_CLASSIFY AS  
with ai_ml_functions as (
select *,SNOWFLAKE.CORTEX.ai_classify(APP_NAME,    ['News', 'Music', 'Social Media', 'Messaging', 'File Sharing', 'Productivity', 'Video Calling', 'Cloud Storage', 'Streaming', 'Gaming']
)AS APP_classify,
SNOWFLAKE.CORTEX.SENTIMENT(REVIEW) AS SENTIMENT_SCORE,
SNOWFLAKE.CORTEX.summarize(REVIEW) AS review_summary,
SNOWFLAKE.CORTEX.translate(REVIEW,'en','hi') AS review_in_hindi ,
SNOWFLAKE.CORTEX.extract_answer(REVIEW,'Is this review about a recent update or a general experience?') AS Topic,
SNOWFLAKE.CORTEX.extract_answer(REVIEW,'Is the user requesting a new feature , a bug or issue?') AS Feature_or_Bug,
SNOWFLAKE.CORTEX.extract_answer(REVIEW,'Are there complaints about app speed, crashes, or login issues?') AS User_Experience,
SNOWFLAKE.CORTEX.extract_answer(REVIEW,'Does the user prefer this app over others?') AS Comparative,
SNOWFLAKE.CORTEX.extract_answer(REVIEW,'Is the tone sarcastic, polite, angry, enthusiastic, abusive , offensive etc.? ') AS Language_Tone,  
SNOWFLAKE.CORTEX.extract_answer(REVIEW,'Is the user likely to stop using the app?') AS Risk_Retention,
SNOWFLAKE.CORTEX.extract_answer(REVIEW,'What kind of user is writing this review (e.g., gamer, student, professional)?') AS user_type
from  T_APP_REVIEWS_SCORES)
select *,APP_classify['label']::string as app_category  ,CASE
           WHEN SENTIMENT_SCORE > 0.3 THEN 'POSITIVE'
           WHEN SENTIMENT_SCORE < -0.3 THEN 'NEGATIVE'
           ELSE 'NEUTRAL'
       END AS SENTIMENT  from ai_ml_functions     ;

SELECT TOP 10 *   FROM T_APP_REVIEWS_SCORES_CLASSIFY;

