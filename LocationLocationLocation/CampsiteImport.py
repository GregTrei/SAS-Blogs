import requests
import re
import pandas as pd
import saspy

url = "https://ridb.recreation.gov/api/v1/facilities/232447/campsites"
headers = {"apikey": "API-key-here"}

sites, offset = [], 0
while True:
    batch = requests.get(url, headers=headers, params={"limit": 50, "offset": offset}).json()["RECDATA"]
    sites += batch
    if len(batch) < 50:
        break
    offset += 50

for s in sites:
    for a in s.pop("ATTRIBUTES"):
        s["attr_" + a["AttributeName"]] = a["AttributeValue"]
    s["equipment"] = "; ".join(f'{e["EquipmentName"]} (max {e["MaxLength"]} ft)' for e in s.pop("PERMITTEDEQUIPMENT"))
    s.pop("ENTITYMEDIA", None)

df = pd.DataFrame(sites)
df.columns = [re.sub(r"\W+", "_", c)[:32] for c in df.columns]  # valid SAS variable names

sas = saspy.SASsession()
sas.df2sd(df, table="campsites", libref="sasuser")