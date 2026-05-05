-- ============================================================
-- Snowflake Cortex AI service enablement
-- ============================================================
# To enable Snowflake cortex services like Analyst, Search and Agents
# Please run the following commands, Automatically all the Cortex services will be enabled for you.

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

CREATE NETWORK POLICY ALLOW_ALL
ALLOWED_IP_LIST = ('0.0.0.0/0');

ALTER ACCOUNT SET NETWORK_POLICY  = ALLOW_ALL;



-- ============================================================
-- Snowflake Stage creation
-- ============================================================
If you want to create a cortex search for documents, make sure you create a stage with server side encryption.
Otherwise , you can't be used in Cortext Search creation.

Also, if stage files needs to appear on cortex search creation it must be enabled SSE.
CREATE STAGE  IF NOT EXISTS DOCUMENT_DB.DOCUMENTS.STG_DOCUMENTS_SSE
	DIRECTORY = ( ENABLE = true )
	ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' ) ;

If you want to use on snowflake sql or snowpark, create stage with client side encryption.

You can copy file between one stage to another.
COPY FILES INTO @DOCUMENT_DB.DOCUMENTS.STG_DOCUMENTS_SSE FROM @DOCUMENT_DB.DOCUMENTS.STG_DOCS_SOURCE;



-- ============================================================
-- Snowflake Agent support types
-- ============================================================
Snowflake currently supports the following tool types:
    CORTEX_SEARCH_SERVICE_QUERY: Cortex Search Service tool
    CORTEX_ANALYST_MESSAGE: Cortex Analyst tool
    SYSTEM_EXECUTE_SQL: SQL execution
    CORTEX_AGENT_RUN: Cortex Agent tool
    GENERIC: tool for UDFs and stored procedures



-- ============================================================
-- STEP 1: CREATE CORTEX SEARCH SERVICE (on V_PLAYER_SEARCH view)
-- ============================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE IPL.LEAGUE.IPL_PLAYER_SEARCH_SERVICE
  ON SEARCH_TEXT
  ATTRIBUTES PLAYER_NAME, PLAYER_ROLE, NATIONALITY, PLAYER_CATEGORY, TEAMS_PLAYED_FOR
  WAREHOUSE = COMPUTE_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT
      SEARCH_TEXT,
      PLAYER_NAME,
      PLAYER_ROLE,
      NATIONALITY,
      PLAYER_CATEGORY,
      TEAMS_PLAYED_FOR,
      TOTAL_RUNS,
      TOTAL_WICKETS,
      BATTING_STRIKE_RATE,
      BOWLING_ECONOMY
    FROM IPL.LEAGUE.V_PLAYER_SEARCH
  );

-- ============================================================
-- STEP 2: CREATE MCP SERVER
-- Combines: Cortex Search, Cortex Analyst (semantic model), and Stored Procedures
-- ============================================================
CREATE OR REPLACE MCP SERVER IPL.LEAGUE.IPL_MCP_SERVER
FROM SPECIFICATION $$
tools:
  - name: "player_search"
    identifier: "IPL.LEAGUE.IPL_PLAYER_SEARCH_SERVICE"
    type: "CORTEX_SEARCH_SERVICE_QUERY"
    description: "Search for IPL players by name, role, nationality, or team. Returns player stats and profiles."
    title: "IPL Player Search"

  - name: "ipl_analyst"
    identifier: "@IPL.LEAGUE.STG_SEMANTIC_MODEL/ipl_semantic_model.yaml"
    type: "CORTEX_ANALYST_MESSAGE"
    description: "Answer analytical questions about IPL cricket data including batting, bowling, fielding stats across seasons 2022-2026."
    title: "IPL Data Analyst"

  - name: "get_player_stats"
    identifier: "IPL.LEAGUE.MCP_GET_PLAYER_STATS"
    type: "GENERIC"
    description: "Get detailed batting, bowling, and fielding statistics for a specific player. Parameters: player_name (string), stat_type (string: all/batting/bowling/fielding)."
    title: "Player Stats Lookup"

  - name: "sql_executor"
    type: "SYSTEM_EXECUTE_SQL"
    title: "SQL Execution Tool"
    description: "Allows the agent to run read-only SQL queries against the database."

  - name: "top_performers"
    identifier: "IPL.LEAGUE.MCP_TOP_PERFORMERS"
    type: "GENERIC"
    description: "Get top performing players by metric. Parameters: metric (runs/wickets/strike_rate/economy/sixes/fours/catches), result_limit (number), nationality (all/indian/overseas)."
    title: "Top Performers"

$$;

GRANT USAGE ON MCP SERVER IPL.LEAGUE.IPL_MCP_SERVER TO ROLE CORTEX_AI_ROLE;

-- ============================================================
-- STEP 3: CREATE CORTEX AGENT (single unified agent with all tools)
-- ============================================================

create or replace agent "Election Result Analysis"
comment='This agent is built on Snowflake Cortex Search and is connected to a curated document containing detailed information about the Andhra Pradesh State Election Results 2024.

Purpose: The agent serves as a specialized interface for election-related queries.

Users are encouraged to confirm information with trusted election authorities for final verification.'
profile='{"display_name":"Election Result Analysis Agent"}'
from specification
$$
models:
  orchestration: "openai-gpt-4.1"
