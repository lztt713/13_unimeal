"""Show how to seed Qichen Hu's real MySQL database.

The backend no longer owns temporary SQLite seed data. Run the shared database
scripts from the repository root instead:

    mysql -u root -p < database/master_schema.sql
    mysql -u root -p < database/sample_data.sql
    mysql -u root -p < database/validation_queries.sql
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    print("UniMeal now uses Qichen Hu's MySQL schema.")
    print("Run these files with the MySQL client from the repository root:")
    print(f"  1. {ROOT / 'database' / 'master_schema.sql'}")
    print(f"  2. {ROOT / 'database' / 'sample_data.sql'}")
    print(f"  3. {ROOT / 'database' / 'validation_queries.sql'}")


if __name__ == "__main__":
    main()
