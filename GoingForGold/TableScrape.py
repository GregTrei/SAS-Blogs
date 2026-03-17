import requests
import pandas as pd
import saspy

sas=saspy.SASsession(url="http://localhost:8081", serverid="0001")

url = "https://en.wikipedia.org/wiki/2026_Winter_Olympics_medal_table"

# Add a browser-like user agent to avoid 403
headers = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/119.0.0.0 Safari/537.36"
    )
}

# Fetch page with headers
response = requests.get(url, headers=headers)
response.raise_for_status()

# Pandas reads the HTML from the response content
tables = pd.read_html(response.text)

# The medal table is the first table
df = tables[2]

print(df)

# Send to SASUSER library as SASUSER.MEDALS
sas.df2sd(df, table='medals', libref='sasuser')
print("SASUSER.MEDALS created successfully.")
