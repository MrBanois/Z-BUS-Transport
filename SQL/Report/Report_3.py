import oracledb
import getpass
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

username = input("Enter Username : ")
userpwd = getpass.getpass(f"Enter password : ")
host = input("Enter Host : ") # "localhost"
port = 1521 #Assume Default port
service_name = input("Enter Service Name : ") # "freepdb1","database1"

rep3 = pd.DataFrame(columns=["User", "Bookings", "Checked-In", "Cancelled", "No-Show"])

with oracledb.connect(f'{username}/{userpwd}@{host}:{port}/{service_name}') as connection :
    with connection.cursor() as cursor :
        start_date = input("Start date (YYYY-MM-DD) : ") # 2025-04-12
        end_date = input("End date (YYYY-MM-DD) : ") # 2025-04-16  --IF DATE IS '2025-04-16' THERE SHOULD BE 7 ENTRIES
        query = cursor.execute(f'''
            SELECT 
                US."F_NAME" || ' ' || US."L_NAME" AS "User",
                COUNT(BD."BID") AS "Bookings",
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '2' THEN 1 END) AS "Checked_In",
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '3' THEN 1 END) AS "Cancelled",
                COUNT(CASE WHEN BD."CURRENT_STATUS" = '4' THEN 1 END) AS "No-Show"
            FROM
                "BOOKING" B
                JOIN "BOOKING_DETAIL" BD ON B."BOOKING_ID" = BD.BID
                JOIN "USER" US ON B."USER" = US."ID"
            WHERE
                B."DATE" BETWEEN DATE '{start_date}' AND DATE '{end_date}'
            GROUP BY US."F_NAME", US."L_NAME"
        ''')
        for _ in query : 
            rep3.loc[len(rep3)] = _

x = np.arange(len(rep3))
width = 0.2

fig, ax = plt.subplots(figsize=(12, 6))

ax.bar(x - (width * 2), rep3["Bookings"], width,label="Bookings")
ax.bar(x - (width * 1), rep3["Checked-In"], width, label="Check-in")
ax.bar(x - (width * 0), rep3["Cancelled"],  width, label="Cancelled")
ax.bar(x - (width * -1), rep3["No-Show"],    width, label="No Show")

ax.set_xticks(x)
ax.set_xticklabels(rep3["User"])

ax.set_xlabel("User")
ax.set_ylabel("Counts")

ax.set_title(f"User activity\n({start_date} to {end_date})")

ax.grid(axis="y", alpha=0.4)
ax.set_axisbelow(True)
ax.legend()

plt.tight_layout()
plt.show()

# 1. Prepare the data
plot_data = rep3.drop(columns=['User', "Bookings"]).sum()
labels = plot_data.index
sizes = plot_data.values
colors = ['#66b3ff', '#ff9999', '#99ff99']
explode = (0.05, 0.05, 0.05)

# 2. Create the Plot
fig, ax = plt.subplots(figsize=(8, 6), dpi=100)

wedges, texts, autotexts = ax.pie(
    sizes, 
    labels=labels, 
    autopct='%1.1f%%', 
    startangle=140,
    colors=colors,
    explode=explode,
    shadow=True,
    radius=0.7              # <--- This makes the circle smaller
)

# 3. Decorations
ax.legend(
    wedges, 
    labels,
    title="Status Categories",
    loc="center left",
    bbox_to_anchor=(1, 0, 0.5, 1)
)

ax.set_title(f"Overall proportion\n({start_date} to {end_date})")

# Ensure the layout is clean
ax.axis('equal')  
plt.tight_layout()
plt.show()