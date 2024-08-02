import requests

base_url = "https://ergast.com/api/f1/"
endpoint_path = "drivers.json"  # Append .json to request JSON data
params = {"limit": 1000}

response = requests.get(base_url + endpoint_path, params=params)
print(response.status_code)
print(response.text)  # Print the response content