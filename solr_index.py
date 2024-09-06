import os

import pysolr
import psycopg
from psycopg.rows import dict_row

# Connect to Solr
solr = pysolr.Solr(f'http://{os.getenv('SOLR_HOST')}:{os.getenv('SOLR_PORT')}/solr/{os.getenv('SOLR_COLLECTION_NAME')}')

# Connect to PostgreSQL
db = psycopg.connect(
    host=os.getenv('DB_HOST'),
    port=os.getenv('DB_PORT'),
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASS'),
    dbname=os.getenv('DB_NAME'),
    row_factory=dict_row  # This returns rows as dictionaries, making it easier to process results
)

def get_tags_and_relations(headline_id):
    query = """
    SELECT t.id, t.category, tl.name, ht.weight,
           STRING_AGG(CONCAT(tr.target_tag_id, ':', tr.strength), ';') AS relations
    FROM headline_tags ht
    JOIN tags t ON ht.tag_id = t.id
    JOIN tag_labels tl ON t.id = tl.tag_id
    LEFT JOIN tag_relations tr ON t.id = tr.source_tag_id
    WHERE ht.headline_id = %s
    GROUP BY t.id, t.category, tl.name, ht.weight
    """

    # Use the connection in a context manager
    with db.cursor() as cursor:
        cursor.execute(query, (headline_id,))
        return cursor.fetchall()


def index_headlines():
    # Fetch headlines
    with db.cursor() as cursor:
        cursor.execute("SELECT id, subject, content, published_at FROM headlines")

        for headline in cursor:
            headline_id = headline['id']
            subject = headline['subject']
            content = headline['content']
            published_at = headline['published_at']

            # Get tags and relations for the current headline
            tags_info = get_tags_and_relations(headline_id)

            # Prepare the document for Solr
            doc = {
                'id': str(headline_id),
                'subject': subject,
                'content': content,
                'published_at': published_at.isoformat(),
                'tags': [t['name'] for t in tags_info],  # tag names
                'tag_categories': [t['category'] for t in tags_info],  # tag categories
                'tag_weights': [t['weight'] for t in tags_info],  # tag weights
                'tag_relations': [f"{t['id']}:{t['relations']}" for t in tags_info if t['relations']]
                # tag_id:relations
            }

            # Add document to Solr
            solr.add([doc])

    # Commit the changes to Solr
    solr.commit()


if __name__ == "__main__":
    index_headlines()
