import os
import sys
import urllib.request
import zipfile
import sqlite3
import io
import subprocess
import json

CITIES_ZIP_URL = "https://download.geonames.org/export/dump/cities1000.zip"
COUNTRIES_URL = "https://download.geonames.org/export/dump/countryInfo.txt"
ADMIN1_URL = "https://download.geonames.org/export/dump/admin1CodesASCII.txt"

DB_FILE = "cities.db"

def download_file(url, desc):
    print(f"Downloading {desc} from {url}...")
    try:
        response = urllib.request.urlopen(url)
        return response.read()
    except Exception as e:
        print(f"Error downloading {desc}: {e}")
        sys.exit(1)

def main():
    # 1. Download country mapping
    country_data = download_file(COUNTRIES_URL, "country info")
    country_map = {}
    
    # Parse country info lines
    for line in country_data.decode("utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) >= 5:
            iso_code = parts[0].strip()
            country_name = parts[4].strip()
            country_map[iso_code] = country_name

    # 2. Download admin1 (state) code mapping
    admin1_data = download_file(ADMIN1_URL, "state info")
    admin1_map = {}
    for line in admin1_data.decode("utf-8").splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) >= 2:
            code_key = parts[0].strip()  # Format: "US.NY" or "IN.DL"
            state_name = parts[1].strip()
            admin1_map[code_key] = state_name

    # 3. Download and extract cities
    cities_zip_data = download_file(CITIES_ZIP_URL, "100k+ cities database (this may take a minute)")
    
    print("Extracting cities database...")
    zip_file = zipfile.ZipFile(io.BytesIO(cities_zip_data))
    cities_txt = zip_file.read("cities1000.txt").decode("utf-8")

    # 4. Prepare SQLite database
    print(f"Generating SQLite database: {DB_FILE}...")
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Create table with indexing for fast searches
    cursor.execute("""
    CREATE TABLE cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        state TEXT NOT NULL,
        country TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timezone TEXT NOT NULL
    )
    """)
    
    cursor.execute("CREATE INDEX idx_cities_name ON cities(name)")

    # 5. Parse and insert city records
    city_batch = []
    processed_count = 0

    print("Parsing cities data and pre-populating database...")
    for line in cities_txt.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) >= 18:
            city_name = parts[1].strip()
            lat = float(parts[4].strip())
            lon = float(parts[5].strip())
            country_code = parts[8].strip()
            admin1_code = parts[10].strip()
            timezone = parts[17].strip()

            # Resolve full country name
            country_name = country_map.get(country_code, country_code)

            # Resolve full state name using key like "IN.DL" or "US.CA"
            state_key = f"{country_code}.{admin1_code}"
            state_name = admin1_map.get(state_key, admin1_code or country_name)

            city_batch.append((city_name, state_name, country_name, lat, lon, timezone))
            processed_count += 1

            if len(city_batch) >= 5000:
                cursor.executemany("""
                INSERT INTO cities (name, state, country, latitude, longitude, timezone)
                VALUES (?, ?, ?, ?, ?, ?)
                """, city_batch)
                city_batch = []

    # Insert remaining records
    if city_batch:
        cursor.executemany("""
        INSERT INTO cities (name, state, country, latitude, longitude, timezone)
        VALUES (?, ?, ?, ?, ?, ?)
        """, city_batch)

    # 5.5. Merge old cities from cities2.json (b3d2b6d)
    print("Merging old Indian cities database from git history...")
    try:
        proc = subprocess.run(
            ["git", "show", "b3d2b6d:assets/data/cities2.json"],
            capture_output=True,
            text=True,
            check=True,
            encoding="utf-8"
        )
        old_cities = json.loads(proc.stdout)
        print(f"Loaded {len(old_cities)} old Indian cities from git.")
        
        # Build a set of existing Indian cities in the db to avoid duplicates
        cursor.execute("SELECT LOWER(name), LOWER(state) FROM cities WHERE country = 'India'")
        existing_indian_cities = set((row[0], row[1]) for row in cursor.fetchall())
        
        old_city_batch = []
        added_count = 0
        
        for old_city in old_cities:
            name = old_city.get('n', '').strip()
            state = old_city.get('s', '').strip()
            country = old_city.get('c', '').strip()
            lat = float(old_city.get('la', 0.0))
            lon = float(old_city.get('lo', 0.0))
            timezone = "Asia/Kolkata"
            
            # Check for duplicate
            key = (name.lower(), state.lower())
            if key not in existing_indian_cities:
                old_city_batch.append((name, state, country, lat, lon, timezone))
                existing_indian_cities.add(key)
                added_count += 1
                
                if len(old_city_batch) >= 5000:
                    cursor.executemany("""
                    INSERT INTO cities (name, state, country, latitude, longitude, timezone)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, old_city_batch)
                    old_city_batch = []
                    
        if old_city_batch:
            cursor.executemany("""
            INSERT INTO cities (name, state, country, latitude, longitude, timezone)
            VALUES (?, ?, ?, ?, ?, ?)
            """, old_city_batch)
            
        print(f"Merged {added_count} new Indian cities/towns from legacy database.")
    except Exception as e:
        print(f"Warning: Failed to merge old cities from git history: {e}")

    conn.commit()
    
    # Calculate final database stats
    cursor.execute("SELECT COUNT(*) FROM cities")
    total_cities = cursor.fetchone()[0]
    conn.close()

    print(f"Success! Pre-populated SQLite database created successfully.")
    print(f"Total city records inserted: {total_cities}")
    print(f"Database size: {os.path.getsize(DB_FILE) / 1024 / 1024:.2f} MB")

if __name__ == "__main__":
    main()