instructions:
  response: "Tone: clear, factual, neutral, professional.\n\nStyle: concise, structured\
    \ answers (lists/tables when useful).\n\nAlways ground responses in the document;\
    \ if data is missing, state it transparently.\n\nAvoid commentary; focus on delivering\
    \ precise results."
  orchestration: "Parse the user’s query to identify intent (party, constituency,\
    \ statistics).\n\nAlways route through Cortex Search against the election results\
    \ document.\n\nSequence: interpret → map to fields → fetch → process (filter/sort)\
    \ → return.\n\nNever speculate; only report documented results."
  sample_questions:
    - question: "“How many parties contested in the Andhra Pradesh 2024 elections?”\
        \  "
    - question: "“What was the overall voter turnout percentage?”"
    - question: "How many seats did each party win in 2024?"
    - question: "Which party secured the majority in the Andhra Pradesh assembly?"
    - question: "Top 5 constituencies with the largest winning margins."
tools:
  - tool_spec:
      type: "cortex_search"
      name: "tool_for_election_results_ap_2024"
      description: " Any question asked to this agent will be routed through Snowflake\
        \ Cortex Search, which fetches the relevant portion of the Andhra Pradesh\
        \ 2024 election results document and presents it as the answer."
  - tool_spec:
      type: "web_search"
      name: "Web Search"
skills: []
mcp_servers:
  - server_spec:
      name: "DOCUMENT_DB.DOCUMENTS.TRAIL_MCP_SERVER"
tool_resources:
  tool_for_election_results_ap_2024:
    search_service: "DOCUMENT_DB.DOCUMENTS.ELECTION_RESULT_ANDHRA_PRADESH_2024"
    max_results: 4
    title_column: "RELATIVE_PATH"
    id_column: "INDEX"
    columns_and_descriptions:
      TEXT:
        description: "Text contains Data related to the elections results of each\
          \ constituency, no of contestants, voter percentage, no of votes secure,\
          \ win, lose, majority, etc."
        type: "TEXT"
        searchable: true
        filterable: false
  Web Search:
    max_results: 10
$$;

GRANT USAGE ON CORTEX AGENT document_db.documents."Election Result Analysis" TO ROLE CORTEX_AI_ROLE;

-- ============================================================
-- STEP 4: TEST - Query the agent from SQL
-- ============================================================
-- Simple test query
SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT(
  'document_db.documents."Election Result Analysis"',
  'Who are the top 5 run scorers in IPL?'
) AS agent_response;

-- ============================================================
-- STEP 5: REST API / CURL ACCESS
-- ============================================================
--
-- Option A: Using Snowflake SQL API (recommended)
-- Replace <ACCOUNT_URL> with your Snowflake account URL (e.g., st41489.snowflakecomputing.com)
-- Replace <JWT_TOKEN> with a valid JWT token (key-pair auth) or session token
--
-- === CURL: Execute Agent via SQL API ===
--
-- curl -X POST "https://st41489.snowflakecomputing.com/api/v2/statements" \
--   -H "Content-Type: application/json" \
--   -H "Authorization: Bearer <JWT_TOKEN>" \
--   -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
--   -d '{
--     "statement": "SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT('\''IPL.LEAGUE.IPL_CRICKET_AGENT'\'', '\''Who are the top 5 run scorers?'\'')",
--     "timeout": 60,
--     "database": "IPL",
--     "schema": "LEAGUE",
--     "warehouse": "COMPUTE_WH",
--     "role": "CORTEX_AI_ROLE"
--   }'
--
--
-- === CURL: Cortex Agent REST Endpoint (Preview) ===
-- If your account supports the Cortex Agent REST API directly:
--
-- curl -X POST "https://st41489.snowflakecomputing.com/api/v2/cortex/agent:run" \
--   -H "Content-Type: application/json" \
--   -H "Authorization: Bearer <JWT_TOKEN>" \
--   -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
--   -d '{
--     "agent_name": "IPL.LEAGUE.IPL_CRICKET_AGENT",
--     "query": "Compare Virat Kohli vs Rohit Sharma batting stats",
--     "stream": false
--   }'
--
--
-- === PYTHON EXAMPLE ===
--
-- import requests
-- import json
--
-- ACCOUNT_URL = "https://st41489.snowflakecomputing.com"
-- JWT_TOKEN = "<your_jwt_token>"
--
-- headers = {
--     "Content-Type": "application/json",
--     "Authorization": f"Bearer {JWT_TOKEN}",
--     "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
-- }
--
-- # Via SQL API
-- payload = {
--     "statement": "SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT('IPL.LEAGUE.IPL_CRICKET_AGENT', :1)",
--     "timeout": 60,
--     "database": "IPL",
--     "schema": "LEAGUE",
--     "warehouse": "COMPUTE_WH",
--     "role": "CORTEX_AI_ROLE",
--     "bindings": {
--         "1": {"type": "TEXT", "value": "Who has the best economy rate among bowlers?"}
--     }
-- }
--
-- response = requests.post(f"{ACCOUNT_URL}/api/v2/statements", headers=headers, json=payload)
-- print(json.dumps(response.json(), indent=2))
--
--
-- === GENERATING A JWT TOKEN (Key-Pair Authentication) ===
-- 1. Generate RSA key pair:
--    openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
--    openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
--
-- 2. Assign public key to your user:
--    ALTER USER RPOSAM SET RSA_PUBLIC_KEY='<public_key_contents>';
--
-- 3. Generate JWT using snowsql or python:
--    from snowflake.connector import auth
--    # Use snowflake-connector-python to generate JWT programmatically
