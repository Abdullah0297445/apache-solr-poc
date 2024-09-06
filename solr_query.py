import os
from fastapi import FastAPI, Query
from typing import List, Optional
import pysolr
from fastapi.responses import JSONResponse

app = FastAPI()

# Solr connection
solr = pysolr.Solr(f'http://{os.getenv('SOLR_HOST')}:{os.getenv('SOLR_PORT')}/solr/{os.getenv('SOLR_COLLECTION_NAME')}')


@app.get("/search")
async def search(
    q: Optional[str] = Query(default='', description="Search query"),
    tag: Optional[List[str]] = Query(None, description="List of tags for filtering")
):
    # Base query
    solr_query = f'_text_:({q})'

    # Graph traversal for tag expansion
    if tag:
        tag_query = ' OR '.join(tag)
        graph_query = f'{{!graph from=tag_relations to=id maxDepth=3}}tags:({tag_query})'
        solr_query = f'({solr_query}) OR {graph_query}'

    # Solr search query with options
    results = solr.search(solr_query, **{
        'fl': 'id,subject,content,published_at,tags,tag_categories',
        'facet': 'on',
        'facet.field': ['tags', 'tag_categories'],
        'facet.limit': 10,
        'facet.mincount': 1,
        'hl': 'on',
        'hl.fl': 'subject,content',
        'bf': 'sum(tag_weights)'
    })

    # Process and return the results as a JSON response
    response = {
        'total': results.hits,
        'results': [dict(doc) for doc in results],
        'facets': {
            'tags': dict(zip(results.facets['facet_fields']['tags'][::2],
                             results.facets['facet_fields']['tags'][1::2])),
            'categories': dict(zip(results.facets['facet_fields']['tag_categories'][::2],
                                   results.facets['facet_fields']['tag_categories'][1::2]))
        },
        'highlighting': results.highlighting
    }

    return JSONResponse(content=response)
