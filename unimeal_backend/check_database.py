"""Read-only connection and schema check. Never creates or alters tables."""
from sqlalchemy import inspect, text
from app.database import engine
from app.models import Base


def main():
    with engine.connect() as connection:
        inspector = inspect(connection)
        tables = inspector.get_table_names()
        missing = []
        for table in Base.metadata.sorted_tables:
            if table.name not in tables:
                missing.append(table.name)
                continue
            columns = {column['name'] for column in inspector.get_columns(table.name)}
            missing.extend(f'{table.name}.{column.name}' for column in table.columns if column.name not in columns)
        if missing:
            raise SystemExit('Missing database tables/columns: ' + ', '.join(missing))
        database = connection.scalar(text('SELECT DATABASE()'))
        print(f'Connected to {database}: {len(tables)} tables; all mapped columns available.')


if __name__ == '__main__':
    main()
