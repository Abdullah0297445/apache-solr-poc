import os
import psycopg
import pysolr
import logging
from datetime import datetime

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Database connection settings
db_config = {
    'dbname': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASS'),
    'host': os.getenv('DB_HOST'),
    'port': os.getenv('DB_PORT')
}

# Solr connection
solr_url = f'http://{os.getenv("SOLR_HOST")}:{os.getenv("SOLR_PORT")}/solr/{os.getenv("SOLR_COLLECTION_NAME")}'
solr = pysolr.Solr(solr_url, always_commit=True)

def index_headlines():
    print(db_config)
    try:
        with psycopg.connect(**db_config) as conn:
            with conn.cursor() as cursor:
                # SQL query to fetch and structure data
                optimized_query = """
                SELECT 
                    h.id AS id,
                    h.subject,
                    h.content,
                    h.published_at,
                    array_agg(DISTINCT t.id) AS "tags.tag_id",
                    array_agg(DISTINCT t.category) AS "tags.tag_category",
                    array_agg(DISTINCT tl.name) AS "tags.tag_aliases",
                    array_agg(DISTINCT rt.id) AS "related_tags.related_tag_id",
                    array_agg(DISTINCT rt.category) AS "related_tags.related_tag_category",
                    array_agg(DISTINCT rtl.name) AS "related_tags.related_tag_aliases",
                    array_agg(DISTINCT tr.strength) AS "related_tags.relation_strength"
                FROM 
                    headlines h
                LEFT JOIN 
                    headline_tags ht ON h.id = ht.headline_id
                LEFT JOIN 
                    tags t ON ht.tag_id = t.id
                LEFT JOIN 
                    tag_labels tl ON t.id = tl.tag_id
                LEFT JOIN 
                    tag_relations tr ON t.id = tr.source_tag_id
                LEFT JOIN 
                    tags rt ON tr.target_tag_id = rt.id
                LEFT JOIN 
                    tag_labels rtl ON rt.id = rtl.tag_id
                GROUP BY 
                    h.id
                """

                cursor.execute(optimized_query)
                results = cursor.fetchall()

                logging.info(f"Query executed. Fetched {len(results)} rows.")

                if not results:
                    logging.warning("No results returned from the database query.")
                    return

                # Convert data into format for Solr
                solr_documents = []
                for row in results:
                    headline = {
                        "id": str(row[0]),  # Ensure id is a string
                        "subject": row[1],
                        "content": row[2],
                        "published_at": row[3].isoformat() + "Z" if row[3] else None,  # Add 'Z' for UTC
                        "tags.tag_id": row[4] if row[4] and row[4][0] is not None else [],
                        "tags.tag_category": row[5] if row[5] and row[5][0] is not None else [],
                        "tags.tag_aliases": row[6] if row[6] and row[6][0] is not None else [],
                        "related_tags.related_tag_id": row[7] if row[7] and row[7][0] is not None else [],
                        "related_tags.related_tag_category": row[8] if row[8] and row[8][0] is not None else [],
                        "related_tags.related_tag_aliases": row[9] if row[9] and row[9][0] is not None else [],
                        "related_tags.relation_strength": row[10] if row[10] and row[10][0] is not None else []
                    }
                    solr_documents.append(headline)

                logging.info(f"Prepared {len(solr_documents)} documents for Solr indexing.")
                logging.info(f"Sample document: {solr_documents[0] if solr_documents else 'No documents'}")

        # Index the documents
        solr.add(solr_documents)
        logging.info("Documents sent to Solr for indexing.")

        # Query Solr to verify indexing
        results = solr.search('*:*')
        logging.info(f'Solr query returned {len(results)} documents.')
        logging.info(f'Sample result: {list(results)[0] if results else "No results"}')

    except Exception as e:
        logging.exception(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    index_headlines()