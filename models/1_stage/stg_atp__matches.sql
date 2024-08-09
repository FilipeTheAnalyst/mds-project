WITH source AS (
    SELECT *
    FROM {{ source('atp_tour_raw', 'matches') }}
),

renamed AS (
    SELECT
        tourney_id::varchar(50) AS tournament_id,
        tourney_name::varchar(100) AS tournament_name,
        CASE
            WHEN tourney_level = 'A' THEN 'Other tour-level events'
            WHEN tourney_level = 'D' THEN 'Davis Cup'
            WHEN tourney_level = 'F' THEN 'Tour finals'
            WHEN tourney_level = 'G' THEN 'Grand Slams'
            WHEN tourney_level = 'M' THEN 'Masters 1000s'
        END::varchar(25) AS tournament_level,
        {{ convert_yyyymmdd_int_to_date('tourney_date') }} AS tournament_date,
        surface::varchar(10) AS surface,
        draw_size::smallint AS draw_size,
        match_num::smallint AS match_id,
        score::varchar(50) AS score,
        best_of::tinyint AS best_of,
        ('Best of ' || best_of)::varchar(10) AS best_of_labeled,
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
        END::varchar(4) AS round,
        minutes::smallint AS minutes,
        winner_id::int AS winner_id,
        winner_seed::tinyint AS winner_seed,
        CASE
            WHEN winner_entry = 'WC' THEN 'Wild card'
            WHEN winner_entry = 'Q' THEN 'Qualifier'
            WHEN winner_entry = 'LL' THEN 'Lucky loser'
            WHEN winner_entry = 'PR' THEN 'Protected ranking'
            WHEN winner_entry = 'ITF' THEN 'ITF entry'
            ELSE winner_entry
        END::varchar(20) AS winner_entry,
        winner_name::varchar(100) AS winner_name,
        CASE
            WHEN winner_hand = 'R' THEN 'Right-handed'
            WHEN winner_hand = 'L' THEN 'Left-handed'
            WHEN winner_hand = 'A' THEN 'Ambidextrous'
            WHEN winner_hand = 'U' THEN 'Unknown'
            ELSE winner_hand
        END::varchar(15) AS winner_dominant_hand,
        winner_ht::smallint AS winner_height_cm,
        winner_ioc::varchar(3) AS winner_country_iso_code,
        winner_age::tinyint AS winner_age,
        w_ace::tinyint AS winner_num_of_aces,
        w_df::smallint AS winner_num_of_double_faults,
        w_svpt::smallint AS winner_num_of_serve_pts,
        w_1st_in::smallint AS winner_num_of_1st_serves_made,
        w_1st_won::smallint AS winner_num_of_1st_serve_pts_won,
        w_2nd_won::smallint AS winner_num_of_2nd_serve_pts_won,
        w_sv_gms::smallint AS winner_num_of_serve_games,
        w_bp_saved::smallint AS winner_num_of_break_pts_saved,
        w_bp_faced::smallint AS winner_num_of_break_pts_faced,
        winner_rank::smallint AS winner_rank,
        winner_rank_points::smallint AS winner_rank_pts,
        loser_id::int AS loser_id,
        loser_seed::tinyint AS loser_seed,
        CASE
            WHEN loser_entry = 'WC' THEN 'Wild card'
            WHEN loser_entry = 'Q' THEN 'Qualifier'
            WHEN loser_entry = 'LL' THEN 'Lucky loser'
            WHEN loser_entry = 'PR' THEN 'Protected ranking'
            WHEN loser_entry = 'ITF' THEN 'ITF entry'
            ELSE loser_entry
        END::varchar(20) AS loser_entry,
        loser_name::varchar(100) AS loser_name,
        CASE
            WHEN loser_hand = 'R' THEN 'Right-handed'
            WHEN loser_hand = 'L' THEN 'Left-handed'
            WHEN loser_hand = 'A' THEN 'Ambidextrous'
            WHEN loser_hand = 'U' THEN 'Unknown'
            ELSE loser_hand
        END::varchar(15) AS loser_dominant_hand,
        loser_ht::smallint AS loser_height_cm,
        loser_ioc::varchar(3) AS loser_country_iso_code,
        loser_age::tinyint AS loser_age,
        l_ace::tinyint AS loser_num_of_aces,
        l_df::smallint AS loser_num_of_double_faults,
        l_svpt::smallint AS loser_num_of_serve_pts,
        l_1st_in::smallint AS loser_num_of_1st_serves_made,
        l_1st_won::smallint AS loser_num_of_1st_serve_pts_won,
        l_2nd_won::smallint AS loser_num_of_2nd_serve_pts_won,
        l_sv_gms::smallint AS loser_num_of_serve_games,
        l_bp_saved::smallint AS loser_num_of_break_pts_saved,
        l_bp_faced::smallint AS loser_num_of_break_pts_faced,
        loser_rank::smallint AS loser_rank,
        loser_rank_points::smallint AS loser_rank_pts,
        w_ace::int + l_ace::int AS total_num_of_aces,
        w_df::int + l_df::int AS total_num_of_double_faults,
        w_svpt::int + l_svpt::int AS total_num_of_serve_pts,
        w_1st_in::int + l_1st_in::int AS total_num_of_1st_serves_made,
        w_1st_won::int + l_1st_won::int AS total_num_of_1st_serve_pts_won,
        w_2nd_won::int + l_2nd_won::int AS total_num_of_2nd_serve_pts_won,
        w_sv_gms::int + l_sv_gms::int AS total_num_of_serve_games,
        w_bp_saved::int + l_bp_saved::int AS total_num_of_break_pts_saved,
        w_bp_faced::int + l_bp_faced::int AS total_num_of_break_pts_faced,
        abs(winner_age::tinyint - loser_age::tinyint) AS age_difference
    FROM source
),

final AS (
    SELECT


        {{ dbt_utils.generate_surrogate_key(['tournament_id', 'tournament_date']) }}
            AS tournament_sk
        ,

        {{ dbt_utils.generate_surrogate_key(['tournament_id', 'match_id']) }} AS match_sk,
        {{ to_date_key('tournament_date') }}::int AS tournament_date_key,
        {{ dbt_utils.generate_surrogate_key(['winner_id']) }} AS player_winner_key,
        {{ dbt_utils.generate_surrogate_key(['loser_id']) }} AS player_loser_key,
        *
    FROM renamed
)

SELECT *
FROM final
