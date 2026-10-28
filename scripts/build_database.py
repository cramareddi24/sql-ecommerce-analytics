"""
Builds data/ecommerce.db (SQLite) from schema.sql and fills it with
synthetic data for a fictional online retailer.

Usage:
    python scripts/build_database.py
"""

import random
import sqlite3
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "ecommerce.db"
SEED = 11

REGIONS = ["West", "Southwest", "Midwest", "Southeast", "Northeast"]
ACQ_CHANNELS = ["Paid Search", "Social", "Referral", "Organic", "Email"]
SALES_CHANNELS = ["Web", "Mobile App", "Marketplace"]
FIRST = ["Alex", "Jordan", "Priya", "Marcus", "Elena", "Sam", "Nina", "Omar", "Grace", "Leo",
         "Maya", "Ethan", "Sofia", "Daniel", "Aisha", "Ryan", "Hana", "Lucas", "Zoe", "Victor"]
LAST = ["Nguyen", "Lee", "Patel", "Garcia", "Kim", "Brooks", "Chen", "Rivera", "Shah", "Morgan",
        "Ali", "Foster", "Ortiz", "Reyes", "Kapoor", "Hughes", "Tran", "Bennett", "Diaz", "Cole"]

# category: [(product, price), ...]
CATALOG = {
    "Electronics": [("Wireless Earbuds", 79), ("Bluetooth Speaker", 59), ("Smart Watch", 199),
                    ("USB-C Hub", 39), ("Portable Charger", 29), ("Noise Canceling Headphones", 249)],
    "Home & Kitchen": [("Chef's Knife", 65), ("Cast Iron Skillet", 45), ("Coffee Grinder", 35),
                       ("Glass Storage Set", 32), ("Linen Throw", 58), ("Ceramic Planter", 24), ("Desk Lamp", 42)],
    "Outdoors": [("Hiking Daypack", 89), ("Insulated Bottle", 28), ("Camping Hammock", 49),
                 ("Trail Running Socks", 18), ("Headlamp", 25)],
    "Apparel": [("Merino Crew Tee", 48), ("Rain Shell Jacket", 129), ("Everyday Hoodie", 64),
                ("Canvas Sneakers", 72), ("Wool Beanie", 22), ("Chino Pants", 58)],
    "Beauty": [("Daily Moisturizer", 26), ("Sunscreen SPF 50", 19), ("Hair Repair Serum", 34),
               ("Clay Face Mask", 21), ("Lip Balm Set", 12)],
    "Fitness": [("Yoga Mat", 38), ("Adjustable Dumbbells", 179), ("Resistance Bands", 24),
                ("Foam Roller", 29), ("Jump Rope", 15), ("Gym Duffel", 55)],
}
MARGIN_BY_CATEGORY = {"Electronics": 0.32, "Home & Kitchen": 0.45, "Outdoors": 0.42,
                      "Apparel": 0.55, "Beauty": 0.62, "Fitness": 0.40}
RETURN_RATE = {"Electronics": 0.06, "Home & Kitchen": 0.04, "Outdoors": 0.05,
               "Apparel": 0.14, "Beauty": 0.02, "Fitness": 0.05}

START, END = date(2024, 1, 1), date(2025, 6, 30)


def seasonal_weight(d: date) -> float:
    return {11: 1.6, 12: 1.9, 1: 0.8, 2: 0.85, 7: 1.15}.get(d.month, 1.0)


def main() -> None:
    rng = random.Random(SEED)
    DB_PATH.parent.mkdir(exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()

    con = sqlite3.connect(DB_PATH)
    con.executescript((ROOT / "schema.sql").read_text())

    # Products
    products, pid = [], 1
    for category, items in CATALOG.items():
        for name, price in items:
            cost = round(price * (1 - MARGIN_BY_CATEGORY[category]), 2)
            products.append((pid, name, category, float(price), cost))
            pid += 1
    con.executemany("INSERT INTO products VALUES (?,?,?,?,?)", products)

    # Customers
    customers = []
    for cid in range(1, 801):
        f, l = rng.choice(FIRST), rng.choice(LAST)
        signup = START + timedelta(days=rng.randint(0, (END - START).days - 30))
        customers.append((cid, f, l, f"{f.lower()}.{l.lower()}.{cid}@example.com",
                          rng.choices(REGIONS, weights=[28, 14, 18, 20, 20])[0],
                          signup.isoformat(),
                          rng.choices(ACQ_CHANNELS, weights=[30, 22, 12, 26, 10])[0]))
    con.executemany("INSERT INTO customers VALUES (?,?,?,?,?,?,?)", customers)

    # Orders: referral and email customers come back more often, and
    # everyone is more likely to come back around the holidays
    loyalty = {"Referral": 0.78, "Email": 0.75, "Organic": 0.70, "Paid Search": 0.62, "Social": 0.58}
    orders, items = [], []

    def place_order(cid: int, order_date: date) -> None:
        oid = len(orders) + 1
        channel = rng.choices(SALES_CHANNELS, weights=[45, 38, 17])[0]
        basket = rng.sample(products, rng.choices([1, 2, 3, 4], weights=[45, 30, 17, 8])[0])
        return_p = max(RETURN_RATE[p[2]] for p in basket)
        status = rng.choices(["Completed", "Returned", "Canceled"], weights=[1 - return_p - 0.03, return_p, 0.03])[0]
        orders.append((oid, cid, order_date.isoformat(), channel, status))
        for p in basket:
            discount = rng.choices([0, 0.10, 0.20], weights=[75, 18, 7])[0]
            if order_date.month in (11, 12):
                discount = max(discount, rng.choice([0, 0.15]))
            qty = rng.choices([1, 2, 3], weights=[80, 15, 5])[0]
            items.append((len(items) + 1, oid, p[0], qty, p[3], discount))

    for cid, *_, signup, acq in customers:
        signup_d = date.fromisoformat(signup)
        order_date = signup_d + timedelta(days=rng.randint(0, 20))
        while order_date <= END:
            place_order(cid, order_date)
            next_date = order_date + timedelta(days=rng.randint(25, 110))
            if next_date > END or rng.random() > min(0.92, loyalty[acq] * seasonal_weight(next_date)):
                break
            order_date = next_date

        # Holiday gift orders
        if signup_d <= date(2024, 11, 15) and rng.random() < 0.30:
            place_order(cid, date(2024, 11, 15) + timedelta(days=rng.randint(0, 35)))


    con.executemany("INSERT INTO orders VALUES (?,?,?,?,?)", orders)
    con.executemany("INSERT INTO order_items VALUES (?,?,?,?,?,?)", items)
    con.commit()

    for table in ["customers", "products", "orders", "order_items"]:
        n = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"{table}: {n:,} rows")
    con.close()
    print(f"Database written to {DB_PATH}")


if __name__ == "__main__":
    main()
