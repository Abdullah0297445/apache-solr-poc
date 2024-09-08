import os
import psycopg
import pysolr

db_config = {
    'dbname': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASS'),
    'host': os.getenv('DB_HOST'),
    'port': os.getenv('DB_PORT')
}

solr_url = f'http://{os.getenv("SOLR_HOST")}:{os.getenv("SOLR_PORT")}/solr/{os.getenv("SOLR_COLLECTION_NAME")}'
solr = pysolr.Solr(solr_url, always_commit=True)

def index_headlines():
    with psycopg.connect(**db_config) as conn:
        with conn.cursor() as cursor:
            # De-normalization query
            query = """
                SELECT 
                    h.id AS id,
                    h.subject,
                    h.content,
                    h.published_at,
                    array_agg(DISTINCT t.category) AS "tags.tag_category",
                    array_agg(DISTINCT tl.name) AS "tags.tag_aliases",
                    array_agg(DISTINCT rt.category) AS "related_tags.related_tag_category",
                    array_agg(DISTINCT rtl.name) AS "related_tags.related_tag_aliases"
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

            cursor.execute(query)
            results = cursor.fetchall()

    solr_documents = []
    for row in results:
        headline = {
            "id": str(row[0]),
            "subject": row[1],
            "content": row[2],
            "published_at": row[3].isoformat() + "Z" if row[3] else None,
            "tags.tag_category": row[4] if row[4] and row[4][0] is not None else [],
            "tags.tag_aliases": row[5] if row[5] and row[5][0] is not None else [],
            "related_tags.related_tag_category": row[6] if row[6] and row[6][0] is not None else [],
            "related_tags.related_tag_aliases": row[7] if row[7] and row[7][0] is not None else [],
        }
        solr_documents.append(headline)

    solr.add(solr_documents)


if __name__ == "__main__":
    index_headlines()
