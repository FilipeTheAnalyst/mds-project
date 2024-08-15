WITH source AS (
    SELECT *
    FROM {{ source('atp_tour_raw', 'atp_matches') }}
)
, renamed AS (
    SELECT
        tourney_id::VARCHAR(50) AS tournament_id,
        tourney_name::VARCHAR(100) AS tournament_name,
        CASE
            WHEN tourney_level = 'A' THEN 'Other tour-level events'
            WHEN tourney_level = 'D' THEN 'Davis Cup'
            WHEN tourney_level = 'F' THEN 'Tour finals'
            WHEN tourney_level = 'G' THEN 'Grand Slams'
            WHEN tourney_level = 'M' THEN 'Masters 1000s'
        END::VARCHAR(25) AS tournament_level,
        TO_DATE(TO_VARCHAR(tourney_date),'YYYYMMDD') AS tournament_date,
        surface::VARCHAR(10) AS surface,
        draw_size::SMALLINT AS draw_size,
        match_num::SMALLINT AS match_id,
        score::VARCHAR(50) AS score,
        best_of::TINYINT AS best_of,
        ('Best of ' || best_of)::VARCHAR(10) AS best_of_labeled,
        CASE
            WHEN round = 'BR' THEN ''
            WHEN round = 'ER' THEN ''
            WHEN round = 'F' THEN 'Final'
            WHEN round = 'QF' THEN 'Quarterfinal'
            WHEN round = 'R16' THEN 'Round of 16'
            WHEN round = 'R32' THEN 'Round of 32'
            WHEN round = 'R64' THEN 'Round of 64'
            WHEN round = 'R128' THEN 'Round of 128'
            WHEN round = 'RR' THEN 'Round robin'
            WHEN round = 'SF' THEN 'Semifinal'
            ELSE round
        END::VARCHAR(20) AS round,
        minutes::SMALLINT AS minutes,
        winner_id::INT AS winner_id,
        winner_seed::TINYINT AS winner_seed,
        CASE
            WHEN winner_entry = 'WC' THEN 'Wild card'
            WHEN winner_entry = 'Q' THEN 'Qualifier'
            WHEN winner_entry = 'LL' THEN 'Lucky loser'
            WHEN winner_entry = 'PR' THEN 'Protected ranking'
            WHEN winner_entry = 'ITF' THEN 'ITF entry'
            ELSE winner_entry
        END::VARCHAR(20) AS winner_entry,
        winner_name::VARCHAR(100) AS winner_name,
        CASE
            WHEN winner_hand = 'R' THEN 'Right-handed'
            WHEN winner_hand = 'L' THEN 'Left-handed'
            WHEN winner_hand = 'A' THEN 'Ambidextrous'
            WHEN winner_hand = 'U' THEN 'Unknown'
            ELSE winner_hand
        END::VARCHAR(15) AS winner_dominant_hand,
        winner_ht::SMALLINT AS winner_height_cm,
        winner_ioc::VARCHAR(3) AS winner_country_iso_code,
        winner_age::TINYINT AS winner_age,
        w_ace::TINYINT AS winner_num_of_aces,
        w_df::SMALLINT AS winner_num_of_double_faults,
        w_svpt::SMALLINT AS winner_num_of_serve_pts,
        w_1stin::SMALLINT AS winner_num_of_1st_serves_made,
        w_1stwon::SMALLINT AS winner_num_of_1st_serve_pts_won,
        w_2ndwon::SMALLINT AS winner_num_of_2nd_serve_pts_won,
        w_svgms::SMALLINT AS winner_num_of_serve_games,
        w_bpsaved::SMALLINT AS winner_num_of_break_pts_saved,
        w_bpfaced::SMALLINT AS winner_num_of_break_pts_faced,
        winner_rank::SMALLINT AS winner_rank,
        winner_rank_points::SMALLINT AS winner_rank_pts,
        loser_id::INT AS loser_id,
        loser_seed::TINYINT AS loser_seed,
        CASE
            WHEN loser_entry = 'WC' THEN 'Wild card'
            WHEN loser_entry = 'Q' THEN 'Qualifier'
            WHEN loser_entry = 'LL' THEN 'Lucky loser'
            WHEN loser_entry = 'PR' THEN 'Protected ranking'
            WHEN loser_entry = 'ITF' THEN 'ITF entry'
            ELSE loser_entry
        END::VARCHAR(20) AS loser_entry,
        loser_name::VARCHAR(100) AS loser_name,
        CASE
            WHEN loser_hand = 'R' THEN 'Right-handed'
            WHEN loser_hand = 'L' THEN 'Left-handed'
            WHEN loser_hand = 'A' THEN 'Ambidextrous'
            WHEN loser_hand = 'U' THEN 'Unknown'
            ELSE loser_hand
        END::VARCHAR(15) AS loser_dominant_hand,
        loser_ht::SMALLINT AS loser_height_cm,
        loser_ioc::VARCHAR(3) AS loser_country_iso_code,
        loser_age::TINYINT AS loser_age,
        l_ace::TINYINT AS loser_num_of_aces,
        l_df::SMALLINT AS loser_num_of_double_faults,
        l_svpt::SMALLINT AS loser_num_of_serve_pts,
        l_1stin::SMALLINT AS loser_num_of_1st_serves_made,
        l_1stwon::SMALLINT AS loser_num_of_1st_serve_pts_won,
        l_2ndwon::SMALLINT AS loser_num_of_2nd_serve_pts_won,
        l_svgms::SMALLINT AS loser_num_of_serve_games,
        l_bpsaved::SMALLINT AS loser_num_of_break_pts_saved,
        l_bpfaced::SMALLINT AS loser_num_of_break_pts_faced,
        loser_rank::SMALLINT AS loser_rank,
        loser_rank_points::SMALLINT AS loser_rank_pts,
        w_ace::INT + l_ace::INT AS total_num_of_aces,
        w_df::INT + l_df::INT AS total_num_of_double_faults,
        w_svpt::INT + l_svpt::INT AS total_num_of_serve_pts,
        w_1stin::INT + l_1stin::INT AS total_num_of_1st_serves_made,
        w_1stwon::INT + l_1stwon::INT AS total_num_of_1st_serve_pts_won,
        w_2ndwon::INT + l_2ndwon::INT AS total_num_of_2nd_serve_pts_won,
        w_svgms::INT + l_svgms::INT AS total_num_of_serve_games,
        w_bpsaved::INT + l_bpsaved::INT AS total_num_of_break_pts_saved,
        w_bpfaced::INT + l_bpfaced::INT AS total_num_of_break_pts_faced,
        abs(winner_age::TINYINT - loser_age::TINYINT) AS age_difference
    FROM source
)
, final AS (
    SELECT

        {{ dbt_utils.generate_surrogate_key(['tournament_id', 'tournament_date']) }}
            AS tournament_sk,
        {{ dbt_utils.generate_surrogate_key(['tournament_id', 'match_id']) }} AS match_sk,
        {{ to_date_key('tournament_date') }}::INT AS tournament_date_key,
        {{ dbt_utils.generate_surrogate_key(['winner_id']) }} AS player_winner_key,
        {{ dbt_utils.generate_surrogate_key(['loser_id']) }} AS player_loser_key,
        *
    FROM renamed
)
SELECT *
FROM final
