import dlt
import logging
import requests
import pandas as pd
from datetime import datetime
from typing import Iterator, Dict

# Configure logging
logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger(__name__)

# Define the GitHub base URL for the ATP Tour data
BASE_URL = "https://raw.githubusercontent.com/JeffSackmann/tennis_atp/master"

@dlt.resource(name="players", primary_key="player_id", write_disposition="merge")
def atp_players_source() -> Iterator[Dict]:
    """
    A dlt resource to read ATP players data from a CSV file and load into DuckDB.
    """
    players_url = f"{BASE_URL}/atp_players.csv"
    log.debug(f"Downloading ATP players data from: {players_url}")

    # Use pandas to read CSV directly from URL
    players_df = pd.read_csv(players_url)

    # Iterate over DataFrame rows and yield each row as a dictionary
    for _, row in players_df.iterrows():
        yield row.to_dict()

@dlt.resource(name="matches", primary_key=("tourney_id", "match_num"), write_disposition="merge")
def atp_matches_source(year_from: int, year_to: int) -> Iterator[Dict]:
    """
    A dlt resource to read ATP matches data from multiple CSV files and load into DuckDB.
    """
    for year in range(year_from, year_to + 1):
        matches_url = f"{BASE_URL}/atp_matches_{year}.csv"
        log.debug(f"Downloading ATP matches data from: {matches_url}")

        # Use pandas to read CSV directly from URL
        matches_df = pd.read_csv(matches_url)

        # Iterate over DataFrame rows and yield each row as a dictionary
        for _, row in matches_df.iterrows():
            yield row.to_dict()

@dlt.resource(name="rankings", primary_key=("ranking_date", "rank"), write_disposition="merge")
def atp_rankings_source() -> Iterator[Dict]:
    """
    A dlt resource to read ATP rankings data from multiple CSV files (per decade and current)
    and load into DuckDB.
    """
    decades = ['70', '80', '90', '00', '10', '20']
    files = [f"atp_rankings_{decade}s.csv" for decade in decades]
    files.append("atp_rankings_current.csv")  # Add current rankings file
    
    for file_name in files:
        rankings_url = f"{BASE_URL}/{file_name}"
        log.debug(f"Downloading ATP rankings data from: {rankings_url}")

        # Use pandas to read CSV directly from URL
        rankings_df = pd.read_csv(rankings_url)

        # Iterate over DataFrame rows and yield each row as a dictionary
        for _, row in rankings_df.iterrows():
            yield row.to_dict()

@dlt.resource(name="countries", write_disposition="replace")
def countries_data_source() -> Iterator[Dict]:
    """
    A dlt resource to download and read countries data from a JSON file and load into DuckDB.
    """
    url = 'https://restcountries.com/v3.1/all'
    log.debug(f"Downloading countries JSON data from: {url}")

    # Use requests to fetch JSON data
    response = requests.get(url)
    response.raise_for_status()

    # Use response.json() to parse JSON data into a list of dictionaries
    json_data = response.json()

    # Iterate over JSON objects and yield each as a dictionary
    for country in json_data:
        yield country

def main():
    # Create a dlt pipeline
    pipeline = dlt.pipeline(
        pipeline_name="atp_tour",
        destination="duckdb",
        dataset_name="raw"
    )

    # Load data from the sources into DuckDB
    load_info = pipeline.run([
        atp_players_source(),
        atp_matches_source(year_from=1968, year_to=datetime.now().year),
        atp_rankings_source(),
        countries_data_source()
    ])

    print(load_info)

if __name__ == "__main__":
    main()